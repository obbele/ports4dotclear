#!/usr/bin/perl

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
