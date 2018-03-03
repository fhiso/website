#!/usr/bin/perl

use strict;
use warnings;

# This tells Perl that this Perl source file is encodede in UTF-8.
use utf8;

# This tells Perl to open STDIN, etc. as UTF-8.  This is better than doing
# binmode STDIN, ':utf8' because it works even when STDIN is a file specified
# in @ARGV auto-open by the <> operator.
use open qw(:std :utf8);

use Perl6::Slurp;

my $newp = 1; 
my $class;
my $long;

# This preprocessor now makes two passes over the input stream in order
# to handle forward references.  @lines contains the list of lines,
# complete with \n terminators, between passes.
my @lines;

my @sect;               # The current (sub)section numbers(s) while parsing.
my %labels;             # Map of label name to section number.
my $bad_nesting;        # Have we had any badly nested headings yet?

sub text($) {
    my ($txt) = @_;

    # RFC 2119 keywords
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

    # Scan all headings (currently excluding ones with --- and === underlining)
    # to keep track of section numbers.
    if ($txt =~ /^(#+)\s/) {
      my $l = length $1;
      while ($l < scalar @sect) { pop @sect }
      if ($l == scalar @sect) { ++$sect[$l-1] }
      elsif ($l == 1 + scalar(@sect)) { push @sect, 1 }
      else { $bad_nesting = 1 }

      # Where there's a {#name} mark at the heading line (which pandoc will
      # use to create an anchor), store it as a label for {§name} references
      # handled in this preprocessor. 
      if ($txt =~ /{#(\S+)}\s*$/) {
        if (exists $labels{$1}) { die "Duplicate label: $1" }
        $labels{$1} = join('.', @sect[1..$#sect]);
      }
    }

    # You can't nest the short form of [...] and `...` cleanly in pandoc 
    # markdown, so preprocess it here.
    $txt =~ s/`\[(\w+)\]`/[`$1`](#$1)/g;

    # Markdown has a poorly documented "feature" whereby two spaces at 
    # the end of a line inserts a hard line break (<br/> or \\).  Stop that.
    $txt =~ s/\s{2,}$/ /;

    push @lines, "$txt\n";
}

while (<>) {
    chomp;

    # File inclusion:  {#include filename}
    if ($newp and s/^{#include\s*(.*?)}$//) {
        my $txt = slurp($1) or die "Unable to read file '$1'";
        $txt =~ s/^/    /gm;
        push @lines, "$txt\n";
    }

    # Paragraph classes:  {.class} and {.class ...} {/}
    if ($newp and s/^{\.([a-z]+)(\s*\.{3})?}\s*//) { 
        $long = $2 ? " long" : "";
        push @lines, "<div class=\"fhiso-$1$long\">\\fhisoopenclass{$1}\n";
        $class = $1;
    }

    if (defined $class and $long and /^(.*)\{\/\}\s*$/) {
        text $1;
        push @lines, "\\fhisocloseclass{$class}</div>\n\n";
        $class = undef; $newp = 1;
    }
    elsif (defined $class and not $long and /^\s*$/) {
        push @lines, "\\fhisocloseclass{$class}</div>\n\n";
        $class = undef; $newp = 1;
    }
    else {
        text $_;
        $newp = /^\s*$/;
    }
}

push @lines, "\\fhisocloseclass{$class}</div>\n" if defined $class;

# Second pass over data handling references of the form {§name}
foreach my $line (@lines) {
  $line =~ s/{§(\S+)}/
    die "File has bad nesting" if $bad_nesting;
    die "Unknown label '$1'" unless exists $labels{$1};
    '§'.$labels{$1}
  /gex;
  print $line;
}
