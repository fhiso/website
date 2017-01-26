#!/usr/bin/perl

use strict;
use warnings;

my $newp = 1; 
my $class;
my $long;

sub text($) {
    my ($txt) = @_;
    my $rfc2119 = qr/must|must\ not|required|shall|shall\ not|
                     should|should\ not|recommended|not\ recommended|
                     may|optional/x;
    my $css = 'font-variant: small-caps';
    $txt =~ s/(\*{1,2})($rfc2119)\1/
        my $open = length($1) == 2 ? '**' : '';
        $open . "<span style=\"$css\">$2<\/span>" . $open
    /gex;
    print "$txt\n";
}

while (<>) {
    chomp;
    if ($newp and s/^{\.([a-z]+)(\s*\.{3})?}\s*//) { 
        $long = $2 ? " long" : "";
        print "<div class=\"fhiso-$1$long\">\\fhisoopenclass{$1}\n";
        $class = $1;
    }

    if (defined $class and $long and /^(.*)\{\/\}\s*$/) {
        text $1;
        print "\\fhisocloseclass{$class}</div>\n\n";
        $class = undef; $newp = 1;
    }
    elsif (defined $class and not $long and /^\s*$/) {
        print "\\fhisocloseclass{$class}</div>\n\n";
        $class = undef; $newp = 1;
    }
    else {
        text $_;
        $newp = /^\s*$/;
    }
}

print "\\fhisocloseclass{$class}</div>\n" if defined $class;
