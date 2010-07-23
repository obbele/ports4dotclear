#!/usr/bin/perl

=pod

=head1 NAME

RewriteURLs.pl - Substitute URLs by new ones

=head1 DESCRIPTION

RewriteURLs.pl is a basic XML SAX filter. It looks for any XML elements
with a C<href>, C<src> or C<data> attribute and, if this attribute
matched the script argument C<old_url>, replaces it by C<new_url>.

=head1 USAGE

RewriteURLs.pl reads its input from stdin and outputs the result to
stdout. You should use it this way:

	./RewriteURLs.pl old_url new_url  <doc.xhtml >result.xhtml

=head1 EXAMPLES

The following XML extract:

	<img src="Media/foobar.jpg"/>

would become, once filtered with C<./RewriteURLs.pl Media/foobar.jpg
/blog/public/foobar.jpg>:

	<img src="/blog/public/foobar.jpg"/>

=cut

use strict;
use warnings;

use Encode;
use XML::SAX;
use XML::SAX::Writer;

my $SRC  = shift;
my $DEST = shift;
unless ( defined($SRC) && defined($DEST) ) {
    die("Usage: $0 source_url destination_url");
}

sub RewriteURLs {
    my $text   = shift;
    my $result = "";

    my $writer = XML::SAX::Writer->new(
        Output     => \$result,
        EncodeFrom => 'UTF-8',
        EncodeTo   => 'UTF-8',

        #DEST => $DEST,
    );
    my $filter = MySAXPHandler->new( Handler => $writer );
    my $parser = XML::SAX::ParserFactory->parser( Handler => $filter );

    $parser->parse_file(*STDIN);

    return $result . "\n";
}

### Main
my $text = RewriteURLs();
$text = encode_utf8($text);
print $text;

##########################################################################
### Anonymous inline package: SAX2 filter
##########################################################################
package MySAXPHandler;
use strict;
use IPC::Open2;
use base qw(XML::SAX::Base);

sub new {
    my $class   = shift;
    my %options = @_;

    return bless \%options, $class;
}

sub start_element {
    my ( $self, $data ) = @_;

    #my $DEST = $self->{Handler}->{Handler}->{DEST};

    # if find a <pre format="toto"> tag
    # 	store cmd information and delete this attribute from the
    # 	xhtml output
    if ( defined( $data->{Attributes}->{"{}src"} ) ) {
        $data->{Attributes}->{"{}src"}->{"Value"} =~ s{^$SRC}{$DEST};
    }
    if ( defined( $data->{Attributes}->{"{}href"} ) ) {
        $data->{Attributes}->{"{}href"}->{"Value"} =~ s{^$SRC}{$DEST};
    }
    if ( defined( $data->{Attributes}->{"{}data"} ) ) {
        $data->{Attributes}->{"{}data"}->{"Value"} =~ s{^$SRC}{$DEST};
    }

    # print opening tag <name>
    $self->SUPER::start_element($data);
}
