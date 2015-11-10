#!/usr/bin/perl -w

use Getopt::Long;
#
#
# A module to get current working directory.
#
use Cwd;
my $dir = getcwd;

$#ARGV>=2 or die "usage: time_series_symbol_project.pl symbol steps-ahead model \n";

$symbol=shift;
$steps=shift;
$model=join(" ",@ARGV);

system "$dir/get_data.pl --notime --close $symbol > _data.in";
system "$dir/time_series_project _data.in $steps $model 2>/dev/null";

