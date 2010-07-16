#!/usr/bin/perl

use strict;
use warnings;
use File::Temp qw/ tempfile tmpnam /;
use File::Copy qw/ copy move /;
use IPC::Open2;

# Global _EVIL_ variables
my $LOG="publish.log";
my $XMLRPC="../Scripts/XML-RPC/dotclear.py";
my $RWURLS="../Scripts/RewriteURLs.pl";
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

# For each file in Media/*, 
# 	upload it
# 	then replace its orginal url (Media/$f) by the one on the dc2 server
# depend on the $RWURLS / RewriteURLs.pl SAX parser
sub upload_content_and_rewrite_urls($$)
{
	my ($config, $xhtml) = @_;

	# Copy xhtml file to a temporary location for processing
	my $publish = tmpnam();
	copy $xhtml, $publish;

	# Process each Media/* file
	foreach my $src (glob('Media/*')) {
		# 1) upload
		my $dest;
		open(my $pipe, "$XMLRPC --conf=$config --upload=$src |");
		while(<$pipe>) {
			if (/file url = (.*)/) {
				$dest = $1;
			}
		}
		close( $pipe);

		# 2) rewrite URL
		open(my $fh, "<$publish"); 			# read file
		my ($wpipe, $rpipe);				# rewrite urls pipe
		my ($temph, $tempname) = tempfile();# retrieve processed output
		print "processing \"$src\" -> [$dest] in tempfile = [$tempname]\n";
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
		if (/^$config/) {
			print $output "$config\t$id\t".`date +%Y-%m-%d`."\n";
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
	open(my $fh, ">>$LOG") or die $!;
	print $fh "$CONFIG\t$last_id\t".`date +%Y-%m-%d`."\n";
	close($fh);
}

unlink $rewrited;

exit 0;
