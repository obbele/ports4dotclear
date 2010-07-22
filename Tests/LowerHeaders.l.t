#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 3;
use Pipe2;

my ($input, $output, $expected);
my $cmd = "../Scripts/LowerHeaders.pl";

#
# test 0
#

$input = '<html><body>
<h1> Foo </h1>
<h2> Bar </h2>
</body></html>';

$expected = '<html><body>
<h3> Foo </h3>
<h4> Bar </h4>
</body></html>';

$output = Pipe2::pipe2( $cmd, $input);
is( $output, $expected, "documentation example");

#
# test 1
#

$input = '<html><body>
<h1>First Title</h1>
<h2>subtitle A</h2>
<p>toto tata titi</p>

<h1>Second Title</h1>
<h2>subtitle A</h2>
<p>hello</p>
<h2>subtitle B</h2>
<p>world</p>


<h1>Third Title</h1>
<h2>subtitle A</h2>
<p>toto</p>
<h2>subtitle B</h2>
<p>tata</p>
<h2>subtitle C</h2>
<p>titi</p>
</body></html>';

$expected = '<html><body>
<h3>First Title</h3>
<h4>subtitle A</h4>
<p>toto tata titi</p>

<h3>Second Title</h3>
<h4>subtitle A</h4>
<p>hello</p>
<h4>subtitle B</h4>
<p>world</p>


<h3>Third Title</h3>
<h4>subtitle A</h4>
<p>toto</p>
<h4>subtitle B</h4>
<p>tata</p>
<h4>subtitle C</h4>
<p>titi</p>
</body></html>';

$output = Pipe2::pipe2( $cmd, $input);
is( $output, $expected, "old one");

#
# unicode
#

$input = '<html><body>
<h1> Testing¶ </h1>
<h2> Unicode™ </h2>
</body></html>';

$expected = '<html><body>
<h3> Testing¶ </h3>
<h4> Unicode™ </h4>
</body></html>';

$output = Pipe2::pipe2( $cmd, $input);
is( $output, $expected, "unicode");
