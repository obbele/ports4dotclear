#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 3;
use XML::Simple;
use Pipe2;

my ( $input, $xml, $got );
my $cmd = "../Scripts/ResizeSVG.pl";

#
# test 0
#

$input = '<svg width="275" height="308"/>';

$xml = Pipe2::pipe2( $cmd, $input );
$got = XMLin($xml);
is( $got->{width},   '100%',        "documentation example: width" );
is( $got->{height},  '100%',        "documentation example: height" );
is( $got->{viewBox}, '0 0 275 308', "documentation example: viewBox" );
