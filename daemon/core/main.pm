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
	
	foreach $i ($queries) {
		$dbQuery = (split /[^\\];/, $queries[$i])[0]; # Stop multipul queries from happening in one string
		
		# Escape SQL statement
		#$dbQuery =~ s/\\/\\\\/g;	# replace \ with \\
		#$dbQuery =~ s/'/\\'/g;		# replace ' with \'
		#$dbQuery =~ s/\;/\\\;/g;	# replace ; with \;
		
		my $dbStatement = $dbObject->prepare($dbQuery)
					or die("Unable to prepare query");
		$dbStatement->execute() or die ("Unable to execute statement");
		while ($row = $dbStatement->fetchrow_hashref()) {
			push @results, $row;
		}
	}
	@queries = ();
	return @results;
}

# updateCache ()
#
sub updateCache
{


}

# array updateGetVersion ()
# Queries the update server, and returns a 3 value array containing the 
# major, minor, and revision versions respectively.
#
sub updateGetVersion
{
	$updateserver = "metastats.sourceforge.net";
	$updateport = "80";
	$updateurl = "/update.php";
	
	$http = IO::Socket::INET->new(Proto=>"tcp",PeerAddr=>$updateserver,PeerPort=>$updateport,Reuse=>1) or die "[ fail ]\n";
	$http->autoflush(1);
	send ($http,"GET $updateurl HTTP/1.0\nHost: $updateserver\nConnection: keep-alive\n\n",0);
	while (<$http>)
	{
		$ln = $_;
		chop $ln;
		$ln =~ s/\s//g;
		if ($ln =~ /^MSV\|(\d\d)\.(\d\d)\.(\d\d)/)
		{
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

sub updateMetastats
{
	print "   Checking for updates..\t\t";
	if ($main::conf{UpdateStable} or $main::conf{UpdateBeta}) {
		my ($vmaj, $vmin, $vrev) = &updateGetVersion();
		my ($cmaj, $cmin, $crev) = split(/\./, $main::version);
		print "[ done ]\n";
		if ($cmaj < $vmaj) {
			print "     ** A major update is available.\n";
		} elsif ($cmin < $vmin) {
			print "     ** A minor update is available.\n";
		} elsif ($crev < $vrev) {
			print "     ** An update is available.\n";
		} else {
			print "     Metastats is up to date.\n";
		}
	} else {
		print "[ skip ]\n"
	}
}

1;
