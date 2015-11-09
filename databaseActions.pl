#!/usr/bin/perl -w

#
#
# databaseActions.pl (Portfolio)
#
#
# Code for EECS 339, Northwestern University
# Contains all the database actions code that does not require output to html.
# 
# Alan Fu, Jerry Li
#


#
# The combination of -w and use strict enforces various 
# rules that make the script more resilient and easier to run
# as a CGI script.
#
use strict;

# The CGI web generation stuff
# This helps make it easy to generate active HTML content
# from Perl
#
# We'll use the "standard" procedural interface to CGI
# instead of the OO default interface
use CGI qw(:standard);
# This helps printing fatal errors to the browser. 
use CGI::Carp qw(fatalsToBrowser);

# The interface to the database.  The interface is essentially
# the same no matter what the backend database is.  
#
# DBI is the standard database interface for Perl. Other
# examples of such programatic interfaces are ODBC (C/C++) and JDBC (Java).
#
#
# This will also load DBD::Oracle which is the driver for
# Oracle.
use DBI;

#
#
# A module that makes it easy to parse relatively freeform
# date strings into the unix epoch time (seconds since 1970)
#
use Time::ParseDate;
#
#
# A module to get current working directory.
#
use Cwd;
my $dir = getcwd;
#
# Debugging
#
# database input and output is paired into the two arrays noted
#
my $debug=0; # default - will be overriden by a form parameter or cookie
my @sqlinput=();
my @sqloutput=();

#
# oracle sqlplus credential
# 
my $dbuser="yfo776";
my $dbpasswd="zv0XOar1o";

# The session cookie will contain the user's name and password so that 
# he doesn't have to type it again and again. 
#
# "RWBSession"=>"user/password"
#
# BOTH ARE UNENCRYPTED AND THE SCRIPT IS ALLOWED TO BE RUN OVER HTTP
# THIS IS FOR ILLUSTRATION PURPOSES.  IN REALITY YOU WOULD ENCRYPT THE COOKIE
# AND CONSIDER SUPPORTING ONLY HTTPS
#
my $cookiename="RWBSession";
#
# And another cookie to preserve the debug state
#
my $debugcookiename="RWBDebug";

#
# Get the session input and debug cookies, if any
#
my $inputcookiecontent = cookie($cookiename);
my $inputdebugcookiecontent = cookie($debugcookiename);

#
# Will be filled in as we process the cookies and paramters
#
my $outputcookiecontent = undef;
my $outputdebugcookiecontent = undef;
my $deletecookie=0;
my $user = undef;
my $password = undef;
my $logincomplain=0;

#
# Get the user action and whether he just wants the form or wants us to
# run the form
#
my $action;
my $run;


if (defined(param("act"))) { 
  $action=param("act");
  if (defined(param("run"))) { 
    $run = param("run") == 1;
  } else {
    $run = 0;
  }
} else {
  $action="base";
  $run = 1;
}

# 
# Initialize section
# 
if (defined(param("debug"))) { 
  # parameter has priority over cookie
  if (param("debug") == 0) { 
    $debug = 0;
  } else {
    $debug = 1;
  }
}else {
  if (defined($inputdebugcookiecontent)) { 
    $debug = $inputdebugcookiecontent;
  } else {
    # debug default from script
  }
}

$outputdebugcookiecontent=$debug;

 
#
#
# Who is this?  Use the cookie or anonymous credentials
#
#
if (defined($inputcookiecontent)) { 
  # Has cookie, let's decode it
  ($user,$password) = split(/\//,$inputcookiecontent);
  $outputcookiecontent = $inputcookiecontent;
} else {
  # No cookie, treat as anonymous user
  ($user,$password) = ("anon","anonanon");
}


my @outputcookies;

#
# OK, so now we have user/password
# and we *may* have an output cookie.   If we have a cookie, we'll send it right 
# back to the user.
#
# We force the expiration date on the generated page to be immediate so
# that the browsers won't cache it.
#
if (defined($outputcookiecontent)) { 
  my $cookie=cookie(-name=>$cookiename,
		    -value=>$outputcookiecontent,
		    -expires=>($deletecookie ? '-1h' : '+1h'));
  push @outputcookies, $cookie;
} 
#
# We also send back a debug cookie
#
#
if (defined($outputdebugcookiecontent)) { 
  my $cookie=cookie(-name=>$debugcookiename,
		    -value=>$outputdebugcookiecontent);
  push @outputcookies, $cookie;
}

#
# Headers and cookies sent back to client
#
# The page immediately expires so that it will be refetched if the
# client ever needs to update it
#
print header(-expires=>'now', -cookie=>\@outputcookies);

# my @portfolioArray=getUserPortfolioList($user);
# my $portfolioSelectionModal=generatePortfolioSelectionModal(@portfolioArray);
# my $portfolioNum; # *******NOTE: I think we need to store which portfolio the user visited in the database (Just an index or the name of it). 
# # So when the user first entered, or when the user switch from one portfolio to another, update that.
# if (defined(param("portfolioNum"))) { 
#   $portfolioNum=param("portfolioNum");
# } else {
#   $portfolioNum=1;
# }
# # This is the line that appears at the top with switching portfolios, logout and stuff.
# my $userPortfolioLogoutLine=generateUserPortfolioLogoutLine($user,$portfolioNum,@portfolioArray);
# my $userPortfolioCash=getUserPortfolioCash($user,$portfolioArray[$portfolioNum]);


# The cash deposit and cash withdraw does not print html
# cashDeposit
#
# Change the amount of cash in database and inform the user.
#
if ($action eq "cashDeposit") { 
	my $currPortfolioName=param("currPortfolioName");
	my $cashDepositAmount=param("cashDepositAmount");
	if ($cashDepositAmount<=0){
		print "Cash deposit amount must be positive.";
	}else{
		ExecSQL($dbuser, $dbpasswd, "update portfolio_portfolio set cash=cash+$cashDepositAmount where user_name='$user' and portfolio_name='$currPortfolioName'",undef);
		print "\$$cashDepositAmount has been added to your account in $currPortfolioName of user $user.";
	}
	exit 0;
}
# cashWithdraw
#
# Change the amount of cash in database and inform the user.
#
if ($action eq "cashWithdraw") { 
	my $currPortfolioName=param("currPortfolioName");
	my $cashWithdrawAmount=param("cashWithdrawAmount");
	if ($cashWithdrawAmount<=0){
		print "Cash withdraw amount must be positive.";
	}else{
		ExecSQL($dbuser, $dbpasswd, "update portfolio_portfolio set cash=cash-$cashWithdrawAmount where user_name='$user' and portfolio_name='$currPortfolioName'",undef);
		print "\$$cashWithdrawAmount has been deducted from your account in $currPortfolioName of user $user.";
	}
	exit 0;
}
# newTranaction
#
# Insert a new transaction.
#
if ($action eq "newTranaction") { 
	my $currPortfolioName=param("currPortfolioName");
	my $symbol=param("symbol");
	my $price=param("price");
	my $amount=param("amount");
	my $timestamp=param("timestamp");
	my $method=param("method");
	# Commenting out error checking for now. 
	# Also Error checking should not happen at this stage, because it is hard to return things in this subroutine,
	# if ($cashWithdrawAmount<=0){
	# 	print "Cash withdraw amount must be positive.";
	# }
	# else{
		# transaction_id,portfolio_name,user_name,symbol,price,timestamp,method,amount
		ExecSQL($dbuser, $dbpasswd, "insert into portfolio_transactions 
			values(seq_transaction_id.nextval,'$currPortfolioName','$user','$symbol',$price,$timestamp,'$method',$amount)",undef);
		print "Transaction has been inserted to portfolio $currPortfolioName of user $user.";
	# }
	exit 0;
}

if  ($action eq "automaticStockTrade") {

  # Can't pass parameters by argv because it is not command line
  my $symbol; my $initialcash; my $tradecost;
  if (defined(param("symbol"))) { 
    $symbol=param("symbol"); 
  } else{
    die "did not define symbol\n";
  }
  if (defined(param("initialcash"))) { 
    $initialcash=param("initialcash"); 
  } else{
    die "did not define initialcash\n";
  }
  if (defined(param("tradecost"))) { 
    $tradecost=param("tradecost"); 
  } else{
    die "did not define symbol tradecost\n";
  }

  my $lastcash=$initialcash;
  my $laststock=0;
  my $lasttotal=$lastcash;
  my $lasttotalaftertradecost=$lasttotal;

  # I need to add ../ because the file thinks we're in databaseActions.pl instead of its parent folder.
  open(STOCK, "$dir/get_data.pl --close $symbol |")
    or die "cannot open $dir/get_data.pl --close $symbol |: $!";



  my $cash=0;
  my $stock=0;
  my $total=0;
  my $totalaftertradecost=0;

  my $day=0;



  while (<STOCK>) { 
    chomp;
    my @data=split;
    my $stockprice=$data[1];

    my $currenttotal=$lastcash+$laststock*$stockprice;
    if ($currenttotal<=0) {
      exit;
    }
    
    my $fractioncash=$lastcash/$currenttotal;
    my $fractionstock=($laststock*$stockprice)/$currenttotal;
    my $thistradecost=0;
    my $redistcash;
    if ($fractioncash >= 0.5 ) {
      $redistcash=($fractioncash-0.5)*$currenttotal;
      if ($redistcash>0) {
        $cash=$lastcash-$redistcash;
        $stock=$laststock+$redistcash/$stockprice;
        $thistradecost=$tradecost;
      } else {
        $cash=$lastcash;
        $stock=$laststock;
      } 
    }  else {
      $redistcash=($fractionstock-0.5)*$currenttotal;
      if ($redistcash>0) {
        $cash=$lastcash+$redistcash;
        $stock=$laststock-$redistcash/$stockprice;
        $thistradecost=$tradecost;
      }
    }
    
    $total=$cash+$stock*$stockprice;
    $totalaftertradecost=($lasttotalaftertradecost-$lasttotal) - $thistradecost + $total; 
    $lastcash=$cash;
    $laststock=$stock;
    $lasttotal=$total;
    $lasttotalaftertradecost=$totalaftertradecost;

    $day++;
    

  #  print STDERR "$day\t$stockprice\t$cash\t".($stock*$stockprice)."\t$stock\t$total\t$totalaftertradecost\n";
  }

  close(STOCK);

  my $roi = 100.0*($lasttotal-$initialcash)/$initialcash;
  my $roi_annual = $roi/($day/365.0);

  my $roi_at = 100.0*($lasttotalaftertradecost-$initialcash)/$initialcash;
  my $roi_at_annual = $roi_at/($day/365.0);


  #print "$symbol\t$day\t$roi\t$roi_annual\n";

      
  print "Invested:                        \t$initialcash\n";
  print "Days:                            \t$day\n";
  print "Total:                           \t$lasttotal (ROI=$roi % ROI-annual = $roi_annual %)\n";
  print "Total-after \$$tradecost/day trade costs: \t$lasttotalaftertradecost (ROI=$roi_at % ROI-annual = $roi_at_annual %)\n";
    
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


######################################################################
#
# Nothing important after this
#
######################################################################

# The following is necessary so that DBD::Oracle can
# find its butt
#
BEGIN {
  unless ($ENV{BEGIN_BLOCK}) {
    use Cwd;
    $ENV{ORACLE_BASE}="/raid/oracle11g/app/oracle/product/11.2.0.1.0";
    $ENV{ORACLE_HOME}=$ENV{ORACLE_BASE}."/db_1";
    $ENV{ORACLE_SID}="CS339";
    $ENV{LD_LIBRARY_PATH}=$ENV{ORACLE_HOME}."/lib";
    $ENV{BEGIN_BLOCK} = 1;
    exec 'env',cwd().'/'.$0,@ARGV;
  }
}
