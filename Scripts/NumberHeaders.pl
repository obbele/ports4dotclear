#!/usr/bin/perl

=pod

=head1 NAME

NumberHeaders.pl - Add numbering to HTML headers

=head1 DESCRIPTION

Add numbering to HTML headers ( C<I.a>, C<I.b>, C<II.a>, C<II.b>, etc.).
To cope with the template used in XML-RPC/dotclear.py, skip any headers
before the C<:: EXCERPT SEPARATOR ::>.

=head1 USAGE

NumberHeaders.pl reads its input from stdin and outputs the result to
stdout. You should use it this way:

	./NumberHeaders.pl <doc.xhtml >result.xhtml

=head1 EXAMPLE

	<h1> Introduction </h1>

	<!-- :: EXCERPT SEPARATOR :: -->

	<h1> Foo </h1>
	<h2> Bar1 </h2>
	<h3> Sub10 </h3>
	<h2> Bar2 </h2>

	<h1> Foo </h1>
	<h2> Bar1 </h2>
	<h2> Bar2 </h2>

would become:

	<h1> Introduction </h1>

	<!-- :: EXCERPT SEPARATOR :: -->

	<h1>I.  Foo </h1>
	<h2>I.a.  Bar1 </h2>
	<h3>I.a.i.  Sub10 </h3>
	<h2>I.b.  Bar2 </h2>

	<h1>II.  Foo </h1>
	<h2>II.a.  Bar1 </h2>
	<h2>II.b.  Bar2 </h2>

=cut

use strict;
use warnings;

sub EnumerateHeaders($)
{
	my $text = shift;
	my @lines = split (/\n/, $text);
	my @result;

	my @romans       = ( "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X" );
	my @uppers       = ( "A", "B", "C", "D", "E", "F", "G", "H", "I", "J" );
	my @lowers       = ( "a", "b", "c", "d", "e", "f", "g", "h", "i", "j" );
	my @romans_small = ( "i", "ii", "iii", "iv", "v", "vi", "vii", "viii", "ix", "x" );

	my %tags = (
		1 => \@romans,
		2 => \@lowers,
		3 => \@romans_small,
		4 => \@uppers,
	);
	my %indices = (
		1 => 0,
		2 => 0,
		3 => 0,
		4 => 0,
		5 => 0, # dummy value
	);
	my $depth = -1;

	for my $line (@lines) {
		if ($line =~ /EXCERPT SEPARATOR/) {
			$depth = 0;
		}
		if ($depth != -1 and $line =~ /^<h([0-9])>/) {
			my $new_depth = $1;

			if ($new_depth <= $depth) {
				for ($new_depth+1..5) { $indices{$_} = 0; }
				$indices{$new_depth}++;
			}

			my $num = "";
			if ($new_depth <= 3) {
				for (1..$new_depth) {
					$num .= "${$tags{$_}}[$indices{$_}].";
				}
			} else {
				$num .= "${$tags{$new_depth}}[$indices{$new_depth}].";
			}
			$line =~ s/^<h$new_depth>/<h$new_depth>$num /;

			$depth = $new_depth;
		}
		push @result, $line;
	}

	return join("\n",@result);
}

my $text;
local $/; # slurp all stdin
$text = <>;
print EnumerateHeaders($text);
