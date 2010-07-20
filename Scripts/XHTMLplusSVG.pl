#!/usr/bin/perl

=pod

=head1 NAME

XHTMLplusSVG.pl - Replace DOCTYPE declaration of XHTML documents

=head1 DESCRIPTION

XHTMLplusSVG.pl is WORKING. But no one finds it useful.

=head1 USAGE

XHTMLplusSVG.pl reads its input from stdin and outputs the result to
stdout. You should use it this way:

	./XHTMLplusSVG.pl <doc.xhtml >result.xhtml

=head1 EXAMPLES

The following XML extract:

	<?xml version="1.0" encoding="UTF-8"?>
	<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
		"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">

would become:

	<?xml version="1.0" encoding="UTF-8"?>
	<!DOCTYPE html PUBLIC
    	"-//W3C//DTD XHTML 1.1 plus MathML 2.0 plus SVG 1.1//EN"
    	"http://www.w3.org/2002/04/xhtml-math-svg/xhtml-math-svg.dtd">

=cut

use strict;
use warnings;

use Encode;
use XML::SAX;
use XML::SAX::Writer;

sub InlineSVG($)
{
	my $text = shift;
	my $result = "";

	my $writer = XML::SAX::Writer->new(
		Output => \$result,
		#DEST => $DEST,
	);
	my $filter = MySAXPHandler->new(Handler => $writer);
	my $parser = XML::SAX::ParserFactory->parser(Handler => $filter);

	$parser->parse_string( $text);

	return $result;
}

### Main
my $text;
{
	local $/;
	$text = <>;
	$text = encode_utf8($text);

	# Insert DOCTYPE declaration, since XML::SAX::* refuse to handle it
	print '<?xml version="1.0" encoding="UTF-8"?>'."\n";
	print '<!DOCTYPE html PUBLIC'."\n";
    print '"-//W3C//DTD XHTML 1.1 plus MathML 2.0 plus SVG 1.1//EN"'."\n";
    print '"http://www.w3.org/2002/04/xhtml-math-svg/xhtml-math-svg.dtd">'."\n";

	print InlineSVG($text);
}

##########################################################################
### Anonymous inline package: SAX2 filter
##########################################################################
package MySAXPHandler;
use strict;
use IPC::Open2;
use base qw(XML::SAX::Base);

sub new {
	my $class = shift;
	my %options = @_;

	return bless \%options, $class;
}

sub start_element {
	my ($self, $data) = @_;

	# print opening tag <name>
	$self->SUPER::start_element($data);
}

sub end_element {
	my ($self, $data) = @_;

	# print opening tag <name>
	$self->SUPER::end_element($data);
}
