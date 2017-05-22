#!/usr/bin/perl

use strict;
use warnings;

use Perl6::Slurp;

my $newp = 1; 
my $class;
my $long;

sub text($) {
    my ($txt) = @_;
    my @rfc2119 = ('must not', 'must', 'required', 'shall not', 'shall',
                   'should not', 'should', 'not recommended', 'recommended',
                   'may', 'optional');
    my $css = 'font-variant: small-caps';
    # Handle uses of *must*, etc.
    my $rfc2119lc = join '|', map {s/ /\\ /; $_} @rfc2119;
    $txt =~ s/(\*{1,2})($rfc2119lc)\1/
        my $open = length($1) == 2 ? '**' : '';
        $open . "<span style=\"$css\">$2<\/span>" . $open
    /gex;
    # Handle uses of MUST, etc.
    my $rfc2119uc = join '|', map {s/ /\ /; uc $_} @rfc2119;
    $txt =~ s/\b($rfc2119uc)\b/
        "<span style=\"$css\">".lc($1)."<\/span>"
    /gex;

    # You can't nest the short form of [...] and `...` cleanly in pandoc 
    # markdown, so preprocess it here.
    $txt =~ s/`\[(\w+)\]`/[`$1`](#$1)/g;

    print "$txt\n";
}

while (<>) {
    chomp;

    if ($newp and s/^{#include\s*(.*?)}$//) {
        my $txt = slurp($1) or die "Unable to read file '$1'";
        $txt =~ s/^/    /gm;
        print "$txt\n";
    }

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
