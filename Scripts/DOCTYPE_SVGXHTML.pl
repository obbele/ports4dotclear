#!/usr/bin/perl

=pod

=head1 NAME

DOCTYPE_SVGXHTML.pl - Prepend text with XHTML DOCTYPE declaration

=head1 DESCRIPTION

DOCTYPE_SVGXHTML.pl fix the behavior of previous XML SAX filter which may
have stripped the document from its DOCTYPE declaration..

=head1 USAGE

DOCTYPE_SVGXHTML.pl reads its input from stdin and outputs the result to
stdout. You should use it this way:

	./DOCTYPE_SVGXHTML.pl <doc.xhtml >result.xhtml


=cut

use strict;
use warnings;
use Encode;

### Main
my $text;
{
    local $/;
    $text = <>;
    $text = decode( 'UTF-8', $text );

    my $doctype = '<?xml version="1.0" encoding="UTF-8"?>;
<!DOCTYPE html PUBLIC;
"-//W3C//DTD XHTML 1.1 plus MathML 2.0 plus SVG 1.1//EN";
"http://www.w3.org/2002/04/xhtml-math-svg/xhtml-math-svg.dtd">';
    $text =~ s{<\?xml.*<html}{$doctype\n<html};

    $text = encode( 'UTF-8', $text );
    print $text;
}
