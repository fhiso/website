#!/usr/bin/perl

use strict;
use warnings;

my $newp = 1; 
my $class;

while (<>) {
    chomp;
    if ($newp and s/^{\.([a-z]+)}\s*//) { 
        print "<div class=\"fhiso$1\">\\fhisoopenclass{$1}\n";
        $class = $1;
    }
    if (defined $class and /^\s*$/) {
        print "\\fhisocloseclass{$class}</div>\n";
        $class = undef;
    }
    print "$_\n";
    $newp = /^\s*$/;
}

print "\\fhisocloseclass{$class}</div>\n" if defined $class;
