#!/usr/bin/perl

use strict;
use warnings;

my $newp = 1; 
my $class;
my $long;

while (<>) {
    chomp;
    if ($newp and s/^{\.([a-z]+)(\s*\.{3})?}\s*//) { 
        $long = $2 ? " long" : "";
        print "<div class=\"fhiso-$1$long\">\\fhisoopenclass{$1}\n";
        $class = $1;
    }
    if (defined $class and ($long ? s/^\{\/\}\s*$// : /^\s*$/)) {
        print "\\fhisocloseclass{$class}</div>\n";
        $class = undef;
    }
    print "$_\n";
    $newp = /^\s*$/;
}

print "\\fhisocloseclass{$class}</div>\n" if defined $class;
