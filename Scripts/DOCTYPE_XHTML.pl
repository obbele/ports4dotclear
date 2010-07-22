#!/usr/bin/perl
=pod

=head1 NAME

DOCTYPE_XHTML.pl - Prepend text with XHTML DOCTYPE declaration

=head1 DESCRIPTION

DOCTYPE_XHTML.pl fix the behavior of previous XML SAX filter which may
have stripped the document from its DOCTYPE declaration..

=head1 USAGE

DOCTYPE_XHTML.pl reads its input from stdin and outputs the result to
stdout. You should use it this way:

	./DOCTYPE_XHTML.pl <doc.xhtml >result.xhtml


=cut

use strict;
use warnings;

use Encode;

### Main
my $text;
{
	local $/;
	$text = <>;
	$text = encode_utf8($text);

	print '<?xml version="1.0" encoding="UTF-8"?>'."\n";
	print '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"'."\n";
	print '"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">'."\n";

	print $text;
}
