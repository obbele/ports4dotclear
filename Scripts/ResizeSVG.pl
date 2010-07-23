#!/usr/bin/perl

=pod

=head1 NAME

ResizeSVG.pl - Put a C<viewBox> declaration inside SVG headers

=head1 DESCRIPTION

ResizeSVG.pl is a basic XML SAX filter. Given a properly formatted SVG
documents, it add a C<viewBox> attribute to its root C<<svg>> element
and redefine its C<width> and C<height> attribute to C<100%>.

This way, SVG object can be displayed and scaled easily from an XHTML
document.

=head1 USAGE

ResizeSVG.pl reads its input from stdin and outputs the result to
stdout. You should use it this way:

	./ResizeSVG.pl <doc.xhtml >result.xhtml

=head1 EXAMPLES

The initial root element of the SVG document

	<svg
		...
		width="275"
		height="308"
		...

would become:

	<svg
		...
		width="100%"
		height="100%"
		viewBox="0 0 275 308"
		...

=cut

use strict;
use warnings;

use Encode;
use XML::SAX;
use XML::SAX::Writer;

sub resize_svg {
    my ($text) = @_;
    my $result = "";

    my $writer = XML::SAX::Writer->new( Output => \$result, );
    my $filter = SAX_ResizeSVG->new( Handler => $writer );
    my $parser = XML::SAX::ParserFactory->parser( Handler => $filter );

    $parser->parse_string($text);

    return $result;
}

### Main
my $text;
{
    local $/;
    $text = <>;

    print '<?xml version="1.0" encoding="UTF-8" standalone="no"?>' . "\n";
    print resize_svg($text);
}

##########################################################################
### Anonymous inline package: SAX2 filter
##########################################################################
package SAX_ResizeSVG;
use strict;
use base qw(XML::SAX::Base);
use Data::Dumper;

sub new {
    my $class   = shift;
    my %options = @_;

    return bless \%options, $class;
}

sub start_element {
    my ( $self, $data ) = @_;

    if ( $data->{Name} eq "svg" ) {
        my $w = $data->{Attributes}->{"{}width"}->{Value};
        my $h = $data->{Attributes}->{"{}height"}->{Value};
        $data->{Attributes}->{'{}viewBox'} = {
            Name      => "viewBox",
            LocalName => "viewBox",
            Value     => "0 0 $w $h",
        };

        $data->{Attributes}->{"{}width"}->{Value}  = "100%";
        $data->{Attributes}->{"{}height"}->{Value} = "100%";
    }

    # print opening tag <name>
    $self->SUPER::start_element($data);
}
