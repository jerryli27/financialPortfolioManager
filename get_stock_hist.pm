package get_stock_hist;

use Data::Dumper;
use Getopt::Long;
use Time::ParseDate;
use Time::CTime;
use FileHandle;

use Date::Manip;

use Finance::QuoteHist::Yahoo;
use Finance::Quote;
require Exporter;

@ISA=qw(Exporter);
@EXPORT=qw(insertStockHist insertStockHistUnixTime getAllStocksHist insertLatestStockHist);

use DBI;
# import stock_data_access because we need to exec sql
use stock_data_access;
# Headers copied from stock_data_access.pm

#
# oracle sqlplus credential
# 
my $user="yfo776";
my $pass="zv0XOar1o";
#
# Insert the historical data of a stock symbol into database
# Default is get the data for last year.
# You can also enter date/time.
sub insertStockHist {
	my ($symbol,$from,$to) = @_;
	if (!(defined $from)){
		$from = "last year";
	}
	if (!(defined $to)){
		$to = "now";
	}

	# convert date model to what QuoteHist wants
	# while assuring we can use Time::ParseDate parsing
	# for compatability with everything else
	$from = parsedate($from);
	$from = ParseDateString("epoch $from");
	$to = parsedate($to);
	$to = ParseDateString("epoch $to");

	%query = (
		  symbols    => [$symbol],
		  start_date => $from,
		  end_date   => $to,
		 );


	$q = new Finance::QuoteHist::Yahoo(%query) or die "Cannot issue query\n";
	my @sqlReturn;
	foreach $row ($q->quotes()) {
	  	# The eval catches the error and do not terminate the program if there is one.
		eval {
			($qsymbol, $qdate, $qopen, $qhigh, $qlow, $qclose, $qvolume) = @{$row};
		 	$qdate=parsedate($qdate);
			my $sql="INSERT INTO portfolio_stocks
					VALUES (\'$qsymbol\', $qdate, $qopen, $qhigh, $qlow, $qclose, $qvolume)";
		 	@sqlReturn=ExecStockSQL(undef,$sql);
		};
		if ( $@ ) {
			#print("sql execution error");
		}
	}
}

#
# Insert the historical data of a stock symbol into database
# to and from must be unix time stamp
sub insertStockHistUnixTime {
	my ($symbol,$from,$to) = @_;
	if (!(defined $from)){
		$from = "last year";
		$from = parsedate($from);
	}
	if (!(defined $to)){
		$to = "now";
		$to = parsedate($to);
	}

	# convert date model to what QuoteHist wants
	# while assuring we can use Time::ParseDate parsing
	# for compatability with everything else
	$from = ParseDateString("epoch $from");
	$to = ParseDateString("epoch $to");
	#print ("From: ".$from." To: ".$to);
	
	%query = (
		  symbols    => [$symbol],
		  start_date => $from,
		  end_date   => $to,
		 );


	$q = new Finance::QuoteHist::Yahoo(%query) or die "Cannot issue query\n";
	my @sqlReturn;
	# I had to connect to oracle this way because we're entering thousands of tuples and speed matters.
	# Log into database takes time and should be done only once.
	# Sorry if the code looks messy.

	my $dbh;
	$dbh = DBI->connect("DBI:Oracle:",$user,$pass);
	if (not $dbh) { 
	die "Can't connect to database because of ".$DBI::errstr;
	}
	my @data;
	my @ret;
	my $sth;
	my $sql;

	foreach $row ($q->quotes()) {
	  	# The eval catches the error and do not terminate the program if there is one.
		eval {
			($qsymbol, $qdate, $qopen, $qhigh, $qlow, $qclose, $qvolume) = @{$row};
		 	$qdate=parsedate($qdate);
			$sql="INSERT INTO portfolio_stocks
					VALUES (\'$qsymbol\', $qdate, $qopen, $qhigh, $qlow, $qclose, $qvolume)";
			#send the query
		 	$sth = $dbh->prepare($sql);

			if (not $sth) { 
				my $errstr="Can't prepare $querystring because of ".$DBI::errstr;
				#$dbh->disconnect(); #commented out this because we still need to insert the rest of data.
				die $errstr;
			}
			if (not $sth->execute()) { 
				my $errstr="Can't execute $querystring because of ".$DBI::errstr;
				#$dbh->disconnect();#commented out this because we still need to insert the rest of data.
				die $errstr;
			}
			# multirow or single column output or strings
			while (@data=$sth->fetchrow_array()) {
				#push @ret, [@data];
			}
		};
		if ( $@ ) {
			#print("sql execution error");
		}
	}
	if (defined($sth)){
		$sth->finish();
	}
	$dbh->disconnect();
}

#
# Insert the historical data of all known stock symbol into database
# Note that this might take a while.
# 
sub getAllStocksHist{
	# Get a list of all the symbols of stocks, their start date, and their end date involved in our transactions.
	my @symbols = ExecStockSQL(undef,"SELECT symbol,max(timestamp) FROM portfolio_allStocks GROUP BY symbol");
	# Get current time
	my $to = parsedate("now");
	my @rows; my @table;
	my $counter=0;
	foreach (@symbols){
		# print ("Inserting stock: ".$symbols[$counter][0]." Timestamp from: ".$symbols[$counter][1]." to ".$to);
		insertStockHistUnixTime($symbols[$counter][0],$symbols[$counter][1],$to);
		$counter=$counter+1;
		
	}
}


sub insertLatestStockHist{
	@info=("date","time","high","low","close","open","volume","last");
	# Get a list of all the symbols of stocks, their start date, and their end date involved in our transactions.
	my @symbols = ExecStockSQL(undef,"SELECT DISTINCT symbol FROM portfolio_allStocks");
	#my @symbols = ("GE");
	$con=Finance::Quote->new();

	$con->timeout(60);

	%quotes = $con->fetch("usa",@symbols);
	# I had to connect to oracle this way because we're entering thousands of tuples and speed matters.
	# Log into database takes time and should be done only once.
	# Sorry if the code looks messy.

	my $dbh;
	$dbh = DBI->connect("DBI:Oracle:",$user,$pass);
	if (not $dbh) { 
	die "Can't connect to database because of ".$DBI::errstr;
	}
	my @data;
	my @ret;
	my $sth;
	my $sql;
	my $symbol;
	foreach (@symbols) {
		$symbol=$$_[0];
	    #print($symbol,"\n=========\n");
	    if (!defined($quotes{$symbol,"success"})) { 
		# print "No Data\n";
	    } else {
	    	print($symbol);
	    	return;
			if (defined($quotes{$symbol,"date"})&&defined($quotes{$symbol,"time"})) {
				# The eval catches the error and do not terminate the program if there is one.
				eval {
					my $time=parsedate($quotes{$symbol,"date"}." ".$quotes{$symbol,"time"}); #epoch time
					$sql="INSERT INTO portfolio_stocks
					VALUES (\'$symbol\', $time, $quotes{$symbol,\"open\"}, $quotes{$symbol,\"high\"}, 
					$quotes{$symbol,\"low\"}, $quotes{$symbol,\"close\"}, $quotes{$symbol,\"volume\"})";
					#send the query
				 	$sth = $dbh->prepare($sql);

					if (not $sth) { 
						my $errstr="Can't prepare $querystring because of ".$DBI::errstr;
						#$dbh->disconnect(); #commented out this because we still need to insert the rest of data.
						die $errstr;
						#print($errstr);
					}
					if (not $sth->execute()) { 
						my $errstr="Can't execute $querystring because of ".$DBI::errstr;
						#$dbh->disconnect();#commented out this because we still need to insert the rest of data.
						die $errstr;
						#print($errstr);
					}
					# multirow or single column output or strings
					while (@data=$sth->fetchrow_array()) {
						#push @ret, [@data];
					}
				};
				if ( $@ ) {
					# sql will print error message. Don't need to do anything
				}
			}
			# foreach $key (@info) {
			#     if (defined($quotes{$symbol,$key})) {
			# 	print $key,"\t",$quotes{$symbol,$key},"\n";
			#     }
			# }
	    }
	    print "\n";
	}
	if (defined($sth)){
		$sth->finish();
	}
	$dbh->disconnect();
}

