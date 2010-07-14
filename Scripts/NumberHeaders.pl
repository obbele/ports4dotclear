#!/usr/bin/perl

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
