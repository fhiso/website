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

    if (defined $class and $long and /^(.*)\{\/\}\s*$/) {
        print "$1\n\\fhisocloseclass{$class}</div>\n\n";
        $class = undef; $newp = 1;
    }
    elsif (defined $class and not $long and /^\s*$/) {
        print "\\fhisocloseclass{$class}</div>\n\n";
        $class = undef; $newp = 1;
    }
    else {
        print "$_\n";
        $newp = /^\s*$/;
    }
}

print "\\fhisocloseclass{$class}</div>\n" if defined $class;
