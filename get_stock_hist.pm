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
@EXPORT=qw(insertStockHist getAllStocksHist insertLatestStockHist);

use DBI;
# import stock_data_access because we need to exec sql
use stock_data_access;

# Headers copied from stock_data_access.pm

#
# Insert the historical data of a stock symbol into database
# Default is get the data for last year.
# You can also enter date/time.
sub insertStockHist {
	my ($symbol,$to,$from) = @_;
	if ($from==undef){
		$from = "last year";
	}
	if ($to==undef){
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

	foreach $row ($q->quotes()) {
	  # my @out;

	  ($qsymbol, $qdate, $qopen, $qhigh, $qlow, $qclose, $qvolume) = @{$row};
	  my $sql="INSERT INTO portfolio_stocks
				VALUES ($qsymbol, $qdate, $qopen, $qhigh, $qlow, $qclose, $qvolume)";
	  ExecStockSQL(undef,$sql);
	}
}
#
# Insert the historical data of all known stock symbol into database
# Default is get the data for last year.
# You can also enter date/time.
sub getAllStocksHist{
	# Get a list of all the symbols of stocks, their start date, and their end date involved in our transactions.
	my @symbols = ExecSQL($dbuser, $dbpasswd, "SELECT symbol,max(timestamp) FROM portfolio_allStocks GROUP BY symbol"
		,undef,$user,$currPortfolioName);
	# Get current time
	$to = parsedate($to);
	$to = ParseDateString("epoch $to");

	my @rows; my @table;
	my $counter=0;
	foreach (@symbols){
		insertStockHist($symbols[$counter][0],$symbols[$counter][1],$to);
		$counter=$counter+1;
	}
}

sub insertLatestStockHist{


	@info=("date","time","high","low","close","open","volume","last");


	# Get a list of all the symbols of stocks, their start date, and their end date involved in our transactions.
	my @symbols = ExecSQL($dbuser, $dbpasswd, "SELECT DISTINCT symbol FROM portfolio_allStocks"
		,undef,$user,$currPortfolioName);

	$con=Finance::Quote->new();

	$con->timeout(60);

	%quotes = $con->fetch("usa",@symbols);

	foreach $symbol (@ARGV) {
	    print $symbol,"\n=========\n";
	    if (!defined($quotes{$symbol,"success"})) { 
		# print "No Data\n";
	    } else {
			if (defined($quotes{$symbol,"date"})&&defined($quotes{$symbol,"time"})) {
				my $time=parsedate($quotes{$symbol,"date"}." ".$quotes{$symbol,"time"});
				$time = ParseDateString("epoch $time");
	  			ExecStockSQL(undef,"INSERT INTO portfolio_stocks
				VALUES ($symbol, $time, $$quotes{$symbol,\"open\"}, $$quotes{$symbol,\"high\"}, 
				$$quotes{$symbol,\"low\"}, $$quotes{$symbol,\"close\"}, $$quotes{$symbol,\"volume\"});");
			}
			# foreach $key (@info) {
			#     if (defined($quotes{$symbol,$key})) {
			# 	print $key,"\t",$quotes{$symbol,$key},"\n";
			#     }
			# }
	    }
	    print "\n";
	}
}