#!/usr/bin/perl
#
# Metastats Listener Daemon
# ------------------------------------------------
# A statistical data logger for multiplayer games
# Copyright (c) 2004-2006 Nick Thomson
# Copyright (c) 2006      Tim McLennan
# 
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

#
# $configfile - system path and name of metastats config file.
#
my $configfile = './metastats.conf';

#
#
################################################################################
# No need to edit below this line
#

use strict;
use POSIX;
use Config;
use Getopt::Long;
use Time::Local;
use Digest::MD5;
use DBI;
use IO::Socket;
use threads;
use Data::Dumper;
Getopt::Long::Configure ("bundling");

$|=1;
$SIG{'HUP'} = \&sigHUP;
$SIG{'INT'} = \&sigDIE;
#$SIG{__DIE__} = \&sigDIE;

##
## Initialize variables & defaults
##
our $version = '00.00.64';
our $db;
our %conf;
my ($query, $result);

my $header = "\nMetastats Listener Daemon $version
--------------------------------------------------
A statistical data logger for multiplayer games
and other log producing programmes.
Copyright (c) 2004-2006 Nick Thomson
Copyright (c) 2006      Tim McLennan

http://metastats.sourceforge.net

Metastats comes with ABSOLUTELY NO WARRANTY. This
is free software, you are welcome to redistribute
it under certain conditions. For further details,
please visit http://www.gnu.org/copyleft/gpl.html\n\n";

my $usage;
if ($ENV{OS} =~ /indows/ || $ENV{OSTYPE} =~ /indows/) {
	$usage = "\nUsage: [type PATH\*.log |] $0 [OPTIONS]...\n";
} else {
	$usage = "\nUsage: [cat PATH/*.log |] $0 [OPTIONS]...\n";
}
$usage .= "Recieve streamed logs from one or more gameservers
to be parsed and inserted into a database of some sort.

  -h, --help			Display this notice.
  -V, --version			Display version information.
  -u, --update=TYPE		Update Metastats to a [stable|beta] build.
  -d, --debug			Enable debug output (-dd for level 2)
  -n, --nodebug			Disables debug output (-nn for a lower level)
  -m, --mode=MODE		Tracking mode (Normal, NameTrack, LAN)
  -v, --verbose			Print debug information to console.
  -q, --quiet			Silences above.
  -s, --stdin			Read logs from <STDIN> instead of a stream.
      --nostdin			Read logs from UDP/TCP stream.
  -i, --server-ip		IP Address of the server from which the 
				logs you are reading from <STDIN> came from.
  -p, --server-port		Port of the server you are reading from <STDIN>.
      --udp-ip			Interface to listen for incoming UDP logs on.
      --udp-port		Port to listen for incoming UDP logs on.
      --tcp-ip			Interface to listen for incoming TCP logs on.
      --tcp-port		Port to listen for incoming TCP logs on.
      --db-type=TYPE		Type of database to connect to.
      --db-host=HOST		Database server ip address or hostname.
      --db-port=PORT		Database server port.
      --db-name=DATABASE	Name of the database to connect to.
      --db-prefix=PREFIX	Table prefix in use on database.
      --db-user=USERNAME	Database username.
      --db-pass=PASSWORD	Database password.
      --dns			Enable DNS hostname resolution.
      --nodns			Disables ALL DNS features.
      --dns-timeout=TIME	Timout DNS queries after TIME seconds.
      --dns-locate		Enable GeoLocation DNS feature.
      --nodns-locate		Disables above.
      --rcon			Send rcon commands to logged servers.
      --norcon			Disables above.
      --timestamp		Use timestamp in logs.
      --notimestamp		Use timestamp on database server. (Default)

Note: Options specified here overwrite options in $configfile.
      See $configfile for more options/information.\n\n";

# Read command line args that stop execution
my ($cl_help, $cl_version, $cl_update);
GetOptions(
	"help|h"	=> \$cl_help,
	"version|V"	=> \$cl_version,
	"update|u=s"	=> \$cl_update);

die($usage)  if ($cl_help);
die($header) if ($cl_version);
die(updateMetastats($cl_update)) if ($cl_update);

# Check Dependancies
$Config{useithreads} or die "Metastats $version requires ithreads for TCP support.Please recompile perl(5.8.1+) and then reload Metastats.\n\n";

##
## Begin Execution
##
print $header;				# Print Metastats information
setPerlConfig();
setConfConfig();
require "$conf{CoreDir}/main.pm";	# Include required files
dbConnect();
setDBConfig();
setCLConfig();

# Auto-update Metastats as per config
updateMetastats($conf{Update});

# Include Modules
my @mods = ();
my %handlers = {};
my %players = {};
loadModules();

# Create Sockets
my ($tcpThread, $udpSocket);
#$tcpThread = netCreateTCPSocket();				#Issues
$udpSocket = netCreateUDPSocket();

# Get a list of our tracked servers
our (%servers, %server_ips, %games, %mods);
getTrackedServers();
print "--------------------------------------------------\n\n";

##
## Main Loop
##
for (;;) {
	my $incdata = 'L 01/24/2006 - 18:13:08: "-vdp.a"n"<>>><<guishness!!!!<2><STEAM_0:0:705082><CT>" killed "VULGARDISPLAYOFPOWERnice<1><STEAM_0:1:9409988><TERRORIST>" with "usp"';
	#$udpSocket->recv($incdata, 1024);
	my $l_remote_host = "127.0.0.1"; #$udpSocket->peerhost;
	my $l_remote_port = "27015";     #$udpSocket->peerport;
	my $serverid = $server_ips{$l_remote_host.":".$l_remote_port};
	if ($serverid) {
		print "Recognised server\n";
		$servers{$serverid}[3]->parse($serverid, $servers{$serverid}[4], $incdata);
	} else {
		print "Unrecognised server $l_remote_host:$l_remote_port\n";
	}
exit("finished");
}

##
## Functions
##

# hash parseConfig (string configFile)
#
# Open the config file, and parse it's contents
# into a hash
#
sub parseConfig
{
	my ($configFile) = @_;
	my %cv = undef;
	
	print "  Loading configuration file..\t\t";
	if (-e $configFile) {
		open (cfg, $configFile) || dieNicely("Cannot open $configFile");
		while (<cfg>) {
			chomp;
			my ($ln) = $_;
			if (!(/^(\040|\t)*#/)) {
				# remove double whitespace characters
				$ln =~ s/(\s{2,})/\040/g;
				
				# remove comments at the end of lines
				$ln =~ s/(#.*)$//;
				
				# Match any number of letters followed by a space
				# then any number of characters inside quotes
				# OR any number of digits
				$ln =~ /^([a-zA-Z]+)\040((\"(.+)\")|((\d)+))$/;
				# $1 and $2 now contain variable and it's contents
				my ($var, $val) = ($1, $2);
				$var =~ s/\"//; $var =~ s/\"$//;
				$val =~ s/\"//; $val =~ s/\"$//;
				
				$cv{$var} = $val if (($var) && ($val));
			}
		}
		print "[ done ]\n";
	} else {
		print "[ fail ]\n\n";
		die "The configuration file was not found.\nPlease check that $configFile exists.";
	}
	return %cv;
}

# void loadModules()
#
# Open the modules directory and require *.msm; set up handlers
# then require *.mem and setup their handlers
#
sub loadModules
{
	# Include Support Modules
	print "\n  Loading Support Modules..\n";
	opendir (MDIR, $conf{ModuleDir}) or die ("[ fail ]\nCan't open support modules directory.\n\n");
	while (my $file = readdir(MDIR)) {
		if ($file =~ /\.msm$/) {
			# Require it
			require $conf{ModuleDir}.'/'.$file;
			
			# Initialise it
			$file =~ s/\.msm$//;
			$file->init();
			$handlers{$file} = {};
			$players{$file} = {};
		}
		# We don't want to load MOD support until all the
		# game support files have been initialised.
		push @mods, $file if ($file =~ /\.mem$/);
	}
	closedir DIR;
	print "  Completed Loading Modules.\n\n";
	
	# Include Extension Modules
	print "  Loading Extension Modules..\n";
	my $mod;
	foreach $mod (@mods) {
		require $conf{ModuleDir}.'/'.$mod;
		$mod =~ s/\.mem$//;
		$mod->init();
		$handlers{$mod} = {};
	}
	print "  Completed Loading Extensions\n\n";
}

# void tcpListener ()
#
# Thread to handle the TCP listening socket
#
sub tcpListener
{
	print "[ done ]\n    Creating TCP listen socket..\t";
	my $tcpSocket = IO::Socket::INET->new(Proto=>"tcp",
						Listen=>1,
						Reuse=>1,
						LocalHost=>$conf{NetTCPHost},
						LocalPort=>$conf{NetTCPPort})
	or die("[ fail ]\n\nCould not create TCP listen socket:\n->$@\n");
	print "[ done ]\n";
	print "    Listening on port $conf{NetTCPPort}(TCP).\n";
	
	for (;;) {
		my $tlsock_new = $tcpSocket->accept();
		print "  ** Incoming TCP connection from ".$tlsock_new->peerhost.":".$tlsock_new->peerport."..\n";
		print "  Launching new worker thread..\n";
		my $tlnID = threads->new(\&tcpWorker($tlsock_new));
	}
}

# void tcpWorker (object socket)
#
# Takes accepted connections from the listener thread and actually
# does something with them
#
sub tcpWorker
{
	my ($sockid) = @_;
	my $incdata = " ";
	
	while ($sockid->recv($incdata, 1024)) {
		print "TCP-> $incdata\n";
	}
	print "  Worker thread exiting\n";
}

# void sigHUP()
#
# Reload config, update cache, et al
#
sub sigHUP
{
	print "\n\n  Recieved SIGHUP, restarting..\n";
	dbDisconnect();
	setPerlConfig();
	setConfConfig();
	dbConnect();
	setDBConfig();
	setCLConfig();
	print "  Continuing logging..\n\n";
}

# void sigDIE()
#
# Tidy up and exit.
#
sub sigDIE
{
	# Tidy up!
	print "\n\n  Recieved SIGDIE or SIGINT\n";
	dbDisconnect();
	print "  Done.\n\n";
}

# void setPerlConfig()
#
# Sets default values for %config
#
sub setPerlConfig
{
	$conf{CoreDir}		= './core';
	$conf{ModuleDir}	= './modules';
	$conf{UseTimestamp}	= 0;
	$conf{DBType}		= 'mysql';
	$conf{DBHost}		= 'localhost';
	$conf{DBPort}		= '3306';
	$conf{DBName}		= 'metastats';
	$conf{DBUser}		= 'metastats';
	$conf{DBPass}		= '';
	$conf{DBPrefix}		= 'ms';
	$conf{DBLowPriority}	= 0;
	$conf{NetUDPHost}	= '';
	$conf{NetUDPPort}	= '27500';
	$conf{NetTCPHost}	= '';
	$conf{NetTCPPort}	= '27500';
}

# void setConfConfig()
#
# Reads $configfile and outputs values into %conf
#
sub setConfConfig
{
	%conf = parseConfig($configfile); # Parse our config file
}

# void dbConnect()
#
# Connects to our database
#
sub dbConnect
{
	print "  Connecting to database..\t\t";
	$db = DBI->connect("DBI:$conf{DBType}:".$conf{DBName}.":".$conf{DBHost}.":".$conf{DBPort}, $conf{DBUser}, $conf{DBPass})
			or die("[ fail ]\n  Unable to connect to database:\n->$DBI::errstr\n");
	print "[ done ]\n";
}

# void dbDisconnect()
#
# Disconnects from our database
#
sub dbDisconnect
{
	print "  Disconnecting from database..\t\t";
        $db->disconnect() or die("[ fail ]\n");
        print "[ done ]\n";
}

# void setDBConfig
#
sub setDBConfig
{
	print "  Loading database configuration..\t";
	$query = "SELECT
			keyname,
			value
		  FROM
			$conf{DBPrefix}_core_config
		  WHERE
			ext='core'";
	
	foreach $result(&dbQuery($db, $query)) {
		$conf{$result->{key}} = $result->{value};
	}
	print "[ done ]\n";
}

sub setCLConfig()
{	
	my ($cl_help, $cl_version, $cl_debug, $cl_nodebug, $cl_verbose, 
		$cl_quiet, $cl_stdin, $cl_serverip, $cl_serverport, 
		$cl_dns, $cl_rcon, $cl_timestamp);
	# Read command line variables into %conf (overwrite)
	print "  Loading commandline configuration..\t";
	GetOptions(
		"help|h"		=> \$cl_help,
		"version|V"		=> \$cl_version,
		"update|u=s"		=> \$conf{Update},
		"debug|d+"		=> \$cl_debug,
		"nodebug|n+"		=> \$cl_nodebug,
		"mode|m=s"		=> \$conf{LogMode},
		"verbose|v"		=> \$cl_verbose,
		"quiet|q"		=> \$cl_quiet,
		"stdin!"		=> \$cl_stdin,
		"s"			=> \$cl_stdin,
		"server-ip|i=s"		=> \$cl_serverip,
		"server-port|p=s"	=> \$cl_serverport,
		"udp-ip=s"		=> \$conf{NetUDPHost},
		"udp-port=s"		=> \$conf{NetUDPPort},
		"tcp-ip=s"		=> \$conf{NetTCPHost},
		"tcp-port=s"		=> \$conf{NetTCPPort},
		"db-type=s"		=> \$conf{DBType},
		"db-host=s"		=> \$conf{DBHost},
		"db-port=s"		=> \$conf{DBPort},
		"db-name=s"		=> \$conf{DBName},
		"db-prefix=s"		=> \$conf{DBPrefix},
		"db-user=s"		=> \$conf{DBUser},
		"db-pass=s"		=> \$conf{DBPass},
		"dns!"			=> \$cl_dns,
		"dns-timeout=i"		=> \$conf{DNSTimeout},
		"dns-locate!"		=> \$conf{DNSGeoLookup},
		"rcon!"			=> \$cl_rcon,
		"timestamp!"		=> \$cl_timestamp
	) or die($usage);
	#Act on $cl_ vars
	# Setup listen ips/ports if no/bad value exists
	$conf{NetUDPHost} = "0.0.0.0" if (!$conf{NetUDPHost});
	$conf{NetUDPPort} = 27500 if (!($conf{NetUDPPort}));
	$conf{NetTCPHost} = "0.0.0.0" if (!$conf{NetTCPHost});
	$conf{NetTCPPort} = 27500 if (!($conf{NetTCPPort}));
	print "[ done ]\n";
}

# void netCreateTCPSocket()
#
# Creates the TCP Listener thread
#
sub netCreateTCPSocket
{
	print "  Creating TCP listener thread..\t";
	$tcpThread = threads->new(\&tcpListener());
}

# void netCreateUDPSocket()
#
# Creates UDP Listen Socket
#
sub netCreateUDPSocket
{
	print "  Creating UDP listen socket..\t\t";
	$udpSocket = IO::Socket::INET->new(Proto=>"udp",
					   LocalHost=>$conf{NetUDPHost},
					   LocalPort=>$conf{NetUDPPort})
	or die("[ fail ]\n\nCould not create UDP listen socket:\n->$@\n");
	print "[ done ]\n";
	print "    Listening on port $conf{NetTCPPort}(UDP).\n";
}
