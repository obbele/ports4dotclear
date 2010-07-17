#!/usr/bin/perl

use strict;
use warnings;

use Encode;
use XML::SAX;
use XML::SAX::Writer;

sub resize_svg
{
	my ($text) = @_;
	my $result = "";

	my $writer = XML::SAX::Writer->new( Output => \$result,);
	my $filter = SAX_ResizeSVG->new(Handler => $writer);
	my $parser = XML::SAX::ParserFactory->parser(Handler => $filter);

	$parser->parse_string( $text);

	return $result;
}

### Main
my $text;
{
	local $/;
	$text = <>;

	print '<?xml version="1.0" encoding="UTF-8" standalone="no"?>'."\n";
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
	my $class = shift;
	my %options = @_;

	return bless \%options, $class;
}

sub start_element {
	my ($self, $data) = @_;

	if ($data->{Name} eq "svg") {
		my $w = $data->{Attributes}->{"{}width"}->{Value};
		my $h = $data->{Attributes}->{"{}height"}->{Value};
		$data->{Attributes}->{'{}viewBox'} = {
			Name => "viewBox",
			LocalName => "viewBox",
			Value => "0 0 $w $h",
		};

		$data->{Attributes}->{"{}width"}->{Value} = "100%";
		$data->{Attributes}->{"{}height"}->{Value} = "100%";
	}

	# print opening tag <name>
	$self->SUPER::start_element($data);
}
