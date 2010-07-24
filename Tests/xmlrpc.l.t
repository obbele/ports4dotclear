#!/usr/bin/perl

use strict;
use warnings;
use File::Temp qw/ tempfile /;
use Test::More tests => 21;
use Pipe2;

my ( $input, $output, $expected );
my $cmd = "../Scripts/XML-RPC/dotclear.py -ctest.cfg";
my $postid;
my $original_state;
my ( $xhtml, $temph, $tempname );

#$expected = "«æ€¶ŧ←»®";
my $utf8_msg = "«æ€¶ŧ←»®";
my $utf8_re  = qr/\x{AB}\x{e6}\x{20AC}\x{B6}\x{167}\x{2190}\x{BB}\x{AE}/;

# unset the $EDITOR environment variable to avoid launching vim with
# 'XML-RPC/dotclear.py'
$ENV{'EDITOR'} = undef;

#
# Backup original state;
#

$original_state = Pipe2::pipe2( "$cmd -l3", '' );

#
# Wrap
#

$input = "Hello World";
$output = Pipe2::pipe2( "$cmd --wrap", $input );
ok( $output =~ /$input/, 'wrap text' );

#
# Wrap unicode
#

$input = "«Grüße Welt !»";
$output = Pipe2::pipe2( "$cmd --wrap", $input );
ok( $output =~ /$input/, 'wrap unicode' );

#
# List
#

$output = system("$cmd --list=1 >/dev/null");
ok( $output == 0, 'list last messages' );

#
# Create new post
# Delete previously created post
# (replaced by the '<<<' method below)
#
# $output = Pipe2::pipe2("$cmd --new <new_post.input", '');
# ok( $output =~ /ID = (\d+)/, 'create new post');
# $postid = $1;
#
# $output = system("$cmd --delete=$postid >/dev/null");
# ok( $output == 0, "delete previous post with ID = $postid");

#
# Create new post with '<<<'
#

$input = 'My Title
tag0, tag1, tag2
This is a short introduction.
This is a short content.
n
n
n
0

';

$output = Pipe2::pipe2( "$cmd --new <<<'$input'", '' );
ok( $output =~ /ID = (\d+)/, "create new post" );
$postid = $1;

#
# (re-)extracting an old entry
#

$output = Pipe2::pipe2( "$cmd --extract=$postid", '' );
like( $output, qr/This is a short introduction/, "extract excerpt" );
like( $output, qr/This is a short content/,      "extract content" );

#
# showing an old entry
#

$output = Pipe2::pipe2( "$cmd --show=$postid", '' );
like( $output, qr/This is a short introduction/, "show excerpt" );
like( $output, qr/This is a short content/,      "show content" );

#
# Delete previously created post
#

$output = system("$cmd --delete=$1 >/dev/null");
ok( $output == 0, "delete previous post with ID = $postid" );

#
# Create new post with unicode
#

$input = "My Title
tag0, tag1, tag2
Grüße Welt!.
This is a short content with unicode $utf8_msg
n
n
n
0

";

$output = Pipe2::pipe2( "$cmd --new <<<'$input'", '' );
if ( $output =~ /ID = (\d+)/ ) {
    $postid = $1;

    $output = Pipe2::pipe2( "$cmd --extract=$postid", '' );
    like( $output, qr/Gr\x{FC}\x{DF}e Welt!/, "extract unicode excerpt" );
    like( $output, $utf8_re, "extract unicode content" );

    $output = Pipe2::pipe2( "$cmd --show=$postid", '' );
    like( $output, qr/Gr\x{FC}\x{DF}e Welt!/, "show unicode excerpt" );
    like( $output, $utf8_re, "show unicode content" );

    $output = system("$cmd --delete=$1 >/dev/null");
    ok( $output == 0, "handling unicode" );
}
else {
    fail("create posts with unicode");
}

#
# Create new post with raw / stdin input
#

$input = 'My Title
tag0, tag1, tag2
n
n
n
0

';

$xhtml = 'This is a short excerpt.
<!-- :::: EXCERPT SEPARATOR :::: -->
This is a short content.';

( $temph, $tempname ) = tempfile();
$xhtml = Pipe2::pipe2( "$cmd --wrap", $xhtml );
{
    local $/;
    print $temph $xhtml;
    close $temph;
}

$output = Pipe2::pipe2( "$cmd --raw=$tempname --new <<<'$input'", '' );
if ( $output =~ /ID = (\d+)/ ) {
    $postid = $1;

    $output = Pipe2::pipe2( "$cmd --extract=$postid", '' );
    like( $output, qr/a short excerpt/, "extract raw excerpt" );
    like( $output, qr/a short content/, "extract raw content" );

    $output = system("$cmd --delete=$1 >/dev/null");
    ok( $output == 0, "handling raw / stdin input" );
}
else {
    fail("create posts from raw files");
}

unlink $tempname;

#
# Create new post with raw / stdin input
#

$input = 'My Title
tag0, tag1, tag2
n
n
n
0

';

$xhtml = "Grüße Welt!.
<!-- :::: EXCERPT SEPARATOR :::: -->
This is a short content with unicode $utf8_msg";

( $temph, $tempname ) = tempfile();
$xhtml = Pipe2::pipe2( "$cmd --wrap", $xhtml );
{
    local $/;
    print $temph $xhtml;
    close $temph;
}

$output = Pipe2::pipe2( "$cmd --raw=$tempname --new <<<'$input'", '' );
if ( $output =~ /ID = (\d+)/ ) {
    $postid = $1;

    $output = Pipe2::pipe2( "$cmd --extract=$postid", '' );
    like( $output, qr/Gr\x{FC}\x{DF}e Welt/, "extract raw unicode excerpt" );
    like( $output, $utf8_re, "extract unicode raw content" );

    $output = system("$cmd --delete=$1 >/dev/null");
    ok( $output == 0, "handling raw / stdin input with unicode" );
}
else {
    fail("create posts raw files with unicode");
}

unlink $tempname;

#
# Check if none of the previous tests have permanently modified the
# original state of the blog;
#

$output = Pipe2::pipe2( "$cmd -l3", '' );
is( $output, $original_state, "original state restored" );

#done_testing;
