#!/usr/bin/perl

use strict;
use warnings;

use TAP::Harness;

my @tests   = ( glob("*.l.t") );
my $harness = TAP::Harness->new(
    {
        verbosity => 0,
        color     => 1,
        jobs      => 3
    }
);
$harness->runtests(@tests);
