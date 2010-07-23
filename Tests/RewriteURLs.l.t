#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 4;
use XML::Simple;
use Pipe2;

my ( $input, $xml, $got );
my ( $src, $dst );
my $cmd = "../Scripts/RewriteURLs.pl";

#
# test 0
#

$src = "Media/foobar.jpg";
$dst = "/blog/public/foobar.jpg";

$input = "<html><body>
<img src='$src'/>
</body></html>";

$xml = Pipe2::pipe2( "$cmd $src $dst", $input );
$got = XMLin($xml)->{body}->{img};
is( $got->{src}, $dst, "img src, documentation example" );

#
# a href
#

$src = "Media/foobar.jpg";
$dst = "/blog/public/foobar.jpg";

$input = "<html><body>
<a href='$src'>foobar</a>
</body></html>";

$xml = Pipe2::pipe2( "$cmd $src $dst", $input );
$got = XMLin($xml)->{body}->{a};
is( $got->{href}, $dst, "a href" );

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

$xml = Pipe2::pipe2( "$cmd $src $dst", $input );
$got = XMLin($xml)->{body}->{object};
is( $got->{data}, $dst, "object data" );

#
# Unicode
#

$src = "Média/œuvre_champêtre.jpg";
$dst = "/blog/public/œuvre_champêtre.jpg";

$input = "<html><body>
<object data='$src'/>
</body></html>";

$xml = Pipe2::pipe2( "$cmd $src $dst", $input );
$got = XMLin($xml)->{body}->{object};
is( $got->{data}, $dst, "unicode" );
