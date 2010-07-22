#!/usr/bin/perl

=pod

=head1 NAME

publish.pl - Upload a whole message to a remote DotClear2 blog

=head1 DESCRIPTION

If no configuration name is specified on the command line, publish.pl
will default to the last one present in the file C<publish.log> or exit,
if none is found.

The script will then upload every file in the C<Media/*> directory to
the DotClear2 blog thanks to the script Scripts/XML-RPC/dotclear.py.

In return, it gets the URL of the content on the remote host (generally
C</blog/public/msg_name/example.file>) and will use it to replace every
occurence of C<Media/example.file> by C</blog/public/msg_name/example.file>
in the XHTML document. See C<RewriteURLs.pl> for more details.

Once the files in C<Media/*> have been processed, the modified XHTML
document is transmitted to DotClear2 to create a new message or edit an
old one.

At the end, publish.pl logs the configuration name, the message ID and
updates the dates in C<publish.log>.

=head1 USAGE

publish.pl takes one required argument, the filename of an XHTML
document, and an optional argument describing the Scripts/XML-RPC/*.cfg
configuration file to use.

	./publish.pl doc.xhtml [ConfigName]"

=cut

use strict;
use warnings;
use File::Temp qw/ tempfile tmpnam /;
use File::Copy qw/ copy move /;
use File::Spec;
use Cwd;
use IPC::Open2;

# Global _EVIL_ variables
my $LOG="publish.log";
my $XMLRPC="../Scripts/XML-RPC/dotclear.py";
my $RWURLS="../Scripts/RewriteURLs.pl";
my $MEDIADIR="Media";
sub usage()
{
	die("Usage: $0 doc.xhtml [ConfigName]");
}

# Read the $LOG file, extract last line and print the first field
# which should be the name of the last configuration file
sub get_last_config()
{
	my $line;

	open( my $fh, "<$LOG");
	while (<$fh>) { 
		$line = $_ unless /^#/;
	}
	close $fh;

	die("Cannot read last line of $LOG") if ! defined($line);

	my @elems = split(/\s/, $line);
	my $last_config = shift @elems;

	if (defined $last_config) {
		return $last_config;
	} else {
		die("Cannot parse the first field in the last line of $LOG");
	}
}

# get the msg ID corresponding to the given configuration name
sub get_msg_id($)
{
	my ($config) = @_;
	my $id;

	open( my $fh, "<$LOG");
	while (<$fh>) { 
		if (/^$config/) {
			my @elems = split;
			$id = $elems[1];
		}
	}
	close $fh;

	return $id;
}

sub get_last_id($)
{
	my ($config) = @_;
	my $id;
	open(my $pipe, "$XMLRPC --conf=$config --list=1 |");
	while (<$pipe>) {
		if (/^([[:digit:]]+)/) {
			$id = $1;
		}
	}
	close($pipe);

	return $id;
}

sub parent_directory()
{
	my $cwd = getcwd();
	my @dirs = File::Spec->splitpath( $cwd);
	return $dirs[$#dirs];
}

# For each file in $MEDIADIR/*, 
# 	upload it
# 	then replace its orginal url ($MEDIADIR/$f) by the one on the dc2 server
# depend on the $RWURLS / RewriteURLs.pl SAX parser
sub upload_content_and_rewrite_urls($$)
{
	my ($config, $xhtml) = @_;

	# Copy xhtml file to a temporary location for processing
	my $publish = tmpnam();
	copy $xhtml, $publish;

	# A trick to upload filename to /blog/public/<msg_name>/foobar.jpg
	# and not /blog/public/$MEDIADIR/foobar.jpg
	my $parent_directory = parent_directory();
	symlink $MEDIADIR, $parent_directory;

	foreach my $src (glob("$parent_directory/*")) {
		# 1) upload
		my $dest;
		open(my $pipe, "$XMLRPC --conf=$config --upload=$src |");
		while(<$pipe>) {
			if (/file url = (.*)/) {
				$dest = $1;
			}
		}
		close( $pipe);

		# 2) untrick the $parent_directory
		$src =~ s/$parent_directory/$MEDIADIR/;

		# 3) rewrite URL
		open(my $fh, "<$publish"); 			# read file
		my ($wpipe, $rpipe);				# rewrite urls pipe
		my ($temph, $tempname) = tempfile();# retrieve processed output
		print "replacing \"$src\" by \"$dest\" in tempfile [$tempname]\n";
		my $pid = open2($rpipe, $wpipe, "$RWURLS", "$src", "$dest");
		{
			local $/; # slurping ON
			my $input = <$fh>; 		close $fh;
			print $wpipe $input; 	close $wpipe;
			my $output = <$rpipe>; 	close $rpipe;
			print $temph $output; 	close $temph;
		}
		waitpid($pid, 0);

		# replace our temporary publish file by the new rewrited one
		move $tempname, $publish; #unlink $tempname;
	}

	# untrick the parent_directory
	unlink $parent_directory;

	# Return the name of our temporary file to be published
	return $publish;
}

# Replace previous date by present one
sub update_publish_date($$)
{
	my ($config, $id) = @_;

	# Copy publish file to a temporary location for processing
	my $temp = tmpnam();
	copy $LOG, $temp;

	open(my $input, "<$temp");
	open(my $output, ">$LOG");
	while(<$input>) {
		if (/^$config\s*$id\s*([0-9-]*)/) {
			my $first_date = $1;
			chomp( my $new_date = `date +%Y-%m-%d`);
			print $output "$config\t$id\t$first_date\t$new_date\n";
		} else {
			print $output $_;
		}
	}
	close $input;
	close $output;
	unlink $temp;
}

### Main
my $XHTML = shift or usage();
my $CONFIG = shift;
unless (defined($CONFIG)) { $CONFIG = get_last_config(); }

my $rewrited = upload_content_and_rewrite_urls($CONFIG, $XHTML);

my $ID = get_msg_id($CONFIG);
if (defined($ID)) {
	print "Replacing previous message #$ID on [$CONFIG]\n";

	my @cmd = ($XMLRPC, "--conf=$CONFIG", "--edit=$ID", "--raw=$rewrited");
	system(@cmd) == 0 or die("system @cmd failed: $!");

	update_publish_date($CONFIG, $ID);

} else {
	print "Posting new message on [$CONFIG]\n";

	my @cmd = ($XMLRPC, "--conf=$CONFIG", "--new", "--raw=$rewrited");
	system(@cmd) == 0 or die("system @cmd failed: $!");

	my $last_id = get_last_id($CONFIG);
	chomp( my $date = `date +%Y-%m-%d`);
	open(my $fh, ">>$LOG") or die $!;
	print $fh "$CONFIG\t$last_id\t$date\t$date\n";
	close($fh);
}

# erare the temporary file inherited from upload_content_and_rewrite_urls
unlink $rewrited;

exit 0;
