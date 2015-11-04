#!/usr/bin/perl -w

#
#
# test.pl (Portfolio)
#
#
# Test code for EECS 339, Northwestern University
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

#
# Is this a login request or attempt?
# Ignore cookies in this case.
#
if ($action eq "login") { 
  if ($run) { 
    #
    # Login attempt
    #
    # Ignore any input cookie.  Just validate user and
    # generate the right output cookie, if any.
    #
    ($user,$password) = (param('user'),param('password'));
    if (ValidUser($user,$password)) { 
      # if the user's info is OK, then give him a cookie
      # that contains his username and password 
      # the cookie will expire in one hour, forcing him to log in again
      # after one hour of inactivity.
      # Also, land him in the base query screen
      $outputcookiecontent=join("/",$user,$password);
      $action = "base";
      $run = 1;
    } else {
      # uh oh.  Bogus login attempt.  Make him try again.
      # don't give him a cookie
      $logincomplain=1;
      $action="login";
      $run = 0;
    }
  } else {
    #
    # Just a login screen request, but we should toss out any cookie
    # we were given
    #
    undef $inputcookiecontent;
    ($user,$password)=("anon","anonanon");
  }
} 

#
# If we are being asked to log out, then if 
# we have a cookie, we should delete it.
#
if ($action eq "logout") {
  $deletecookie=1;
  $action = "base";
  $user = "anon";
  $password = "anonanon";
  $run = 1;
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

#
# Now we finally begin generating back HTML
#
#

# style header for tab bar
my $cssStyleHeader="<style type=\"text/css\">

	<!-- tab bar styles -->
	#tabContainer {
	  padding: 25px 15px 0 15px;
	  background: #000000;
	}

	ul#topTab {
	  list-style-type: none;
	  width: 100%;
	  position: relative;
	  height: 27px;
	  font-size: 13px;
	  font-weight: bold;
	  margin: 0;
	  padding: 11px 0 0 0;
	}

	ul#topTab li {
	  display: block;
	  float: left;
	  margin: 0 0 0 4px;
	  height: 27px;
	}

	ul#topTab li.left {
	  margin: 0;
	}

	ul#topTab li a {
	  display: block;
	  float: left;
	  color: #fff;
	  background: #363636;
	  line-height: 27px;
	  text-decoration: none;
	  padding: 0 17px 0 18px;
	  height: 27px;
	}

	ul#topTab li a.right {
	  padding-right: 19px;
	}

	ul#topTab li a:hover {
	  background: #6C6C6C;
	}

	ul#topTab li a.active {
	  color: #2E4560;
	  background: #fff;
	}

	ul#topTab li a.active:hover {
	  color: #2E4560;
	  background: #fff;
	}
	<!-- end of tab bar styles -->

	<!-- table styles -->
	table {
	    width:100%;
	}
	table, th, td {
	    border: 1px solid black;
	    border-collapse: collapse;
	}
	th, td {
	    padding: 5px;
	    text-align: left;
	}
	table tr:nth-child(even) {
	    background-color: #eee;
	}
	table tr:nth-child(odd) {
	   background-color:#fff;
	}
	table th	{
	    background-color: black;
	    color: white;
	}
	<!-- end of table styles -->

	<!-- hyperlink styles -->
	a {
		font-size: 0.875em; /* 14px/16=0.875em */
	}
	<!-- end of hyperlink styles -->
	</style>";

my $tabBarBody="
	<body>
	    <div id=\"tabContainer\" class=\"nav nav-tabs\">
	        <ul id=\"topTab\">
	            <li class=\"active\"><a data-toggle=\"tab\" href=\"#overview\">Overview</a></li>
	            <li><a data-toggle=\"tab\" href=\"#statistics\" >Statistics</a></li>
	            <li><a data-toggle=\"tab\" href=\"#performances\" >Performances</a></li>
	            <li><a data-toggle=\"tab\" href=\"#transactions\" >Transactions</a></li>
	        </ul>" # Deleted the div and body here
	;

my $usernameLink="<a data-toggle=\"modal\" href=\"\#openPortfolioSelectionModal\">".$user."</a>";
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


# print the header of html
print header,start_html('Portfolio Management');

# LOGIN
#
# Login is a special case since we handled running the filled out form up above
# in the cookie-handling code.  So, here we only show the form if needed
# 
#
if ($action eq "login") { 
	print "<center>";
  if ($logincomplain) { 
    print "Login failed.  Try again.<p>"
  } 
  if ($logincomplain or !$run) { 
    print start_form(-name=>'Login'),
      h2('Login to Portfolio Management'),
	"Userame:",textfield(-name=>'user'),	p,
	  "Password:",password_field(-name=>'password'),p,
	    hidden(-name=>'act',default=>['login']),
	      hidden(-name=>'run',default=>['1']),
		submit,
		  end_form;
  }
  print "</center>";
}
# createNewPortfolio
#
# creates a new portfolio in the database. If the portfolio name is more than 64 characters, inform the user.
#
if ($action eq "createNewPortfolio") { 
	my $newPortfolioName=param("newPortfolioName");
	print "<head>
				<meta http-equiv=\"refresh\" content=\"3;url=test.pl\" />
			</head>";
	print "<center>";
	if (length($newPortfolioName)<=0){
		print "You need to enter a portfolio name. Redirecting back to overview in 3 seconds.";
	}elsif  (length($newPortfolioName)>64){
		print "The portfolio name has to be less than 64 characters. Redirecting back to overview in 3 seconds.";
	}else{
		ExecSQL($dbuser, $dbpasswd, "insert into portfolio_portfolio values('$newPortfolioName','$user',0)",undef);
		print "The portfolio $newPortfolioName has been created. Redirecting back to overview in 3 seconds.";
	}
	print "</center>";
}
# deleteCurrPortfolio
#
# delete the current portfolio. The current portfolio is determined by passing in the current portfolio name.
#
if ($action eq "deleteCurrPortfolio") { 
	my $currPortfolioName=param("currPortfolioName");
	print "<head>
				<meta http-equiv=\"refresh\" content=\"3;url=test.pl\" />
			</head>";
	print "<center>";
	if (length($currPortfolioName)<=0){
		print "Parameter passing error! You need to enter a portfolio name if you want to delete a portfolio. Redirecting back to overview in 3 seconds.";
	}elsif  (length($currPortfolioName)>64){
		print "Parameter passing error! The portfolio name has to be less than 64 characters if you want to delete a portfolio. Redirecting back to overview in 3 seconds.";
	}else{
		ExecSQL($dbuser, $dbpasswd, "delete from portfolio_portfolio where user_name='$user' and portfolio_name='$currPortfolioName'",undef);
		print "The portfolio $currPortfolioName has been deleted. Redirecting back to overview in 3 seconds.";
	}
	print "</center>";
}



if ($action eq "base") {
	
	if ($user eq "anon") { 
	print h2("Welcome to portfolio management. You are currently anonymous"),
		"<p>Please <a href=\"test.pl?act=register\">register</a></p>",
		"<p>or <a href=\"test.pl?act=login\">login</a></p>";
 	} else {
 		# print h2("You have logged in");
 		#
 		# the majority of printing should come here
 		#
 		#
 		#
		my $newTransactionModal=generateNewTransactionModal($user,$portfolioArray[$portfolioNum]);
 		my $sharedTopPartOfTabs="
			<br><span class=\"glyphicon glyphicon-arrow-down\" aria-hidden=\"true\"></span>
			<button type=\"button\" class=\"btn btn-default\"  name=\"deleteButton\" value=\"Delete\" onclick=\"DeleteClicked()\">
  				Delete
			</button>
			<span style=\"float:right;\"><a data-toggle=\"modal\" href=\"\#newTransactionModal\">Edit transactions</a>|<a href=\"\">Edit this portfolio</a>|
			<a href=\"test.pl?act=deleteCurrPortfolio&currPortfolioName=$portfolioArray[$portfolioNum]\" 
			onclick=\"return confirm('Are you sure? Deleting a portfolio cannot be undone.')\">Delete this portfolio</a></span>";#create a link aligned to the right on the same line
		my $cashDepositModal=generateCashDepositModal($user,$portfolioArray[$portfolioNum]);
		my $cashWithdrawModal=generateCashWithdrawModal($user,$portfolioArray[$portfolioNum]);
		my $sharedStringForCash="<p>\tCash - \$$userPortfolioCash <a data-toggle=\"modal\" href=\"\#cashDepositModal\">Deposit</a> 
		/ <a data-toggle=\"modal\" href=\"\#cashWithdrawModal\">Withdraw</a> $cashDepositModal $cashWithdrawModal";

 		print 
		"<link rel=\"stylesheet\" href=\"http://maxcdn.bootstrapcdn.com/bootstrap/3.3.5/css/bootstrap.min.css\">
	 	<script src=\"https://ajax.googleapis.com/ajax/libs/jquery/1.11.3/jquery.min.js\"></script>
		<script src=\"http://maxcdn.bootstrapcdn.com/bootstrap/3.3.5/js/bootstrap.min.js\"></script>
		<script src=\"//cdnjs.cloudflare.com/ajax/libs/moment.js/2.9.0/moment-with-locales.js\"></script>
		<script src=\"//cdn.rawgit.com/Eonasdan/bootstrap-datetimepicker/e8bddc60e73c1ec2475f827be36e1957af72e2ea/src/js/bootstrap-datetimepicker.js\"></script>",
		$cssStyleHeader,
		$userPortfolioLogoutLine, 
			# The span here makes the text aligned to the right while the rest of the file stays left aligned
		$portfolioSelectionModal, # html for modal(hidden unless click on username)
		$newTransactionModal, # modals cannot be put inside the tab contents. Otherwise it will get copied four times 
		$cashDepositModal, # and only the modal in the first tab will be called.
		$cashWithdrawModal,
		$tabBarBody,
		# The div of each individual tab
		"<div class=\"tab-content\">",
			# OVERVIEW
		    "<div id=\"overview\" class=\"tab-pane fade in active\">",
		    $sharedTopPartOfTabs,
		    "<form name=\"tableForm\" action=\"\" method=\"post\">",
			table({-width=>'100%', -border=>'0'},
		           #caption('When Should You Eat Your Vegetables?'),
		           Tr({-align=>'CENTER',-valign=>'TOP'},
		           [
		              th(['<input type="checkbox" name="checkAll" value=""/>', 'Symbol','Last price','Change',"Volume","Open","Close","High","Low"]),
		              td(['<input type="checkbox" name="checkboxGE" value=""/>','<a href=\"\">GE</a>',15.70,"0.24(1.55%)","4.1T", 26.94, 27.55, 27.91, 26.8]),
		              td(['<input type="checkbox" name="checkboxAPLL" value=""/>','<a href=\"\">APLL</a>',15.70,"0.24(1.55%)","4.1T", 26.94, 27.55, 27.91, 26.8]),
		              td(['<input type="checkbox" name="checkboxFB" value=""/>','<a href=\"\">FB</a>',15.70,"0.24(1.55%)","4.1T", 26.94, 27.55, 27.91, 26.8]),
		           ]
		           )
		        ),
			"</form>",
			$sharedStringForCash,
			"</div>",
			# STATISTICS
			"<div id=\"statistics\" class=\"tab-pane fade\">\n",
			$sharedTopPartOfTabs,
			"<form name=\"tableForm\" action=\"\" method=\"post\">",
			table({-width=>'100%', -border=>'0'},
		           #caption('When Should You Eat Your Vegetables?'),
		           Tr({-align=>'CENTER',-valign=>'TOP'},
		           [
		              th(['<input type="checkbox" name="checkAll" value=""/>', 'Symbol','Last price','Change',"Volume","Open","Close","High","Low"]),
		              td(['<input type="checkbox" name="checkboxGE" value=""/>','<a href=\"\">GE</a>',15.70,"0.24(1.55%)","4.1T", 26.94, 27.55, 27.91, 26.8]),
		              td(['<input type="checkbox" name="checkboxAPLL" value=""/>','<a href=\"\">APLL</a>',15.70,"0.24(1.55%)","4.1T", 26.94, 27.55, 27.91, 26.8]),
		              td(['<input type="checkbox" name="checkboxFB" value=""/>','<a href=\"\">FB</a>',15.70,"0.24(1.55%)","4.1T", 26.94, 27.55, 27.91, 26.8]),
		           ]
		           )
		        ),
			"</form>",
			$sharedStringForCash,
			"</div>",
			# PERFORMANCES
			"<div id=\"performances\" class=\"tab-pane fade\">\n",
			$sharedTopPartOfTabs,
			"<form name=\"tableForm\" action=\"\" method=\"post\">",
			table({-width=>'100%', -border=>'0'},
		           #caption('When Should You Eat Your Vegetables?'),
		           Tr({-align=>'CENTER',-valign=>'TOP'},
		           [
		              th(['<input type="checkbox" name="checkAll" value=""/>', 'Symbol','Last price','Change',"Volume","Open","Close","High","Low"]),
		              td(['<input type="checkbox" name="checkboxGE" value=""/>','<a href=\"\">GE</a>',15.70,"0.24(1.55%)","4.1T", 26.94, 27.55, 27.91, 26.8]),
		              td(['<input type="checkbox" name="checkboxAPLL" value=""/>','<a href=\"\">APLL</a>',15.70,"0.24(1.55%)","4.1T", 26.94, 27.55, 27.91, 26.8]),
		              td(['<input type="checkbox" name="checkboxFB" value=""/>','<a href=\"\">FB</a>',15.70,"0.24(1.55%)","4.1T", 26.94, 27.55, 27.91, 26.8]),
		           ]
		           )
		        ),
			"</form>",
			"<p>\tCash - <a href=\"\">Deposit</a> / <a href=\"\">Withdraw</a>",
			"</div>",
			# TRANSACTIONS
			"<div id=\"transactions\" class=\"tab-pane fade\">\n",
			$sharedTopPartOfTabs,
			generateTransactionsTable($user,$portfolioArray[$portfolioNum]),
			$sharedStringForCash,
			"</div>",
		"</div>", # the div for tab-content
		"</div>",# the div of the container.
		"</body>",
		#
		# The Javascript portion of our app
		#
	    "<script type=\"text/javascript\" src=\"test.js\"> </script>"
		;
 	}
} 	

if ($action eq "register") {
	print "<center>";
	if (!$run){
		$run = 1;
		print h2("Register for Portfolio Management"),
			start_form(-name=>'Register'),
			"Username: ", textfield(-name=>'user'), p,
		    "Password: ", textfield(-name=>'password'), p,
		    hidden(-name=>'run',-default=>['1']),
			hidden(-name=>'act',-default=>['register']),
			  submit,
			    end_form,
			      hr;
	} else {
		my $user=param('user');
		my $password=param('password');
		my $error;
		$error=UserAdd($user,$password);
		if ($error) { 
			print h3("Can't add user because: $error");
		} else {
			print h3("You have successfully registered");
		}
	}
	print "<p><a href=\"test.pl?act=login\">Login</a></p>";
	print "<p><a href=\"test.pl?act=base&run=1\">Return</a></p>";
	print "</center>";
} 	




print end_html();

#
#
# run sql to get the list of portfolio names
#
#
sub getUserPortfolioList{
	my ($user)=@_;
	# select the first column
	return ExecSQL($dbuser, $dbpasswd, "select portfolio_name from portfolio_portfolio where user_name=?","COL",$user);
}

#
#
# run sql to get the portfolio's cash amount.
#
#
sub getUserPortfolioCash{
	my ($user,$currPortfolioName)=@_;
	# select the first column
	my @ret=ExecSQL($dbuser, $dbpasswd, "select cash from portfolio_portfolio where portfolio_name=? and user_name=?","COL",$currPortfolioName,$user);
	return $ret[0];
}

#
#
# dynamically generate the portfolio selection modal based on portfolio names.
#
#
sub generatePortfolioSelectionModal {
	my (@portfolioArray)=@_;
	my $portfolioSelectionModal="<!-- Modal -->
	<div class=\"modal fade\" id=\"openPortfolioSelectionModal\" role=\"dialog\">
	<div class=\"modal-dialog\">

	  <!-- Modal content-->
	  <div class=\"modal-content\">
	    <div class=\"modal-header\">
	      <button type=\"button\" class=\"close\" data-dismiss=\"modal\">&times;</button>
	      <h4 class=\"modal-title\">".$user."\'s portfolios</h4>
	    </div>
	    <div class=\"modal-body\">";
	my $counter=0;
	foreach (@portfolioArray){
        $portfolioSelectionModal.="<p><a href=\"test.pl?portfolioNum=$counter\">".$_."</a></p>";
        $counter=$counter+1;
    }
	$portfolioSelectionModal.="
	    </div>
	    <div class=\"modal-footer\">
	    	<form role=\"form\" id=\"newPortfolioForm\">
				<label for=\"newPortfolioName\">Your New Portfolio's Name:</label>
				<input type=\"text\" class=\"form-control\" id=\"newPortfolioName\">
				<button type=\"button\" class=\"btn btn-default\" data-dismiss=\"modal\" id=\"newPortfolioSubmit\">Create New Portfolio</button>
	    	</form>
	    </div>
	  </div>
	</div>
	</div>";
	return $portfolioSelectionModal;
}
#
#
# dynamically generate the cash deposit modal based on username and portfolio names.
#
#
sub generateCashDepositModal{
	my ($user,$currPortfolioName)=@_;
	my $cashDepositModal="<!-- Modal -->
	<div class=\"modal fade\" id=\"cashDepositModal\" role=\"dialog\">
	<div class=\"modal-dialog\">

	  <!-- Modal content-->
	  <div class=\"modal-content\">
	    <div class=\"modal-header\">
	      <button type=\"button\" class=\"close\" data-dismiss=\"modal\">&times;</button>
	      <h4 class=\"modal-title\">Deposit cash to $user\'s $currPortfolioName portfolio.</h4>
	    </div>
	    <div class=\"modal-footer\">
	    	<form role=\"form\" id=\"cashDepositForm\">
				<label for=\"cashDepositAmount\">Amount you want to add to your account:</label>
				<input type=\"text\" class=\"form-control\" id=\"cashDepositAmount\">
				<button type=\"button\" class=\"btn btn-default\" data-dismiss=\"modal\" id=\"cashDepositSubmit\">Submit</button>
	    	</form>
	    </div>
	  </div>
	</div>
	</div>";
	return $cashDepositModal;
}
#
#
# dynamically generate the cash withdraw modal based on username and portfolio names.
#
#
sub generateCashWithdrawModal{
	my ($user,$currPortfolioName)=@_;
	my $cashWithdrawModal="<!-- Modal -->
	<div class=\"modal fade\" id=\"cashWithdrawModal\" role=\"dialog\">
	<div class=\"modal-dialog\">

	  <!-- Modal content-->
	  <div class=\"modal-content\">
	    <div class=\"modal-header\">
	      <button type=\"button\" class=\"close\" data-dismiss=\"modal\">&times;</button>
	      <h4 class=\"modal-title\">Withdraw cash from $user\'s $currPortfolioName portfolio.</h4>
	    </div>
	    <div class=\"modal-footer\">
	    	<form role=\"form\" id=\"cashWithdrawForm\">
				<label for=\"cashWithdrawAmount\">Amount you want to withdraw from your account:</label>
				<input type=\"text\" class=\"form-control\" id=\"cashWithdrawAmount\">
				<button type=\"button\" class=\"btn btn-default\" data-dismiss=\"modal\" id=\"cashWithdrawSubmit\">Submit</button>
	    	</form>
	    </div>
	  </div>
	</div>
	</div>";
	return $cashWithdrawModal;
}
#
#
# dynamically generate the cash withdraw modal based on username and portfolio names.
#
#
sub generateNewTransactionModal{
	my ($user,$currPortfolioName)=@_;
	# transaction_id(autogenerated),portfolio_name,user_name,symbol,price,timestamp,method,amount
	my $newTransactionModal="<!-- Modal -->
	<div class=\"modal fade\" id=\"newTransactionModal\" role=\"dialog\">
	<div class=\"modal-dialog\">
	  <!-- Modal content-->
	  <div class=\"modal-content\">
	    <div class=\"modal-header\">
	      <button type=\"button\" class=\"close\" data-dismiss=\"modal\">&times;</button>
	      <h4 class=\"modal-title\">Record a new transaction in $user\'s $currPortfolioName portfolio.</h4>
	    </div>
	    <div class=\"modal-body\">
	    	<form role=\"form\" id=\"cashWithdrawForm\">
	    		<div class=\"col-xs-2\">
					<label for=\"symbol\">Symbol:</label>
					<input type=\"text\" class=\"form-control\" id=\"symbol\">
				</div>
	    		<div class=\"col-xs-2\">
					<label for=\"price\">Price:</label>
					<input type=\"text\" class=\"form-control\" id=\"price\">
				</div>
	    		<div class=\"col-xs-2\">
					<label for=\"amount\">Amount:</label>
					<input type=\"text\" class=\"form-control\" id=\"amount\">
				</div>
				<div class='col-sm-5'>
		            <div class=\"form-group\">
						<label for=\"newTransactionDatetimeDiv\">Trade time:</label>
		                <div class='input-group date' id='newTransactionDatetimeDiv'>
		                    <input type='text' class=\"form-control\" data-format=\"MM/dd/yyyy HH:mm:ss PP\" id='newTransactionDatetimePicker'/>
		                    <span class=\"input-group-addon\">
		                        <span class=\"glyphicon glyphicon-calendar\"></span>
		                    </span>
		                </div>
		            </div>
		        </div>
		        <script type=\"text/javascript\">
		            \$(function () {
		                \$('#newTransactionDatetimeDiv').datetimepicker();
		            });
		        </script>
		        <br><br><br><br><!-- Added so many blank lines so that the buttons can start on a new line...-->
		        <span style=\"float:right;\">
	    		<label class=\"radio-inline\">
			      <input type=\"radio\" name=\"optradio\" checked=\"checked\" id=\"newTransactionBuy\">Buy
			    </label>
			    <label class=\"radio-inline\">
			      <input type=\"radio\" name=\"optradio\" id=\"newTransactionSell\">Sell
			    </label>
				<button type=\"button\" class=\"btn btn-default\" data-dismiss=\"modal\" id=\"newTransactionSubmit\">Submit</button>
				</span>
	    	</form>
	    </div>
	  </div>
	</div>
	</div>";
	return $newTransactionModal;
}

sub generateUserPortfolioLogoutLine{
	my ($user,$portfolioNum,@portfolioArray)=@_;
	my $ret;
	# If the portfolio array exists and portfolio index is legal.
	if (scalar(@portfolioArray)>$portfolioNum){
		return h4($usernameLink."|<a data-toggle=\"modal\" href=\"\#openPortfolioSelectionModal\" id=\"currPortfolioName\">".$portfolioArray[$portfolioNum].
			"</a><span style=\"float:right;\"><a href=\"test.pl?act=logout\">Log out</a></span>");
	}elsif (scalar(@portfolioArray)==0){
		# If the portfolio array does not exist.
		return h4($usernameLink."|<a data-toggle=\"modal\" href=\"\#openPortfolioSelectionModal\" id=\"currPortfolioName\">Please create a portfolio
			</a><span style=\"float:right;\"><a href=\"test.pl?act=logout\">Log out</a></span>");
	}else{
		# If the portfolio array is shorter than portfolio index
		return h4($usernameLink."|<a data-toggle=\"modal\" href=\"\#openPortfolioSelectionModal\" id=\"currPortfolioName\">".$portfolioArray[scalar(@portfolioArray)-1].
			"</a><span style=\"float:right;\"><a href=\"test.pl?act=logout\">Log out</a></span>");
	}
}

sub generateTransactionsTable{
	my ($user,$currPortfolioName)=@_;
	# The following does not work quite yet.
	# my $ref = [
 #              th(['<input type="checkbox" name="checkAll" value=""/>', 'Symbol','Type','Date',"Shares","Price","Cash Value","Commission"]),
 #              td(['<input type="checkbox" name="checkboxGE" value=""/>','<a href=\"\">GE</a>',"Buy","Oct 27, 2015","100", "22.6", "\$2260", "\$10.00",]),
 #           ];
	my $ret=
	"<form name=\"transactionsTableForm\" action=\"\" method=\"post\">",
	table({-width=>'100%', -border=>'0'},
           #caption('When Should You Eat Your Vegetables?'),
           Tr({-align=>'CENTER',-valign=>'TOP'},
           	[
              th(['<input type="checkbox" name="checkAll" value=""/>', 'Symbol','Type','Date',"Shares","Price","Cash Value","Commission"]),
              td(['<input type="checkbox" name="checkboxGE" value=""/>','<a href=\"\">GE</a>',"Buy","Oct 27, 2015","100", "22.6", "\$2260", "\$10.00",]),
           ]
           )
        ),
	"</form>";
	return $ret;
}

#
#
# Check to see if user and password combination exist
#
# $ok = ValidUser($user,$password)
#
#
sub ValidUser {
  my ($user,$password)=@_;
  my @col;
  eval {@col=ExecSQL($dbuser,$dbpasswd, "select count(*) from portfolio_users where user_name=? and password=?","COL",$user,$password);};
  if ($@) { 
    return 0;
  } else {
    return $col[0]>0;
  }
}




#
# Add a user
# call with email, password
#
# returns false on success, error string on failure.
# 
# UserAdd($email,$password)
#
sub UserAdd { 
  eval { ExecSQL($dbuser,$dbpasswd,
		 "insert into portfolio_users (user_name,password) values (?,?)",undef,@_);};
  return $@;
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
