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
} 

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



my $usernameLink="<a href=\"\">username</a>";

my @portfolioArray=("portfolio1","portfolio2");



print header,
	"<link rel=\"stylesheet\" href=\"http://maxcdn.bootstrapcdn.com/bootstrap/3.3.5/css/bootstrap.min.css\">
 	<script src=\"https://ajax.googleapis.com/ajax/libs/jquery/1.11.3/jquery.min.js\"></script>
	<script src=\"http://maxcdn.bootstrapcdn.com/bootstrap/3.3.5/js/bootstrap.min.js\"></script>",
	$cssStyleHeader,
	start_html('Portfolio'),
	h3($usernameLink."|<a href=\"".$portfolioArray[0]."\">".$portfolioArray[0].
		"</a><span style=\"float:right;\"><a href=\"\">Log out</a></span>"), 
		# The span here makes the text aligned to the right while the rest of the file stays left aligned
	$tabBarBody,
	# The div of each individual tab

	"<div class=\"tab-content\">",
		# OVERVIEW
	    "<div id=\"overview\" class=\"tab-pane fade in active\">",
	    "<div>\t",
		button(-name=>'deleteButton',
			   -value=>'Delete',
			   -onClick=>"DeleteClicked()"),
		"</div>",
		"<span style=\"float:right;\"><a href=\"\">Edit transactions</a>|<a href=\"\">Edit portfolio</a>|<a href=\"\">Delete portfolio</a></span>", #create a link aligned to the right on the same line
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
		# STATISTICS
		"<div id=\"statistics\" class=\"tab-pane fade\">\n",
		button(-name=>'deleteButton',
			   -value=>'Delete',
			   -onClick=>"DeleteClicked()"),
		"<span style=\"float:right;\"><a href=\"\">Edit transactions</a>|<a href=\"\">Edit portfolio</a>|<a href=\"\">Delete portfolio</a></span>", #create a link aligned to the right on the same line
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
		# PERFORMANCES
		"<div id=\"performances\" class=\"tab-pane fade\">\n",
		"<div>\t",
		button(-name=>'deleteButton',
			   -value=>'Delete',
			   -onClick=>"DeleteClicked()"),
		"</div>",
		"<span style=\"float:right;\"><a href=\"\">Edit transactions</a>|<a href=\"\">Edit portfolio</a>|<a href=\"\">Delete portfolio</a></span>", #create a link aligned to the right on the same line
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
			"<div>\t",
			button(-name=>'deleteButton',
				   -value=>'Delete',
				   -onClick=>"DeleteClicked()"),
			"</div>",
		"<span style=\"float:right;\"><a href=\"\">Edit transactions</a>|<a href=\"\">Edit portfolio</a>|<a href=\"\">Delete portfolio</a></span>", #create a link aligned to the right on the same line
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
	"</div>", # the div for tab-content
	"</div>",# the div of the container.
	"</body>",
	#
	# The Javascript portion of our app
	#
    "<script type=\"text/javascript\" src=\"test.js\"> </script>",
	end_html();


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
