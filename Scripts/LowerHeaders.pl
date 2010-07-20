#!/usr/bin/perl

=pod

=head1 NAME

LowerHeaders.pl - Adjust Markdown headers to DotClear2 convention

=head1 DESCRIPTION

Markdown files are written with the convenient syntax where one
underlines titles with a bunch of "==========" or "-------". For
example:

	My Title
	========

		Blabla

	My subtitle
	-----------
		
		Blablabla


Unfortunately, this syntax is converted to C<<h1>> and C<<h2>> HTML
headers whereas DotClear2 posts expected to be order with titles
starting with the C<<h3>> and C<<h4>> tags.

This humble PERL script will so replace every HTML headers C<<hX>> by
C<<hX+2>>. C<<h1>> becoming C<<h3>>, C<<h2>> becoming C<<h4>>, etc.

=head1 USAGE

LowerHeaders.pl reads its input from stdin and outputs the result to
stdout. You should use it this way:

	./LowerHeaders.pl <doc.xhtml >result.xhtml

=head1 EXAMPLES

	<h1> Foo </h1>

	<h2> Bar </h2>

would become:

	<h3> Foo </h3>

	<h4> Bar </h4>

=cut

use strict;
use warnings;

sub DownHeaders($)
{
	my $text = shift;

	for (my $i = 4; $i > 0; $i--){
		my ($old, $new) = ($i,$i+2);

		$text =~ s{<h$old}{<h$new}g;
		$text =~ s{</h$old}{</h$new}g;
	}

	return $text;
}

my $text;
local $/; # slurp all stdin
$text = <>;
print DownHeaders($text);
