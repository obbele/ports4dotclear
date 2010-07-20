#!/usr/bin/perl
=pod

=head1 NAME

Externalize.pl - Process part of a XML tree with external commands

=head1 DESCRIPTION

Externalize.pl is a basic XML SAX filter. It looks for any occurence of
'<TAG extern="foobar"></TAG>', takes the data inside this element and
output the result back in the XML tree.

=head1 USAGE

Externalize.pl reads its input from stdin and outputs the result to
stdout. You should use it this way:

	./Externalize.pl <doc.xhtml >result.xhtml

=head1 EXAMPLES

=head2 Uppercase example

The following XML extract:

	<pre extern="tr a-z A-Z">
		Hello World !
	</pre>

would become:

	<pre>
		HELLO WORLD !
	</pre>

=head2 Sort example

The following XML extract:

	<div id="foobar" extern="sort">
		1
		3
		9
		8
		2
	</div>

would become:

	<div id="foobar" >
		1
		2
		3
		8
		9
	</div>

=cut

use strict;
use warnings;

use Encode;
use XML::SAX;
use XML::SAX::Writer;

sub FormatPREs($)
{
	my $text = shift;
	my $result = "";

	my $writer = XML::SAX::Writer->new(
		Output => \$result,
	);
	my $filter = SAX_FormatPRE->new(Handler => $writer);
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

	# Insert DOCTYPE declaration, since XML::SAX::* refuses to handle it
	print '<?xml version="1.0" encoding="UTF-8"?>'."\n";
	print '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"'."\n";
	print '"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">'."\n";

	print FormatPREs($text);
}

##########################################################################
### Anonymous inline package: SAX2 filter
##########################################################################
package SAX_FormatPRE;
use strict;
use IPC::Open2;
use base qw(XML::SAX::Base);

sub new {
	my $class = shift;
	my %options = @_;

	# Set our flag used when parsing to-be-formatted <pre> tags
	$options{"externTag"} = undef;
	$options{"externCmd"} = undef;
	$options{"externData"} = "";

	return bless \%options, $class;
}

sub start_element {
	my ($self, $data) = @_;

	# if find a <X extern="toto"> tag
	# 	store cmd information and delete this attribute from the
	# 	xhtml output
	if (defined($data->{Attributes}->{"{}extern"}) )
	{
		$self->{externTag} = $data->{Name};
		$self->{externCmd} = $data->{Attributes}->{"{}extern"}->{"Value"};
		delete $data->{Attributes}->{"{}extern"};
	}

	# print opening tag <name>
	$self->SUPER::start_element($data);

	# Insert CSS style
	if ($data->{Name} eq "head") {
		$self->outputRawXML("\n    ".'<link rel="stylesheet" type="text/css" href="highlight.css" />');
	}
}

sub characters {
	my ($self, $chars) = @_;

	if (defined $self->{externCmd}) {
		# forward to our special externData variable
		$self->{externData} .= $chars->{Data};
	} else {
		# else forward to normal output
		$self->SUPER::characters($chars);
	}
}

sub end_element {
	my ($self, $data) = @_;

	# when leaving a <pre> element,
	# 	convert our data and
	# 	reinitialise our filter
	if (defined($self->{externCmd}) and $data->{Name} eq $self->{externTag}) {

		my $input = $self->{externData};
		$input =~ s/^[\s\n\r]*//; # chop first new lines
		$input =~ s/[\s\n\r]*$//; # chop last empty lines
		my $output = externalize( $self->{externCmd}, $input );

		$self->outputRawXML($output);

		# Do not forget to reinitialize our flags !
		$self->{externTag} = undef;
		$self->{externCmd} = undef;
		$self->{externData} = "";
	}

	$self->SUPER::end_element($data);
}

# Prevent escaping of XML entities as '<', '>', '&', …
sub outputRawXML {
	my ($self, $output) = @_;

	# We cheat and output directly to the SAX::Writer::Consumer
	# otherwise SUPER::characters would escape the HTML
	# entities and scramble the tags we are inserting
	$self->{Handler}->{Handler}->_output_element;
	$self->{Handler}->{Handler}->{Consumer}->output($output);

	# This is an alternate version of the previous hack
	# but this one does not seems to work :(
	#$self->{Handler}->{Handler}->{InCDATA} = 0;
	#$self->SUPER::characters({ Data => $output });
	#$self->{Handler}->{Handler}->{InCDATA} = 1;
}

# Pipe $input to an external command $cmd and return the output
# N.B.: this is a standalone function, NOT an object method !
sub externalize {
	my ($cmd, $input) = @_;
	my ($hin, $hout, $pid, $output);

	$pid = open2( $hout, $hin, $cmd);
	print $hin $input; close $hin;
	{
		local $/;
		$output = <$hout>; close $hout;
	}
	waitpid( $pid, 0);
	return $output;
}

# Alternative version for inserting CSS link in the HTML headers
sub insertCSS
{
	my ($self, $data) = @_; # $data is a reference node to be cloned

	my %style = %{$data};
	my $attrs = {
		'{}rel'  => {
			'Prefix' => '',
			'LocalName' => 'rel',
			'Value' => 'stylesheet',
			'Name' => 'rel',
			'NamespaceURI' => '',
		},
		'{}type'  => {
			'Prefix' => '',
			'LocalName' => 'type',
			'Value' => 'text/css',
			'Name' => 'type',
			'NamespaceURI' => '',
		},
		'{}href'  => {
			'Prefix' => '',
			'LocalName' => 'href',
			'Value' => 'highlight.css',
			'Name' => 'href',
			'NamespaceURI' => '',
		},
	};

	$style{"Name"} = "link";
	$style{"Attributes"} = $attrs;

	$self->SUPER::characters({ Data => "\n    " });
	$self->SUPER::start_element(\%style);
	$self->SUPER::end_element(\%style);
}
