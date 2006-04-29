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
Getopt::Long::Configure ("bundling");

$|=1;
$SIG{'HUP'} = \&sigHUP;
#$SIG{'INT'} = \&sigDIE;
#$SIG{__DIE__} = \&sigDIE;

##
## Initialize variables & defaults
##
our $version = '00.00.73';
my $db;
our %conf;
my (%cl);

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
      --delete-days=DAYS	Number of days to store kill data. (Default 7)
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

# Read command line args into hash so they can be read later
GetOptions(
	"help|h|?"		=> \$cl{help},
	"version|V"		=> \$cl{version},
	"update|u=s"		=> \$cl{update},
	"debug|d+"		=> \$cl{debug},
	"nodebug|n+"		=> \$cl{nodebug},
	"mode|m=s"		=> \$cl{mode},
	"verbose|v"		=> \$cl{verbose},
	"quiet|q"		=> \$cl{quiet},
	"stdin!"		=> \$cl{stdin},
	"s"			=> \$cl{stdin},
	"server-ip|i=s"		=> \$cl{serverip},
	"server-port|p=s"	=> \$cl{serverport},
	"udp-ip=s"		=> \$cl{udpip},
	"udp-port=s"		=> \$cl{udpport},
	"tcp-ip=s"		=> \$cl{tcpip},
	"tcp-port=s"		=> \$cl{tcpport},
	"db-type=s"		=> \$cl{dbtype},
	"db-host=s"		=> \$cl{dbhost},
	"db-port=s"		=> \$cl{dbport},
	"db-name=s"		=> \$cl{dbname},
	"db-prefix=s"		=> \$cl{dbprefix},
	"db-user=s"		=> \$cl{dbuser},
	"db-pass=s"		=> \$cl{dbpass},
	"delete-days=i"		=> \$cl{deletedays},
	"dns!"			=> \$cl{dns},
	"dns-timeout=i"		=> \$cl{dnstimeout},
	"dns-locate!"		=> \$cl{dnslocate},
	"rcon!"			=> \$cl{rcon},
	"timestamp!"		=> \$cl{timestamp}
) or exit();
die($usage)  if ($cl{help});
die($header) if ($cl{version});

# Check Dependancies
$Config{useithreads} or die "Metastats $version requires ithreads support. Please recompile perl(5.8.1+) and then reload Metastats.\n\n";

##
## Begin Execution
##
print $header;

# Populate %conf, connect to DB
%conf = setPerlConfig();
%conf = setConfConfig($configfile, %conf);
require "$conf{CoreDir}/main.pm";
$db = dbConnect();
%conf = setDBConfig($db, %conf);
%conf = setCLConfig(%conf, %cl);				#%cl is global?

# Auto-update Metastats (if set)
updateMetastats($conf{Update});

# Init Modules/Extensions
our %handler = getHandlers($db);

# Get a list of our tracked servers
our (%servers, %serverIPs);
getTrackedServers($db);						#Returns nothing

# Create Sockets
my ($tcpThread, $udpSocket);
#my $tcpThread = netCreateTCPSocket();				#Infanant Loop
my $udpSocket = netCreateUDPSocket();

print "\n  Now logging using time from ";
print "logs" if ($conf{UseTimestamp});
print "db"   if (!$conf{UseTimestamp});
print " in $conf{Mode} Mode\n";
print "--------------------------------------------------\n\n";

##
## Main Loop
##
for (;;) {
	my ($incdata, $UDPHost, $UDPPort, $serverID);
	#'L 01/24/2006 - 18:13:08: "-vdp.a"n"<>>><<guishness!!!!<2><STEAM_0:0:705082><CT>" killed "VULGARDISPLAYOFPOWERnice<1><STEAM_0:1:9409988><TERRORIST>" with "usp"';
	if ($conf{STDIN}) {
		$UDPHost = $conf{LogIP};
		$UDPPort = $conf{LogPort};
		$incdata = <STDIN>;
	} else {
		$udpSocket->recv($incdata, 1024);
		$UDPHost = $udpSocket->peerhost;
		$UDPPort = $udpSocket->peerport;
	}
	
	$serverID = $serverIPs{$UDPHost.':'.$UDPPort};
	
	if ($serverID) {
		print "Recognised $servers{$serverID}->{Module} server $UDPHost:$UDPPort\n";
		$servers{$serverID}->{Module}->parse($db, $servers{$serverID}, $incdata);
	} else {
		print "--> Unrecognised server $UDPHost:$UDPPort\n";
	}
}

##
## Functions
##

# void setPerlConfig()
#
# Sets default values for %config
#
sub setPerlConfig
{
	print "  Reading default config..\t\t";
	my %cv = {};
	$cv{CoreDir}		= './core';
	$cv{ModuleDir}		= './modules';
	$cv{UseTimestamp}	= 0;
	$cv{DBType}		= 'mysql';
	$cv{DBHost}		= 'localhost';
	$cv{DBPort}		= '3306';
	$cv{DBName}		= 'metastats';
	$cv{DBUser}		= 'metastats';
	$cv{DBPass}		= '';
	$cv{DBPrefix}		= 'ms';
	$cv{DBLowPriority}	= 0;
	$cv{NetUDPHost}		= '';
	$cv{NetUDPPort}		= '27500';
	$cv{NetTCPHost}		= '';
	$cv{NetTCPPort}		= '27500';
	print "[ done ]\n";
	
	return %cv;
}

# hash parseConfig (string configFile)
#
# Open the config file, and parse it's contents
# into a hash
#
sub setConfConfig
{
	my ($configFile, %cv) = @_;
	
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

# void setDBConfig
#
# Reads the database for configuration info
#
sub setDBConfig
{
	my ($db, %cv) = @_;
	print "  Loading database configuration..\t";
	my $query = "SELECT
			keyname,
			value
		  FROM
			$conf{DBPrefix}_core_config
		  WHERE
			ext='core'";
	
	foreach my $result(dbQuery($db, $query)) {
		$cv{$result->{keyname}} = $result->{value};
	}
	print "[ done ]\n";
	return %cv;
}

sub setCLConfig
{
	my (%cv) = @_;
	# WTF? %cl is global?
	#foreach my $i (keys %cl) { print "$i = $cl{$i}\n"; }
	
	# Read command line variables %cl into %conf (overwrite)
	print "  Loading commandline configuration..\t";
	die($usage)					if ($cl{help});
	die($header)					if ($cl{version});
	$cv{Update}		= $cl{update}		if ($cl{update});
	$cv{LogLevel}		+= $cl{debug}		if ($cl{debug});
	$cv{LogLevel}		-= $cl{nodebug}		if ($cl{nodebug});
	$cv{LogLevel}		= 0			if ($conf{Debug} < 0);
	$cv{Mode}		= $cl{mode}		if ($cl{mode});
	$cv{LogEcho}		= 1			if ($cl{verbose});
	$cv{LogEcho}		= 0			if ($cl{quiet});
	# STDIN info
	$cv{STDIN}		= 1			if ($cl{stdin});
	$cv{STDIN}		= 0			if (!$cl{stdin});
	$cv{STDIN}		= 1			if ($cl{s});
	$cv{LogIP}		= $cl{serverip}		if ($cl{serverip});
	$cv{LogPort}		= $cl{serverport}	if ($cl{serverport});
	$cv{NetUDPHost}		= $cl{udpip}		if ($cl{udpip});
	$cv{NetUDPPort}		= $cl{udpport}		if ($cl{udpport});
	$cv{NetTCPHost}		= $cl{tcpip}		if ($cl{tcpip});
	$cv{NetTCPPort}		= $cl{tcpport}		if ($cl{tcpport});
	$cv{NetUDPHost} 	= "0.0.0.0"		if (!$conf{NetUDPHost});
	$cv{NetUDPPort} 	= 27500			if (!$conf{NetUDPPort});
	$cv{NetTCPHost} 	= "0.0.0.0"		if (!$conf{NetTCPHost});
	$cv{NetTCPPort} 	= 27500			if (!$conf{NetTCPPort});
	# Database settings
	$cv{DBType}		= $cl{dbtype}		if ($cl{dbtype});
	$cv{DBHost}		= $cl{dbhost}		if ($cl{dbhost});
	$cv{DBPort}		= $cl{dbport}		if ($cl{dbport});
	$cv{DBName}		= $cl{dbname}		if ($cl{dbname});
	$cv{DBPrefix}		= $cl{dbprefix}		if ($cl{dbprefix});
	$cv{DBUser}		= $cl{dbuser}		if ($cl{dbuser});
	$cv{DBPass}		= $cl{dbpass}		if ($cl{dbpass});
	$cv{DeleteDays}		= $cl{deletedays}	if ($cl{deletedays});
	# DNS settings
	$cv{DNSEnable}		= 1			if ($cl{dns});
	$cv{DNSEnable}		= 0			if (!$cl{dns});
	$cv{DNSTimeout}		= $cl{dnstimeout}	if ($cl{dnstimeout});
	$cv{DNSGeoLocate}	= 1			if ($cl{dnslocate});
	$cv{RconEnable}		= 1			if ($cl{rcon});
	$cv{RconEnable}		= 0			if (!$cl{rcon});
	$cv{UseTimestamp}	= 1			if ($cl{timestamp});
	
	print "[ done ]\n";
	
	return %cv;
}

# void tcpWorker (object socket)
#
# Takes accepted connections from the listener thread and actually
# does something with them
#
sub tcpWorker
{
	my ($sockid) = @_;
	my $incdata = '';
	
	while ($sockid->recv($incdata, 1024)) {
		print "TCP-> $incdata\n";
	}
	print "  Worker thread exiting\n";
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

# void netCreateTCPSocket()
#
# Creates the TCP Listener thread
#
sub netCreateTCPSocket
{
	print "  Creating TCP listener thread..\t";
	$tcpThread = threads->new(\&tcpListener());
	return $tcpThread;
}

# void netCreateUDPSocket()
#
# Creates UDP Listen Socket
#
sub netCreateUDPSocket
{
	print "\n  Creating UDP listen socket..\t\t";
	$udpSocket = IO::Socket::INET->new(Proto=>"udp",
					   LocalHost=>$conf{NetUDPHost},
					   LocalPort=>$conf{NetUDPPort})
	or die("[ fail ]\n\nCould not create UDP listen socket:\n->$@\n");
	print "[ done ]\n";
	print "    Listening on port $conf{NetTCPPort}(UDP).\n";
	return $udpSocket;
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
	getTrackedServers();
	print "  Continuing logging..\n\n";
}

# void sigDIE()
#
# Tidy up and exit.
#
sub sigDIE
{
	# Tidy up!
	print "\n\n  Recieved SIGDIE\n";
	dbDisconnect();
	print "  Done.\n\n";
	die("SIGDIE");
}
