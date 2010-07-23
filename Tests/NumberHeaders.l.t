#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 4;
use Pipe2;

my ( $input, $output, $expected );
my $cmd = "../Scripts/NumberHeaders.pl";

#
# test 0
#

$input = '<html><body>
<h1> Foo </h1>
<h2> Bar </h2>
</body></html>';

$expected = '<html><body>
<h1> Foo </h1>
<h2> Bar </h2>
</body></html>';

$output = Pipe2::pipe2( $cmd, $input );
is( $output, $expected, "dummy" );

#
# test 1
#

$input = '<html><body>
<h1> Introduction </h1>

<!-- :: EXCERPT SEPARATOR :: -->

<h1> Foo </h1>
<h2> Bar1 </h2>
<h3> Sub10 </h3>
<h2> Bar2 </h2>

<h1> Foo </h1>
<h2> Bar1 </h2>
<h2> Bar2 </h2>
</body></html>';

$expected = '<html><body>
<h1> Introduction </h1>

<!-- :: EXCERPT SEPARATOR :: -->

<h1>I.  Foo </h1>
<h2>I.a.  Bar1 </h2>
<h3>I.a.i.  Sub10 </h3>
<h2>I.b.  Bar2 </h2>

<h1>II.  Foo </h1>
<h2>II.a.  Bar1 </h2>
<h2>II.b.  Bar2 </h2>
</body></html>';

$output = Pipe2::pipe2( $cmd, $input );
is( $output, $expected, "documentation example" );

#
# test 2
#

$input = '<html><body>
:: EXCERPT SEPARATOR ::
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
:: EXCERPT SEPARATOR ::
<h1>I. First Title</h1>
<h2>I.a. subtitle A</h2>
<p>toto tata titi</p>

<h1>II. Second Title</h1>
<h2>II.a. subtitle A</h2>
<p>hello</p>
<h2>II.b. subtitle B</h2>
<p>world</p>


<h1>III. Third Title</h1>
<h2>III.a. subtitle A</h2>
<p>toto</p>
<h2>III.b. subtitle B</h2>
<p>tata</p>
<h2>III.c. subtitle C</h2>
<p>titi</p>
</body></html>';

$output = Pipe2::pipe2( $cmd, $input );
is( $output, $expected, "old one" );

#
# test 3
#

$input = '<html><body>
<h1> Grüße </h1>
:: EXCERPT SEPARATOR ::
<h2> Welt ¿? </h2>
</body></html>';

$expected = '<html><body>
<h1> Grüße </h1>
:: EXCERPT SEPARATOR ::
<h2>I.a.  Welt ¿? </h2>
</body></html>';

$output = Pipe2::pipe2( $cmd, $input );
is( $output, $expected, "unicode" );
