#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 1;
use Pipe2;

my ($input, $output, $expected);
my $cmd = "../Scripts/RewriteURLs.pl";

#
# test 0
#

$input = '<html><body>
<img src=\'Media/foobar.jpg\'/>
</body></html>';

$expected = '<html><body>
<img src=\'/blog/public/foobar.jpg\' />
</body></html>';

$output = Pipe2::pipe2( "$cmd Media/foobar.jpg /blog/public/foobar.jpg"
	                  , $input);
is( $output, $expected, "documentation example");
