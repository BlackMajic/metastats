#!/usr/bin/perl
#
# Metastats Listener Daemon
# ------------------------------------------------
# A statistical data logger for multiplayer games
# Copyright (c) 2004-2006, Nick Thomson.
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
$SIG{HUP} = \&sigHUP;
$SIG{__DIE__} = \&sigDIE;

##
## Initialize variables & defaults
##
our $version = '00.00.59';
our $db;
my ($query, $result);
my ($cl_help, $cl_version, $cl_stdin, $cl_server_ip, $cl_server_port);

my $header = "\nMetastats Listener Daemon $version
-----------------------------------------------
A statistical data logger for multiplayer games
http://metastats.sourceforge.net
Copyright (c) 2004-2006 Nick Thomson.
Copyright (c) 2006      Tim McLennan.

Metastats comes with ABSOLUTELY NO WARRANTY. This
is free software, you are welcome to redistribute
it under certain conditions. For further details,
please visit http://www.gnu.org/copyleft/gpl.html\n\n";

my $usage = "\nUsage: [cat PATH/*.log |] $0 [OPTIONS]...\n
Recieve streamed logs from one or more gameservers
to be parsed and inserted into a database of some sort.

  -h, --help			Display this notice.
  -V, --version			Display version information.
  -d, --debug			Enable debug output (-dd = higher level)
  -n, --nodebug			Disables debug output (-nn = lower level)
  -m, --mode=MODE		Select tracking mode (Normal, NameTrack, Lan)
  -v, --verbose			Print debug information to console.
??-o, --output=FILE		Outputs debug data to FILE.
  -s, --stdin			Read logs from <STDIN> instead of a stream.
  -i, --server-ip		IP Address of the server from which the 
				logs you are reading from <STDIN> came from.
  -p, --server-port		Port of the server above.
      --nostdin			Reads from stream.
      --db-host=HOST		Database server ip address or hostname.
      --db-port=PORT		Database server port.
      --db-type=TYPE		Type of database to connect to.
      --db-name=DATABASE	Database name to connect to.
      --db-prefix=PREFIX	Table prefix in use on database.
      --db-user=USERNAME	Database username.
      --db-pass=PASSWORD	Database password.
      --dns			Enable DNS hostname resolution.
      --dns-timeout		Timout DNS queries after n seconds.
  -l, --dns-locate		Enable GeoLocation DNS feature.
      --nodns			Disables ALL DNS features.
  -r, --rcon			Send rcon commands to logged servers.
  -R, --norcon			Disables above.
  -t, --timestamp		Use timestamp in logs.
  -T, --notimestamp		Use timestamp on database server.
  -u, --update-stable		Automatically update to a stable build.
  -b, --update-beta		Automatically update to a beta build.

Note: Options specified on the command line overwrite
      options in $configfile.\n\n";

our %conf;		# Setup default values
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
$conf{UDPListenHost}	= '*';
$conf{UDPListenPort}	= '27500';
$conf{TCPListenHost}	= '*';
$conf{TCPListenPort}	= '27500';
$conf{LogLevel}		= 0;
$conf{LogEcho}		= 1;
$conf{LogFile}		= '';
$conf{LogCloneDir}	= '';
$conf{LogCloneOneFile}	= '';
$conf{LogForward}	= '';
$conf{CrashReport}	= './crash.txt';
$conf{CrashNotify}	= '';
$conf{UpdateStable}	= 0;
$conf{UpdateBeta}	= 0;

# Read command line args
GetOptions(
	"help|h"	=> \$cl_help,
	"version|V"	=> \$cl_version);

die($usage)  if ($cl_help);
die($header) if ($cl_version);

#
# Check Dependancies
#
$Config{useithreads} or die "Metastats $version requires ithreads for TCP support.Please recompile perl(5.8.1+) and then reload Metastats.\n\n";

##
## Begin Execution
##
print $header;				# Print Metastats information
%conf = parseConfig($configfile);	# Parse our config
require "$conf{CoreDir}/main.pm";	# Include required files

#
# Auto-update Metastats
#
updateMetastats();

#
# Connect to Database
#
print "   Connecting to database..\t\t";
$db = DBI->connect("DBI:$conf{DBType}:".$conf{DBName}.":".$conf{DBHost}.":".$conf{DBPort}, $conf{DBUser}, $conf{DBPass})
		or die("[ fail ]\n   Unable to connect to database:\n->$DBI::errstr\n");
print "[ done ]\n";

#
# Read DB Config
#
print "   Loading configuration data from db..\t";
$query = "SELECT
		keyname,
		value
	  FROM
		$conf{DBPrefix}_core_config
	  WHERE
		ext='core'";
foreach $result(dbQuery($db, $query)) {
        $conf{$result->{key}} = $result->{value};
}
print "[ done ]\n";

#
# Read command line variables into %conf (overwrite)
#
GetOptions(
	"help|h"		=> \$cl_help,
	"version|V"		=> \$cl_version,
	"debug|d+"		=> \$conf{LogLevel},
	"nodebug|n+"		=> \$conf{LogLevel},
	"mode|m=s"		=> \$conf{Mode},
	"verbose|v"		=> \$conf{LogEcho},
	"output|o=s"		=> \$conf{LogFile},
	"stdin!"		=> \$cl_stdin,
	"s"			=> \$cl_stdin,
	"server-ip|i=s"		=> \$cl_server_ip,
	"server-port|p=i"	=> \$cl_server_port,
	"db-host=s"		=> \$conf{DBHost},
	"db-port=s"		=> \$conf{DBPort},
	"db-type=s"		=> \$conf{DBType},
	"db-name=s"		=> \$conf{DBName},
	"db-prefix=s"		=> \$conf{DBPrefix},
	"db-username=s"		=> \$conf{DBUser},
	"db-password=s"		=> \$conf{DBPass},
	"dns!"			=> \$conf{DNSResolveIP},
	"dns-timeout=i"		=> \$conf{DNSTimeout},
	"dns-locate|l"		=> \$conf{DNSGeoLocate},
	"rcon!"			=> \$conf{RconEnable},
	"r"			=> \$conf{RconEnable},
	"timestamp!"		=> \$conf{UseTimestamp},
	"t"			=> \$conf{UseTimestamp}
) or die($usage);

# Setup listen ips/ports if no/bad value exists
$conf{UDPListenHost} = "0.0.0.0" if ($conf{UDPListenHost} == "*" || !$conf{UDPListenHost});
$conf{UDPListenPort} = 27500 if (!($conf{UDPListenPort}));
$conf{TCPListenHost} = "0.0.0.0" if ($conf{TCPListenHost} == "*" || !$conf{TCPListenHost});
$conf{TCPListenPort} = 27500 if (!($conf{TCPListenPort}));

#
# Include Modules
#
my @mods = ();
my %handlers = {};
my %players = {};

loadModules();

#
# Get a list of our tracked servers
#
my %servers = {};
my %server_ips = {};
my %games = {};
my %mods = {};
my %modifiers = {};
my %defs = {};

getTrackedServers();

#
# Create UDP Socket
#
print "   Creating UDP listen socket..\t\t";
my $lsocket = IO::Socket::INET->new(Proto=>"udp",
		LocalHost=>$conf{UDPListenHost},
		LocalPort=>$conf{UDPListenPort})
		or die("[ fail ]\n\nCould not create UDP listening socket:\n->$@\n");
print "[ done ]\n";
print "\n   Listening on port $conf{UDPListenPort}(UDP).\n\n";

#
# Create TCP Socket
#
print "   Creating TCP listener thread..\t";
my $tcpThread = threads->new(\&tcpListener());

##
## Main Loop
##
for (;;) {
	my $incdata = "";
	$lsocket->recv($incdata, 1024);
	my $l_remote_host = $lsocket->peerhost;
	my $l_remote_port = $lsocket->peerport;
	my $serverid = $server_ips{$l_remote_host.":".$l_remote_port};
	if ($serverid) {
		print "Recognised server\n";
	} else {
		print "Unrecognised server\n";
	}
	$games{$servers{$serverid}[3]}->parse($serverid, $mods{$servers{$serverid}[4]}, $incdata);
}

##
## Functions
##

# void tcpListener ()
#
# Thread to handle the TCP listening socket
#
sub tcpListener
{
	print "[ done ]\n   Creating TCP listen socket..\t\t";
	my $tlsocket = IO::Socket::INET->new(Proto=>"tcp",
						Listen=>1,
						Reuse=>1,
						LocalHost=>$conf{TCPListenHost},
						LocalPort=>$conf{TCPListenPort})
				or die("[ fail ]\n\nCould not create TCP listening socket:\n->$@\n");
	print "[ done ]\n";
	print "\n   Listening on port $conf{TCPListenPort}(TCP).\n\n";
	for (;;) {
		my $tlsock_new = $tlsocket->accept();
		print "   ** Incoming TCP connection from ".$tlsock_new->peerhost.":".$tlsock_new->peerport."..\n";
		print "   Launching new worker thread..\n";
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
	while ($sockid->recv($incdata, 1024))
	{
		print "-> $incdata\n";
	}
	print "   Worker thread exiting\n";
}

# hash parseConfig (string configFile)
#
# Open the config file, and parse it's contents
# into a hash
#
sub parseConfig
{
	my ($configFile) = @_;
	my %cv = undef;
	
	print "   Loading configuration file..\t\t";
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
	print "\n   Loading Support Modules..\n";
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
	print "   Completed Loading Modules.\n\n";
	
	# Include Extension Modules
	print "   Loading Extension Modules..\n";
	my $mod;
	foreach $mod (@mods) {
		require $conf{ModuleDir}.'/'.$mod;
		$mod =~ s/\.mem$//;
		$mod->init();
		$handlers{$mod} = {};
	}
	print "   Completed Loading Extensions\n\n";
}

# void getTrackedServers()
#
# SELECT the servers stored in the database, save them into a hash
# then load them into their game/mod hash respectively.
#
sub getTrackedServers
{
	print "   Identifying Tracked Servers..\t";
	$query = "SELECT
			server_id,
			server_ip,
			server_port,
			server_name,
			server_mod,
			server_rcon
		  FROM
			$conf{DBPrefix}_core_servers";
	
	foreach $result (&dbQuery($db, $query)) {
		$servers{$result->{server_id}} = [ $result->{server_ip},
						$result->{server_port},
						$result->{server_name},
						$result->{server_mod},
						$result->{server_rcon} ];
		# Associate server ip:port with its ID for quicker checking
		$server_ips{$result->{server_ip}.":".$result->{server_port}} = $result->{server_id};
	}
	$result = '';
	
	foreach $result (&dbQuery($db, "SELECT ext, ext_name FROM $conf{DBPrefix}_core_extensions")) {
		$games{$result->{ext}} = $result->{ext_name};
	}
	$result = '';
	
	foreach $result (&dbQuery($db, "SELECT id, ext FROM $conf{DBPrefix}_core_mods")) {
		$mods{$result->{id}} = $result->{ext};
	}
	print "[ done ]\n";
}
