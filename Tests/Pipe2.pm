package Pipe2;

use strict;
use warnings;
use IPC::Open2;

# Pipe $input to an external command $cmd and return the output
# N.B.: this is a standalone function, NOT an object method !
sub pipe2($$) {
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

1;


__END__

=pod

=head1 NAME

Pipe2.pl - Perl handy function to call an external process

=head1 DESCRIPTION

Pipe2 provide a simple wrapper around IPC::Open2. You just have to
provide a command and an input string.

=head1 USAGE

	use Pipe2;

	my $input = "Hello World !\n";
	my $output = pipe2( "tr a-z A-Z", $input);
	print $output;

=cut

