#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 4;
use Pipe2;

my ($input, $output, $expected);
my ($src, $dst);
my $cmd = "../Scripts/RewriteURLs.pl";

#
# test 0
#

$src = "Media/foobar.jpg";
$dst = "/blog/public/foobar.jpg";

$input = "<html><body>
<img src='$src'/>
</body></html>";

$expected = "<html><body>
<img src='$dst' />
</body></html>";

$output = Pipe2::pipe2( "$cmd $src $dst", $input);
is( $output, $expected, "img src, documentation example");

#
# a href
#

$src = "Media/foobar.jpg";
$dst = "/blog/public/foobar.jpg";

$input = "<html><body>
<a href='$src'>foobar</a>
</body></html>";

$expected = "<html><body>
<a href='$dst'>foobar</a>
</body></html>";

$output = Pipe2::pipe2( "$cmd $src $dst", $input);
is( $output, $expected, "a href");

#
# test 0
#

$src = "Media/foobar.jpg";
$dst = "/blog/public/foobar.jpg";

$input = "<html><body>
<object data='$src'>
<p>Fallback content</p>
</object>
</body></html>";

$expected = "<html><body>
<object data='$dst'>
<p>Fallback content</p>
</object>
</body></html>";

$output = Pipe2::pipe2( "$cmd $src $dst", $input);
is( $output, $expected, "object data");

#
# Unicode
#

$src = "Média/œuvre_champêtre.jpg";
$dst = "/blog/public/œuvre_champêtre.jpg";

$input = "<html><body>
<object data='$src'/>
</body></html>";

$expected = "<html><body>
<object data='$dst' />
</body></html>";

$output = Pipe2::pipe2( "$cmd $src $dst", $input);
is( $output, $expected, "unicode");
