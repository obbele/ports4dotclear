#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 5;
use XML::Simple;
use Pipe2;

my ( $input, $xml, $got, $expected );
my $cmd = "../Scripts/Externalize.pl";

#
# tr
#

$input = '<html><body>
<pre extern="tr a-z A-Z">
	Hello World !
</pre>
</body></html>';
$expected = 'HELLO WORLD !';

$xml = Pipe2::pipe2( $cmd, $input );
$got = XMLin($xml)->{body}->{pre};
is( $got, $expected, "tr" );

#
# Sort
#

$input = '<?xml version=\'1.0\'?><html><body>
<div id="foobar" extern="sort">
	1
	3
	9
	8
	2
</div>
</body></html>';
$expected = '1
	2
	3
	8
	9
';

$xml = Pipe2::pipe2( $cmd, $input );
$got = XMLin($xml)->{body}->{div};

is( $got->{id},      "foobar",  "sort" );
is( $got->{content}, $expected, "sort" );

#
# Unicode
#

$input = '<?xml version=\'1.0\'?><html><body>
<div id="foobar" extern="cat">
	Grüße Welt !®™©
</div>
</body></html>';
$expected = 'Grüße Welt !®™©';

$got = Pipe2::pipe2( $cmd, $input );
$xml = Pipe2::pipe2( $cmd, $input );
$got = XMLin($xml)->{body}->{div};

is( $got->{id},      "foobar",  "unicode" );
is( $got->{content}, $expected, "unicode" );
