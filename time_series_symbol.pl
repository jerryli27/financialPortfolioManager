#!/usr/bin/perl -w

use Getopt::Long;
#
#
# A module to get current working directory.
#
use Cwd;
my $dir = getcwd;

$#ARGV>=2 or die "usage: time_series_symbol.pl symbol steps-ahead model \n";

$symbol=shift;
$steps=shift;
$model=join(" ",@ARGV);

$cmd = "$dir/get_data.pl --notime --close $symbol | ($dir/time_series_predictor_online $steps $model 2>/dev/null) | $dir/time_series_evaluator_online $steps";

system  $cmd;
