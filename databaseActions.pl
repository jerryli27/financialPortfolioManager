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

my @portfolioArray=getUserPortfolioList($user);
my $portfolioSelectionModal=generatePortfolioSelectionModal(@portfolioArray);
my $portfolioNum; # *******NOTE: I think we need to store which portfolio the user visited in the database (Just an index or the name of it). 
# So when the user first entered, or when the user switch from one portfolio to another, update that.
if (defined(param("portfolioNum"))) { 
  $portfolioNum=param("portfolioNum");
} else {
  $portfolioNum=1;
}
# This is the line that appears at the top with switching portfolios, logout and stuff.
my $userPortfolioLogoutLine=generateUserPortfolioLogoutLine($user,$portfolioNum,@portfolioArray);
my $userPortfolioCash=getUserPortfolioCash($user,$portfolioArray[$portfolioNum]);


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
	my $user=param("user");
	my $symbol=param("symbol");
	my $price=param("price");
	my $amount=param("amount");
	my $timestamp=param("timestamp");
	my $method=param("method");
	if ($cashWithdrawAmount<=0){
		print "Cash withdraw amount must be positive.";
	}else{
		# transaction_id,portfolio_name,user_name,symbol,price,timestamp,method,amount
		ExecSQL($dbuser, $dbpasswd, "insert into portfolio_transactions 
			values(seq_transaction_id.nextval,'$currPortfolioName','$user','$symbol','$price','$timestamp','$method','$amount')",undef);
		print "Transaction has been inserted to portfolio $currPortfolioName of user $user.";
	}
	exit 0;
}
