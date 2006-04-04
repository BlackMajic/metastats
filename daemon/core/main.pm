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
# ################################################
# No  modifications are  nessecary  to this  file;
# please  see   the  documentation  and  edit  the
# 'metastats.conf'   file  to   configure   custom
# settings for this daemon.
# ################################################

use strict;
use POSIX;

# array dbQuery (object dbObject; string dbQuery)
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
		print "$queries[$i]\n" if ($main::conf{Debug} >= 5);
		# Stop multipul queries from happening in one string
		my $dbQuery = (split /[^\\];/, $queries[$i])[0];
		
		my $dbStatement = $dbObject->prepare($dbQuery)
					or die("Unable to prepare query");
		$dbStatement->execute() or die ("Unable to execute statement");
		
		while ($row = $dbStatement->fetchrow_hashref()) {
			push @results, $row;
		}
	}
	return @results;
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
	
	my $http = IO::Socket::INET->new(Proto=>"tcp",
					 PeerAddr=>$updateserver,
					 PeerPort=>$updateport,
					 Reuse=>1,
					 Timeout=>1)
			or die("[ fail ]\n");
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
	
	my @res_ver = ();
	@res_ver[0] = $maj;
	@res_ver[1] = $min;
	@res_ver[2] = $rev;
	
	return @res_ver;
}

# array updateMetastats()
#
# Compares major, minor, and revision versions,
# downloads update script and runs it.
#
sub updateMetastats
{
	my ($update) = @_;
	print "  Checking for updates..\t\t";
	if ($update == "stable" || $update == "beta") {
		my ($rMaj, $rMin, $rRev) = updateGetVersion();
		my ($lMaj, $lMin, $lRev) = split(/\./, $main::version);
		print "[ done ]\n";
		if ($lMaj < $rMaj) {
			print "    **A major update is available**\n";
		} elsif ($lMin < $rMin) {
			print "    **A minor update is available**\n";
		} elsif ($lRev < $rRev) {
			print "    **An update is available**\n";
		} else {
			if (!$rMaj && !$rMin && !$rRev) {
				print "    Metastats cannot contact the update server.\n";
			} else {
				print "    Metastats is up to date.\n";
			}
		}
	} else {
		print "[ skip ]\n"
	}
}

# void getTrackedServers()
#
# SELECT the servers stored in the database, save them into a hash
# then load them into their game/mod hash respectively.
#
sub getTrackedServers
{
	my ($query, $result);
	print "  Identifying Tracked Servers..\n";
	$query = "SELECT
			server_id,
			server_ip,
			server_port,
			server_name,
			server_game,
			server_mod,
			server_rcon
		  FROM
			$main::conf{DBPrefix}_core_servers";
	
	foreach $result (&dbQuery($main::db, $query)) {
		print "    $result->{server_ip}:$result->{server_port}\n";
		$main::servers{$result->{server_id}} = [$result->{server_ip},
							$result->{server_port},
							$result->{server_name},
							$result->{server_game},
							$result->{server_mod},
							$result->{server_rcon}];
		
		# Associate server ip:port with its ID for quicker checking
		$main::server_ips{$result->{server_ip}.":".$result->{server_port}} = $result->{server_id};
	}
	$result = '';
	
	$query = "SELECT
			mod,
			mod_name
		  FROM
			$main::conf{DBPrefix}_core_modules";
	
	foreach $result (&dbQuery($main::db, $query)) {
		$main::games{$result->{mod}} = $result->{mod_name};
	}
	$result = '';
	
	$query = "SELECT
			id,
			ext
		  FROM
			$main::conf{DBPrefix}_core_extensions";
	
	foreach $result (&dbQuery($main::db, $query)) {
		$main::mods{$result->{id}} = $result->{ext};
	}
}

1;
