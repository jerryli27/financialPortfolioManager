#!/usr/bin/perl -w

use strict;

use CGI qw(:standard);
use CGI::Carp qw(fatalsToBrowser);

print header,
	start_html('hello world'),
	h1('hello world'),
	end_html();
