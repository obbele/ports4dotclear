#!/usr/bin/perl
# Superseed by the global Makefile's target 'new'
#
# still is a simple example of PERL used for system administration
# (copy/mv/link/…)

use File::Copy qw/ copy /;
my $TPL="Template";

print "Enter new directory name:\n";
chomp( my $dir = <>);

# Number by default entry to 999
$dir = "999_$dir";

mkdir $dir;
copy "$TPL/publish.log", "$dir/publish.log";
copy "$TPL/text.mkd", "$dir/text.mkd";
link "$TPL/Makefile", "$dir/Makefile";
mkdir "$dir/Media";

chdir $dir;
