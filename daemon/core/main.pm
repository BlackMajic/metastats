# Metastats Listener Daemon - Half-Life Game Support Module
# ---------------------------------------------------------
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
# ####################################################
# # No  modifications are  nessecary  to this  file; #
# # please  see   the  documentation  and  edit  the #
# # 'metastats.conf'   file  to   configure   custom #
# # settings for this daemon.                        #
# ####################################################

package main;
use strict;
use POSIX;

# void dbConnect()
#
# Connects to our database
#
sub dbConnect
{
	print "  Connecting to database..\t\t";
	my $db = DBI->connect("DBI:$main::conf{DBType}:".$main::conf{DBName}.":".$main::conf{DBHost}.":".$main::conf{DBPort},
				 $main::conf{DBUser},
				 $main::conf{DBPass})
			or die(boxFail() . "Unable to connect to database:\n->$DBI::errstr\n");
	print boxOK();
	return $db;
}

# array dbQuery (object dbObject, string dbQuery)
# 
# Queries the database specified in dbObject
# recieves results, and places them in an array of hashref's
# returned to the caller.
#
sub dbQuery
{
	my ($dbObject, @queries) = @_;
	my @results = ();
	my $row = '';
	my $i;
	
	foreach $i ($main::queries) {
		print "\n$queries[$i]\n" if ($main::conf{LogLevel} >= 5);
		# Stop multipul queries from happening in one string
		my $dbQuery = (split /[^\\];/, $queries[$i])[0];
		
		my $dbStatement = $dbObject->prepare($dbQuery)
					or errorMessage("Unable to prepare query: $dbQuery");
		$dbStatement->execute() or errorMessage("Unable to execute statement: $dbQuery");
		
		if ($queries[$i] =~ /SELECT/) {
			while ($row = $dbStatement->fetchrow_hashref()) {
				push @results, $row;
			}
		}
	}
	return @results;
}

# void dbDisconnect(object dbObject)
#
# Disconnects from our database
#
sub dbDisconnect
{
	my ($db) = @_;
	print "  Disconnecting from database..\t\t";
	
	$db->disconnect() or die(boxFail());
	
	boxOK()
}

# updateCache ()
#
sub updateCache
{
}

# array updateGetVersion ()
# 
# Queries the update server, and returns a 3 value array containing the 
# major, minor, and revision versions respectively.
#
sub updateGetVersion
{
	my $updateserver = "metastats.sourceforge.net";
	my $updateport = "80";
	my $updateurl = "/update.php";
	my ($ln, $maj, $min, $rev);
	my @res_ver = (0,0,0);
	
	my $http = IO::Socket::INET->new(Proto=>"tcp",
					 PeerAddr=>$updateserver,
					 PeerPort=>$updateport,
					 Reuse=>1,
					 Timeout=>10)
			or return @res_ver;
	$http->autoflush(1);
	send ($http,"GET $updateurl HTTP/1.0\nHost: $updateserver\nConnection: keep-alive\n\n",0);
	while (<$http>) {
		$ln = $_;
		chop $ln;
		$ln =~ s/\s//g;
		if ($ln =~ /^MSV\|(\d\d)\.(\d\d)\.(\d\d)/) {
			($maj, $min, $rev) = ($1, $2, $3);
		}
	}
	close ($http);
	
	$res_ver[0] = $maj;
	$res_ver[1] = $min;
	$res_ver[2] = $rev;
	
	return @res_ver;
}

# array updateMetastats()
#
# Compares major, minor, and revision versions,
# downloads update script and runs it.
#
sub updateMetastats
{
	my($update) = @_;
	print "  Checking for updates..\t\t";
	if ($update eq "stable" || $update eq "beta") {
		my ($rMaj, $rMin, $rRev) = updateGetVersion();
		my ($lMaj, $lMin, $lRev) = split(/\./, $main::version);
		if ($lMaj < $rMaj) {
			print boxOK() . "    **A major update is available**\n";
		} elsif ($lMin < $rMin) {
			print boxOK() . "    **A minor update is available**\n";
		} elsif ($lRev < $rRev) {
			print boxOK() . "    **An update is available**\n";
		} else {
			if (!$rMaj && !$rMin && !$rRev) {
				print boxFail() . "    Metastats cannot contact the update server.\n";
			} else {
				print boxOK() . "    Metastats is up to date.\n";
			}
		}
	} else {
		print boxSkip();
	}
}

# void getTrackedServers()
#
# SELECT the servers stored in the database, save them into a hash
# then load them into their game/mod hash respectively.
#
sub getTrackedServers
{
	my ($db) = @_;
	my (@ret, %servers, %serverIPs, $total);
	print "\n  Identifying Tracked Servers..\n";
	
	# limit query to existing .msm/.mem
	my $query = "SELECT
			server_id,
			server_ip,
			server_port,
			server_mod,
			server_ext,
			server_rcon,
			server_name
		     FROM
			$main::conf{DBPrefix}_core_servers
		     ORDER BY
			server_mod, server_ext ASC";
	
	foreach my $result (&dbQuery($db, $query)) {
		$total++;
		print "    ($result->{server_mod})\t\t$result->{server_ip}:$result->{server_port}\n";
		$main::servers{$result->{server_id}} = {
			ID		=> $result->{server_id},
			IP		=> $result->{server_ip},
			Port		=> $result->{server_port},
			Name		=> $result->{server_name},
			Module		=> $result->{server_mod},
			Extension	=> "$result->{server_mod}_$result->{server_ext}",
			Rcon		=> $result->{server_rcon},
			Map		=> '',
			MinPlayers	=> $main::conf{MinPlayers},
			Players		=> (),
			Pre		=> ()};
		
		# Associate server ip:port with its ID for quicker checking
		$main::serverIPs{$result->{server_ip}.":".$result->{server_port}} = $result->{server_id};
	}
	$ret[0] = %servers;
	$ret[1] = %serverIPs;
	$total = 0 if (!$total);
	print "  Tracking [ " . colored($total, "bold") . " ] Servers.\n";
	
	return @ret;
}

# hash getHandlers(dbHandle)
#
# Querys db for modules and extensions, then checks if the corresponding 
# files exist. If they do, run init() and load into %handlers (then return it)
#
sub getHandlers
{
	my ($db) = @_;
	my (%handlers, %modules, %extensions);
	my ($query, $result, $r, $good, $total);
	print "\n  Initializing modules and extensions..\n";

	$query = "SELECT
			*
		FROM
			$main::conf{DBPrefix}_core_modules";
	
	foreach $result (&dbQuery($db, $query)) {
		print "   $result->{mod_long}";
		$total++;
		if (-e $main::conf{ModuleDir} . '/' . $result->{mod_short} . '.msm') {
			# Require it
			require $main::conf{ModuleDir} . '/' . $result->{mod_short} . '.msm';
			
			# Initialise it
			if ($result->{mod_short}->init()) {
				$good++;
				$handlers{$result->{mod_short}} = {};
				$query = "SELECT
						*
					FROM
						$main::conf{DBPrefix}_core_extensions
					WHERE
						module = '$result->{mod_short}'";
				foreach $r (&dbQuery($db, $query)) {
					$total++;
					print "    +$r->{ext_long}";
					if (-e $main::conf{ModuleDir} . '/' . $r->{module} . '_' . $r->{ext_short} . '.mem') {
						# Require it
						require $main::conf{ModuleDir} . '/' . $r->{module} . '_' . $r->{ext_short} . '.mem';
						
						# Initialise it
						if ("$r->{module}_$r->{ext_short}"->init()) {
							$good++;
							$handlers{"$r->{module}_$r->{ext_short}"} = {};
						} else {
							print "\t\t\t\t" . boxFail();
						}
					} else {
						print "\t\t\t" . boxNoFile();
					}
				}
			} else {
				print "\t\t\t\t" . boxFail();
			}
		} else {
			print "\t\t\t\t" . boxNoFile();
		}
	}
	print "  [ " . colored("$good of $total", "bold") . " ] Modules Initialized.\n";
	
	return %handlers; #, %modules, %extensions);
}

1;
