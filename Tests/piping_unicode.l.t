#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Encode qw/ encode decode /;
use Pipe2;

my $short_test_file = "unicode.xhtml";
my $long_test_file  = "long_unicode.xhtml";
my @filters         = (
    '../Scripts/DOCTYPE_SVGXHTML.pl', '../Scripts/DOCTYPE_XHTML.pl',
    '../Scripts/Externalize.pl',      '../Scripts/InlineSVG.pl',
    '../Scripts/LowerHeaders.pl',     '../Scripts/NumberHeaders.pl',
    '../Scripts/ResizeSVG.pl',        '../Scripts/RewriteURLs.pl a b',
);

my $number_of_tests = 2 * @filters;
plan tests => $number_of_tests;

my ( $cmd, $output, $expected );

#$expected = "«æ€¶ŧ←»®";
$expected = qr/\x{AB}\x{e6}\x{20AC}\x{B6}\x{167}\x{2190}\x{BB}\x{AE}/;

foreach $cmd (@filters) {
    $output = Pipe2::pipe2( "$cmd <$short_test_file", '' );
    like( $output, $expected, "piping short unicode text to $cmd" );

    $output = Pipe2::pipe2( "$cmd <$long_test_file", '' );
    like( $output, $expected, "piping long unicode text to $cmd" );
}
