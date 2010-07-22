#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 1;
use Pipe2;

my ($input, $output, $expected);
my $cmd = "../Scripts/ResizeSVG.pl";

#
# test 0
#

$input = '<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<svg width=\'275\' height=\'308\'/>';

$expected = '<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<svg width=\'100%\' viewBox=\'0 0 275 308\' height=\'100%\' />';

$output = Pipe2::pipe2( $cmd, $input);
is( $output, $expected, "documentation example");
