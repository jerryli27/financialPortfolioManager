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
# execsql in stock_data_access seems to give lots of error message though..
use stock_data_access;

#
# oracle sqlplus credential
# 
my $dbuser="yfo776";
my $dbpasswd="zv0XOar1o";


# Headers copied from stock_data_access.pm

#
# Insert the historical data of a stock symbol into database
# Default is get the data for last year.
# You can also enter date/time.
sub insertStockHist {
	my ($symbol,$to,$from) = @_;
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

	foreach $row ($q->quotes()) {
	  # my @out;

	  ($qsymbol, $qdate, $qopen, $qhigh, $qlow, $qclose, $qvolume) = @{$row};
	  $qdate=parsedate($qdate);
	  my $sql="INSERT INTO portfolio_stocks
				VALUES (\'$qsymbol\', $qdate, $qopen, $qhigh, $qlow, $qclose, $qvolume)";
	  ExecSQL($dbuser, $dbpasswd,$sql,undef);
	}
}
#
# Insert the historical data of all known stock symbol into database
# Default is get the data for last year.
# You can also enter date/time.
sub getAllStocksHist{
	# Get a list of all the symbols of stocks, their start date, and their end date involved in our transactions.
	my @symbols = ExecSQL($dbuser, $dbpasswd,"SELECT symbol,max(timestamp) FROM portfolio_allStocks GROUP BY symbol",undef);
	# Get current time
	my $to = parsedate($to);
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
	my @symbols = ExecSQL($dbuser, $dbpasswd,"SELECT DISTINCT symbol FROM portfolio_allStocks",undef);

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
	  			ExecSQL($dbuser, $dbpasswd,"INSERT INTO portfolio_stocks
				VALUES ($symbol, $time, $$quotes{$symbol,\"open\"}, $$quotes{$symbol,\"high\"}, 
				$$quotes{$symbol,\"low\"}, $$quotes{$symbol,\"close\"}, $$quotes{$symbol,\"volume\"});",undef);
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


#
# Given a list of scalars, or a list of references to lists, generates
# an html table
#
#
# $type = undef || 2D => @list is list of references to row lists
# $type = ROW   => @list is a row
# $type = COL   => @list is a column
#
# $headerlistref points to a list of header columns
#
#
# $html = MakeTable($id, $type, $headerlistref,@list);
#
sub MakeTable {
  my ($id,$type,$headerlistref,@list)=@_;
  my $out;
  #
  # Check to see if there is anything to output
  #
  if ((defined $headerlistref) || ($#list>=0)) {
    # if there is, begin a table
    #
    $out="<table id=\"$id\" border>";
    #
    # if there is a header list, then output it in bold
    #
    if (defined $headerlistref) { 
      $out.="<tr>".join("",(map {"<td><b>$_</b></td>"} @{$headerlistref}))."</tr>";
    }
    #
    # If it's a single row, just output it in an obvious way
    #
    if ($type eq "ROW") { 
      #
      # map {code} @list means "apply this code to every member of the list
      # and return the modified list.  $_ is the current list member
      #
      $out.="<tr>".(map {defined($_) ? "<td>$_</td>" : "<td>(null)</td>" } @list)."</tr>";
    } elsif ($type eq "COL") { 
      #
      # ditto for a single column
      #
      $out.=join("",map {defined($_) ? "<tr><td>$_</td></tr>" : "<tr><td>(null)</td></tr>"} @list);
    } else { 
      #
      # For a 2D table, it's a bit more complicated...
      #
      $out.= join("",map {"<tr>$_</tr>"} (map {join("",map {defined($_) ? "<td>$_</td>" : "<td>(null)</td>"} @{$_})} @list));
    }
    $out.="</table>";
  } else {
    # if no header row or list, then just say none.
    $out.="(none)";
  }
  return $out;
}


#
# Given a list of scalars, or a list of references to lists, generates
# an HTML <pre> section, one line per row, columns are tab-deliminted
#
#
# $type = undef || 2D => @list is list of references to row lists
# $type = ROW   => @list is a row
# $type = COL   => @list is a column
#
#
# $html = MakeRaw($id, $type, @list);
#
sub MakeRaw {
  my ($id, $type,@list)=@_;
  my $out;
  #
  # Check to see if there is anything to output
  #
  $out="<pre id=\"$id\">\n";
  #
  # If it's a single row, just output it in an obvious way
  #
  if ($type eq "ROW") { 
    #
    #
    $out.=join("\n",map { defined($_) ? $_ : "(null)" } @list);
    $out.="\n";
  } else {
    #
    # For a 2D table
    #
    foreach my $r (@list) { 
      $out.= join("\t", map { defined($_) ? $_ : "(null)" } @{$r});
      $out.="\n";
    }
  }
  $out.="</pre>\n";
  return $out;
}
# @list=ExecSQL($user, $password, $querystring, $type, @fill);
#
# Executes a SQL statement.  If $type is "ROW", returns first row in list
# if $type is "COL" returns first column.  Otherwise, returns
# the whole result table as a list of references to row lists.
# @fill are the fillers for positional parameters in $querystring
#
# ExecSQL executes "die" on failure.
#
sub ExecSQL {
  my ($user, $passwd, $querystring, $type, @fill) =@_;
  if ($debug) { 
    # if we are recording inputs, just push the query string and fill list onto the 
    # global sqlinput list
    push @sqlinput, "$querystring (".join(",",map {"'$_'"} @fill).")";
  }
  my $dbh = DBI->connect("DBI:Oracle:",$user,$passwd);
  if (not $dbh) { 
    # if the connect failed, record the reason to the sqloutput list (if set)
    # and then die.
    if ($debug) { 
      push @sqloutput, "<b>ERROR: Can't connect to the database because of ".$DBI::errstr."</b>";
    }
    die "Can't connect to database because of ".$DBI::errstr;
  }
  my $sth = $dbh->prepare($querystring);
  if (not $sth) { 
    #
    # If prepare failed, then record reason to sqloutput and then die
    #
    if ($debug) { 
      push @sqloutput, "<b>ERROR: Can't prepare '$querystring' because of ".$DBI::errstr."</b>";
    }
    my $errstr="Can't prepare $querystring because of ".$DBI::errstr;
    $dbh->disconnect();
    die $errstr;
  }
  if (not $sth->execute(@fill)) { 
    #
    # if exec failed, record to sqlout and die.
    if ($debug) { 
      push @sqloutput, "<b>ERROR: Can't execute '$querystring' with fill (".join(",",map {"'$_'"} @fill).") because of ".$DBI::errstr."</b>";
    }
    my $errstr="Can't execute $querystring with fill (".join(",",map {"'$_'"} @fill).") because of ".$DBI::errstr;
    $dbh->disconnect();
    die $errstr;
  }
  #
  # The rest assumes that the data will be forthcoming.
  #
  #
  my @data;
  if (defined $type and $type eq "ROW") { 
    @data=$sth->fetchrow_array();
    $sth->finish();
    if ($debug) {push @sqloutput, MakeTable("debug_sqloutput","ROW",undef,@data);}
    $dbh->disconnect();
    return @data;
  }
  my @ret;
  while (@data=$sth->fetchrow_array()) {
    push @ret, [@data];
  }
  if (defined $type and $type eq "COL") { 
    @data = map {$_->[0]} @ret;
    $sth->finish();
    if ($debug) {push @sqloutput, MakeTable("debug_sqloutput","COL",undef,@data);}
    $dbh->disconnect();
    return @data;
  }
  $sth->finish();
  if ($debug) {push @sqloutput, MakeTable("debug_sql_output","2D",undef,@ret);}
  $dbh->disconnect();
  return @ret;
}