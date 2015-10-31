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

my $tabBarHeader="<style type=\"text/css\">
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

	ul#topTab li a.current {
	  color: #2E4560;
	  background: #fff;
	}

	ul#topTab li a.current:hover {
	  color: #2E4560;
	  background: #fff;
	}
	</style>";

my $tabBarBody="
	<body>
	    <div id=\"tabContainer\">
	        <ul id=\"topTab\">
	            <li><a href=\"http://murphy.wot.eecs.northwestern.edu/~jlt709/portfolio/test.pl?debug=0\" title=\"Overview\" class=\"current\">Overview</a></li>
	            <li><a href=\"http://murphy.wot.eecs.northwestern.edu/~jlt709/portfolio/test.pl?debug=1\" title=\"Overview\">Statistics</a></li>
	            <li><a href=\"http://murphy.wot.eecs.northwestern.edu/~jlt709/portfolio/test.pl?debug=1\" title=\"Overview\">Performances</a></li>
	            <li><a href=\"http://murphy.wot.eecs.northwestern.edu/~jlt709/portfolio/test.pl?debug=1\" title=\"Overview\">Transactions</a></li>
	        </ul>
	    </div>
	</body>";
my $usernameLink="<a href=\"\">username</a>"
my @array = ("One fish", "Two fish", "Red Fish", "Blue Fish");

print join("\n", @array), "\n";
my @portfolioArray;
$portfolioArray[0]="portfolio1";
$portfolioArray[1]="portfolio2";

print header,
	$tabBarHeader,
	start_html('hello world'),
	h1($usernameLink."|<a href=\"".$portfolioArray[0]."\">".$portfolioArray[0].
		"</a><span style=\"float:right;\"><a href=\"\">Log out</a></span>"), 
		# The span here makes the text aligned to the right while the rest of the file stays left aligned
	$tabBarBody,
	end_html();


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
