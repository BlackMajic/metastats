# Metastats Listener Daemon - Half-Life Game Support Module
# ---------------------------------------------------------
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
	my $dbObject = @_[0];
	my $dbQuery = @_[1];
	my @results = ();
	my $row = '';

	my $dbStatement = $dbObject->prepare($dbQuery) or die("Unable to prepare query");
	$dbStatement->execute() or die ("Unable to execute statement");
	while ($row = $dbStatement->fetchrow_hashref())
	{
		push @results, $row;
	}	

	return @results;

}

sub updateCache
{


}

#
sub updateGetVersion
{

	$updateserver = "jumpingmad.com";
	$updateport = "80";
	$updateurl = "/autoupdate/index.php";


	$http = IO::Socket::INET->new(Proto=>"tcp",PeerAddr=>$updateserver,PeerPort=>$updateport,Reuse=>1) or die "[FAIL]\n";
	$http->autoflush(1);
	send ($http,"GET $updateurl HTTP/1.0\nHost: $updateserver\nConnection: keep-alive\n\n",0);
	while (<$http>)
	{
		$ln = $_;
		chop $ln;
		$ln =~ s/\s//g;
		if ($ln =~ /^UAS\|(\d\d)\.(\d\d)\.(\d\d)/)
		{
			($maj, $min, $rev) = ($1, $2, $3);
		}
	}
	close ($http);

	my @res_ver = ();
	@res_ver[1] = $maj;
	@res_ver[2] = $min;
	@res_ver[3] = $rev;

	return @res_ver;

}

# void parseConfig (string configFile)
#
# Open the config file, and parse it's contents
# into a hash
#
sub parseConfig
{

	my ($configFile) = @_;

	my %cv = undef;

	print "   Loading configuration file..\t\t";
	if (-e $configFile)
	{
		open (cfg, $configFile) || &dieNicely("test");

		while (<cfg>)
		{
			chomp;
			my ($ln) = $_;
			if (!(/^(\040|\t)*#/))
			{		
				# remove double whitespace characters
				$ln =~ s/(\s{2,})/\040/g;

				# remove comments at the end of lines
				$ln =~ s/(#.*)$//;

				# Match any number of letters followed by a space
				# then any number of characters inside quotes
				# OR any number of digits
				$ln =~ /^([a-zA-Z]+)\040((\"(.+)\")|((\d)+))$/;

				# $1 and $2 now contain variable and it's contents
				($var, $val) = ($1, $2);

				$var =~ s/\"//; $var =~ s/\"$//;
				$val =~ s/\"//; $val =~ s/\"$//; 

				$cv{$var} = $val if (($var) && ($val));
			}
		}
		print "done.\n";
	}
	else
	{
		print "failed.\n\n";
		die "The configuration file was not found.\nPlease check that $configFile exists.";
	}

	return %cv;

}

1;