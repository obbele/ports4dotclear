#!/usr/bin/perl

=pod

=head1 NAME

InlineSVG.pl - Insert SVG object inline XHTML documents

=head1 DESCRIPTION

InlineSVG.pl is NOT WORKING.

=head1 USAGE

InlineSVG.pl reads its input from stdin and outputs the result to
stdout. You should use it this way:

	./InlineSVG.pl <doc.xhtml >result.xhtml

=head1 EXAMPLES

=cut

use strict;
use warnings;

use Encode;
use XML::SAX;
use XML::SAX::Writer;

sub InlineSVG
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

	if ($data->{Prefix} eq '') {
		$data->{Prefix} = 'svg';
		$data->{Name} = 'svg:'.$data->{Name};
	}
	# print opening tag <name>
	$self->SUPER::start_element($data);
}

sub end_element {
	my ($self, $data) = @_;

	if ($data->{Prefix} eq '') {
		$data->{Prefix} = 'svg';
		$data->{Name} = 'svg:'.$data->{Name};
	}
	# print opening tag <name>
	$self->SUPER::end_element($data);
}
