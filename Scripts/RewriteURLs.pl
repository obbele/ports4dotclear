#!/usr/bin/perl

use strict;
use warnings;

use Encode;
use XML::SAX;
use XML::SAX::Writer;

my $SRC = shift;
my $DEST = shift;
unless (defined($SRC) && defined($DEST)) {
	die("Usage: $0 source_url destination_url");
}

sub RewriteURLs($)
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
	print '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"'."\n";
	print '"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">'."\n";

	print RewriteURLs($text);
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
	#my $DEST = $self->{Handler}->{Handler}->{DEST};

	# if find a <pre format="toto"> tag
	# 	store cmd information and delete this attribute from the
	# 	xhtml output
	if ( defined($data->{Attributes}->{"{}src"}) )
	{
		$data->{Attributes}->{"{}src"}->{"Value"} =~ s{^$SRC}{$DEST}; 
	}
	if ( defined($data->{Attributes}->{"{}href"}) )
	{
		$data->{Attributes}->{"{}href"}->{"Value"} =~ s{^$SRC}{$DEST}; 
	}
	if ( defined($data->{Attributes}->{"{}data"}) )
	{
		$data->{Attributes}->{"{}data"}->{"Value"} =~ s{^$SRC}{$DEST}; 
	}

	# print opening tag <name>
	$self->SUPER::start_element($data);
}
