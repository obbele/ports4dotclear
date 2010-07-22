#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 3;
use Pipe2;

my ($input, $output, $expected);
my $cmd = "../Scripts/Externalize.pl";

#
# tr
#

$input = '<html><body>
<pre extern="tr a-z A-Z">
	Hello World !
</pre>
</body></html>';

$expected = '<html><body>
<pre>HELLO WORLD !</pre>
</body></html>';

$output = Pipe2::pipe2( $cmd, $input);
is( $output, $expected, "tr");

#
# Sort
#

$input = '<html><body>
<div id="foobar" extern="sort">
	1
	3
	9
	8
	2
</div>
</body></html>';

$expected = '<html><body>
<div id=\'foobar\'>1
	2
	3
	8
	9
</div>
</body></html>';

$output = Pipe2::pipe2( $cmd, $input);
is( $output, $expected, "sort");

#
# Unicode
#

$input = '<html><body>
<div id="foobar" extern="cat">
	Grüße Welt !®™©
</div>
</body></html>';

$expected = '<html><body>
<div id=\'foobar\'>Grüße Welt !®™©</div>
</body></html>';

$output = Pipe2::pipe2( $cmd, $input);
is( $output, $expected, "unicode");
