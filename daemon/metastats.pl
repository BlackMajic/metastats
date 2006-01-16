#!/usr/bin/perl

# Metastats Listener Daemon
# ------------------------------------------------
# A statistical data logger for multiplayer games
# Copyright (c) 2004-2006, Nick Thomson.

# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

my $version = "00.00.57";

use Strict;
use Config;

$Config{useithreads} or die "Metastats requires ithreads for its TCP support. Please recompile perl (5.8.1+) and then reload Metastats.";

use IO::Socket;
use threads;
use DBI;
use Digest::MD5;
use Time::Local;

$SIG{HUP} = \&sigHUP;
$SIG{__DIE__} = \&sigDIE;


print <<EOI;

Metastats Listener Daemon $version
-----------------------------------------------
A statistical data logger for multiplayer games
Copyright (c) 2004-2006, Nick Thomson.

Metastats comes with ABSOLUTELY NO WARRANTY. This
is free software, you are welcome to redistribute
it under certain conditions. For further details,
please visit http://www.gnu.org/copyleft/gpl.html.

EOI

%cvars = &parseConfig('./metastats.conf');

require $cvars{CoreDir}.'/main.pm';

print "   Checking for updates..\t\t";
my (undef, $vmaj, $vmin, $vrev) = &updateGetVersion();
my ($cmaj, $cmin, $crev) = split(/\./, $version);
print "done.\n";

if ($cmaj < $vmaj)
{
	print "\n   ** A major update is available.\n\n";
}
elsif ($cmin < $vmin)
{
	print "\n   ** A minor update is available.\n\n";
}
elsif ($crev < $vrev)
{
	print "\n   ** An update is available.\n\n";
}
else
{
	print "\n   Metastats is up to date.\n\n";
}

print "   Connecting to database..\t\t";

$db = DBI->connect(
	"DBI:mysql:".$cvars{DatabaseName}.":".$cvars{DatabaseHost},
	$cvars{DatabaseUser},
	$cvars{DatabasePass}) or die ("fail.\n   Unable to connect to database:\n   -> $DBI::errstr\n");

print "done.\n";

# populate our cache from the database
%servers = {};
%server_ips = {};
%games = {};
%mods = {};
%modifiers = {};
%defs = {};
my $res = '';

#
# Servers
#
foreach $res (&dbQuery($db, "SELECT server_id, server_ip, server_port, server_name, game_id, mod_id, rcon FROM uastats_servers"))
{
	$servers{$res->{server_id}} = [ $res->{server_ip},
						$res->{server_port},
						$res->{server_name},
						$res->{game_id},
						$res->{mod_id},
						$res->{rcon} ];

	# Associate server ip:port with its ID for quicker checking
	$server_ips{$res->{server_ip}.":".$res->{server_port}} = $res->{server_id};
}

$res = '';
foreach $res (&dbQuery($db, "SELECT game_id, game_plugin FROM uastats_games"))
{
	$games{$res->{game_id}} = $res->{game_plugin};
}
$res = '';
foreach $res (&dbQuery($db, "SELECT mod_id, mod_plugin FROM uastats_mods"))
{
	$mods{$res->{mod_id}} = $res->{mod_plugin};
}

#
# Definitions, modifiers follow :p
#
my @mods = ();
%handlers = {};
%players = {};

print "\n";

# Search for Game Support Modules and load them
opendir (MDIR, $cvars{ModuleDir}) or die ("Can't open game modules directory.");
while ($file = readdir(MDIR))
{
	if ($file =~ /\.gsm$/)
	{
		# Require it
		require $cvars{ModuleDir}.'/'.$file;

		# Initialise it
		$file =~ s/\.gsm$//;
		$file->init();
		$handlers{$file} = {};
		$players{$file} = {};
	}
	# We don't want to load MOD support until all the
	# game support files have been initialised.
	push @mods, $file if ($file =~ /\.msm$/);
}

closedir DIR;

foreach $modsup (@mods)
{
	require $cvars{ModuleDir}.'/'.$modsup;
	$modsup =~ s/\.msm$//;
	$modsup->init();
	$handlers{$modsup} = {};
}

print "\n";

# Defaults if no value exists
$cvars{UDPListenHost} = "*" if (!($cvars{UDPListenHost}));
$cvars{UDPListenPort} = 27500 if (!($cvars{UDPListenPort}));

print "   Creating UDP listening socket..\t";


## Any spare cheese?

my $lsocket = IO::Socket::INET->new(	Proto=>"udp",
							LocalHost=>"192.168.17.10",
							LocalPort=>$cvars{UDPListenPort})
				or die ("fail.\n\nCould not create UDP listening socket:\n->$@\n");

print "done.\n";
print "\n   Listening on port $cvars{UDPListenPort} (UDP).\n\n";

print "   Creating TCP listener thread..\t";
my $tcpThread = threads->new(\&tcpListener);

for (;;)
{
	my $incdata = "";
	$lsocket->recv($incdata, 1024);
	$l_remote_host = $lsocket->peerhost;
	$l_remote_port = $lsocket->peerport;
	my $serverid = $server_ips{$l_remote_host.":".$l_remote_port};
	if ($serverid)
	{
		print "Recognised server\n";
	}
	else
	{
		print "Unrecognised server\n";
	}
	$games{$servers{$serverid}[3]}->parse($serverid, $mods{$servers{$serverid}[4]}, $incdata);

}


# void tcpListener ()
# Thread to handle the TCP listening socket
sub tcpListener
{
	print "done.\n   Creating TCP listening socket..\t";
	my $tlsocket = IO::Socket::INET->new(	Proto=>"tcp",
								Listen=>1,
								Reuse=>1,
								LocalHost=>"192.168.17.10",
								LocalPort=>$cvars{TCPListenPort})
				or die("fail.\n\nCould not create TCP listening socket:\n->$@\n");

	print "done.\n";
	print "\n   Listening on port $cvars{TCPListenPort} (TCP).\n\n";

	for (;;)
	{
		my $tlsock_new = $tlsocket->accept();
		print "   ** Incoming TCP connection from ".$tlsock_new->peerhost.":".$tlsock_new->peerport."..\n";
		print "   Launching new worker thread..\n";
		my $tlnID = threads->new(\&tcpWorker($tlsock_new));
	}
	
	
}

# void tcpWorker (object socket)
# Takes accepted connections from the listener thread and actually
# does something with them
sub tcpWorker
{

	my ($sockid) = @_;
	my $incdata = " ";

	while ($sockid->recv($incdata, 1024))
	{
		print "-> $incdata\n";
	}
	print "   Worker thread exiting\n";

}

## Will code for food.

sub sigHUP
{
	$SIG{HUP} = \&sigHUP;
	# Reload config, update cache et al
}

sub sigDIE
{
	# Tidy up!
}
