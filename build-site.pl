#!/usr/bin/perl

use strict;
use warnings;

use Perl6::Slurp;
use File::Copy;
use FindBin;
use POSIX qw/strftime/;

my $site = {
  'index'      
     => [ 'tsc-governance/tsc.md',        'Technical Work' ],
  'opm'        
     => [ 'tsc-governance/opm.md',        'Operations & Policy Manual' ],
  'charter'
     => [ 'tsc-governance/charter.md',    'Charter' ],
  'tsc-public' 
     => [ 'tsc-governance/tsc-public.md', 'tsc-public Mailing List' ],
  'minutes' 
     => [ 'tsc-governance/minutes.md',    'Minutes' ],
  'strategy'  
     => [ 'tsc-governance/strategy.md',   'Technical Strategy (draft)' ],
  'priorities'
     => [ 'tsc-governance/strategy.md',   'Priorities (draft)' ],
  'policies' => {
     'index' 
        => [ 'tsc-governance/policies.md',     'Policies' ],
     'style'  
        => [ 'tsc-governance/style.md',        'Style Guide' ],
     'vocabularies'  
        => [ 'tsc-governance/vocabularies.md', 'Vocabularies (draft policy)' ],
  },
  'egs' => {
     'index'
        => [ 'tsc-governance/egs.md',      'Exploratory Groups' ],
     'sceg' => {
        'index'   
           => [ 'tsc-governance/S&CEG/index.md', 'Sources & Citations' ],
        'directives'
           => [ 'tsc-governance/S&CEG/directives.md', 'Directives' ],
        'decisions'
           => [ 'sources-and-citations-eg/decisions.md', 'Decisions' ],
        'links'
           => [ 'sources-and-citations-eg/Useful_Links.md', 'Useful Links' ],
     },
     'cceg' => {
        'index'
           => [ 'tsc-governance/CCEG/index.md', 'Core Concepts' ],
        'directives', 
           => [ 'tsc-governance/CCEG/directives.md', 'Directives' ],
     },
     'lexeg' => {
        'index'
           => [ 'tsc-governance/LexEG/index.md', 'Lexicon' ],
        'directives', 
           => [ 'tsc-governance/LexEG/directives.md', 'Directives' ],
        'snapshot',
           => [ 'lexicon-eg/builder/snapshot.md', 'Snapshot' ],
     }
   },
  'bibliography' => {
    'index'
       => [ 'tsc-governance/bibliography.md', 'Bibliography' ],
    'contents'
       => [ 'bibliography/bibliography.md', 'Contents' ],
    'datamodels'
       => [ 'bibliography/datamodels.md', 'Data Models' ],
  },
  'cfps' => {
    'index'
       => [ 'tsc-governance/CFPS/index.md', 'Call for Papers' ],
    'faq'
       => [ 'tsc-governance/CFPS/faq.md', 'FAQ' ],
    'papers'
       => [ 'website/cfps_processor/papers.php', 'Papers received' ],
    'submit'
       => [ 'website/cfps_processor/submit.md', 'Submit paper' ],
  }
};

my @files = ( '.htaccess', 'style.css', 'fhiso.png', 'favicon.ico', 
              'columnsort.js' );

my $outdir = '../www-build';


sub write_html_1 {
    my ($file, $dir, $item, $crumbs, $index) = @_;

    my $src = "../$item->[0]";
    my $dest = "${dir}$file.php";
    my $primary = undef;
    if ($src =~ /-([0-9]{8})\.([a-z]+)$/) {
        $primary = $dest;  
        $dest = "${dir}$file-$1.php";
        $primary =~ s!^(?:.*/)?([^./]+)\.php$!$1!;
    }

    open my $out, '>', "$outdir/$dest" or die "Unable to open $outdir/$dest";
    print $out "<?php\n";

    print $out "\$page_title = '$item->[1]';\n\n";

    my $root;
    print $out "\$ancestral_pages = [\n";
    for my $i (0 .. $#$crumbs) {
        if (@$crumbs) {
            my $t = $crumbs->[$i];
            my $depth = $#$crumbs-$i;  
            $depth++ if $dest =~ m!/index\.php$!;
            my $url = join( '/', ('..') x $depth ) || '.';
            print $out "  (object)[ 'url' => '$url', 'title' => '$t' ],\n";
            $root = $url unless defined $root;
        }
    }
    print $out "];\n\n";
    
    if ($index) { 
        print $out "\$child_pages = [\n";
        foreach my $key (sort { $a eq 'index' ? -1 :
                                $b eq 'index' ? +1 : 
                                lc($a) cmp lc($b) } keys %$index) {
            my $i = $index->{$key};
            my $t = ref($i) eq 'HASH' ? $i->{index}->[1] : $i->[1];
            print $out "  (object)[ 'url' => '$key', 'title' => '$t' ],\n";
        }
        print $out "];\n\n";
    }

    $root //= '.';
    print $out "set_include_path('$root');\n\n";

    print $out "function content() { ?>\n";

    if (defined $primary) { 
        print $out '<p class="warning">Warning: '
            . 'This may be an old version of the document.   '
            . 'The current version can be found '
            . "<a href=\"$primary\">here</a>.</p>\n";
    }

    if ($src =~ /\.md$/) {
        my $dialect 
            = 'markdown+definition_lists+header_attributes-auto_identifiers';
        print $out qx(pandoc -f $dialect "$src");
    }
    elsif ($src =~ /\.(html|php)$/) {
        print $out qx(cat "$src");
    }
    else { 
        die "Unknown file extension"; 
    }

    print $out "<?php }\n\n";

    print $out "include('include/template.php');\n";
    exit 1 if $?;
    close $out;
}

sub write_html {
    my ($file, $dir, $item, $crumbs, $index) = @_;
    write_html_1($file, $dir, $item, $crumbs, $index);
 
    my $old_pat = "../$item->[0]";
    my $date_pat = "[0-9]" x 8;
    $old_pat =~ s/\.([a-z]+)$/-$date_pat\.$1/;
    foreach my $old (glob $old_pat) {
        $old =~ s!^\.\./!!;
        write_html_1($file, $dir, [ $old, $item->[1] ], $crumbs, $index);
    }
}

sub recurse {
    my ($desc, $dir, @crumbs) = @_;
    $dir //= '';

    if (exists $desc->{'index'}) {
        my $i = $desc->{'index'};
        write_html( 'index', $dir, $i, \@crumbs, $desc );
        push @crumbs, $i->[1];
    }

    foreach my $file (keys %$desc) {
        next if $file eq 'index';
        my $i = $desc->{$file};
        if ( ref($i) eq 'HASH') { 
            mkdir "$outdir/$dir$file" unless -d "$outdir/$dir$file";
            recurse( $i, "$dir$file/", @crumbs ); 
        }
        else { 
            write_html( $file, $dir, $i, \@crumbs, $desc );
        }
    }
}

sub recurse_sitemap {
    my ($out, $indent, $path, $desc) = @_;
    foreach my $key (sort { lc($a) cmp lc($b) } keys %$desc) {
        next if $key eq 'index';
        my $i = $desc->{$key};
        my $t = ref($i) eq 'HASH' ? $i->{index}->[1] : $i->[1]; 
        print $out "$indent*   [$t](/$path$key)\n";
        recurse_sitemap($out, "$indent    ", "$path$key/", $i) 
            if ref($i) eq 'HASH';
    }   
}

mkdir $outdir unless -d $outdir;

open my $sitemap, '>', "$FindBin::Bin/sitemap.md" or die;
print $sitemap "# Site Map\n";
print $sitemap "<div class=\"sitemap\">\n";
print $sitemap "[$site->{index}->[1]](/)\n\n";
recurse_sitemap( $sitemap, '', '', $site );
print $sitemap "</div>\n";
close $sitemap;
write_html('sitemap', '', [ 'website/sitemap.md', 'Site Map' ], [$site->{index}->[1]], $site);

foreach my $f (@files) {
  copy $f, "$outdir/";
}
recurse $site;


