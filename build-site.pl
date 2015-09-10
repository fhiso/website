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
  'style'  
     => [ 'tsc-governance/style.md',      'Style Guide' ],
  'tsc-public' 
     => [ 'tsc-governance/tsc-public.md', 'tsc-public Mailing List' ],
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
       => [ 'website/cfps_processor/index.html', 'Papers received' ],
    'submit'
       => [ 'website/cfps_processor/submit.md', 'Submit paper' ],
  }
};

my @files = ( '.htaccess', 'style.css', 'fhiso.png', 'favicon.ico' );

my $outdir = '../www-build';

sub right_index_item($$$$$) {
    my ($out, $key, $i, $item, $class) = @_;

    my $t = ref($i) eq 'HASH' ? $i->{index}->[1] : $i->[1]; 
    $t =~ s/&/&amp;/g;
    if ($i == $item) { 
        print $out "<li class=\"$class\">$t</li>\n"; 
    }
    else { 
        print $out "<li class=\"$class\"><a href=\"$key\">$t</a></li>\n";
    }
}

sub right_index($$$) {
    my ($out, $index, $item) = @_;

    print $out <<EOF;
    <div class="right">
      <h2>Related Links</h2>
      <ul class="related">
EOF
    if (exists $index->{index}) {
        right_index_item( $out, 'index', $index->{index}, $item, 'index' );
    }
    foreach my $key (sort { lc($a) cmp lc($b) } keys %$index) {
        next if $key eq 'index';
        right_index_item( $out, $key, $index->{$key}, $item, '' );
    }
    print $out <<EOF;
      </ul>
    </div>
EOF
}

sub write_html {
    my ($file, $dir, $item, $crumbs, $index) = @_;

    my $src = "../$item->[0]";
    my $dest = "${dir}$file.html";
    my $title = $item->[1];

    $title =~ s/&/&amp;/g;

    open my $out, '>', "$outdir/$dest" or die "Unable to open $outdir/$dest";
    print $out <<EOF;
<html xmlns="http://www.w3.org/1999/xhtml" lang="en" xml:lang="en">
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    <meta http-equiv="Content-Style-Type" content="text/css" />
    <meta name="author" 
          content="Family History Information Standards Organisation, Inc." />
    <title>$title</title>
    <link rel="stylesheet" href="/style.css" type="text/css" />
  </head>
  <body>
    <div class="logo"><a href="http://fhiso.org/"><img src="/fhiso.png" 
         alt="Family History Information Standards Organisation" /></a></div>
    <div class="navbar menu1">
      <a class="navitem" href="http://fhiso.org/">Home</a>
EOF

    for my $i (0 .. $#$crumbs) {
        if (@$crumbs) {
            my $t = $crumbs->[$i]; $t =~ s/&/&amp;/g;
            my $depth = $#$crumbs-$i;  
            $depth++ if $dest =~ m!/index\.html$!;
            my $url = join( '/', ('..') x $depth ) || '.';
            print $out <<EOF
      <span class="sep">/</span>
      <a class="navitem" href="$url">$t</a>
EOF
        }
    }

    print $out <<EOF;
      <span class="sep">/</span>
      <span class="navitem active">$title</span>
    </div>
    <div class="navbar menu2">
      <a href="/sitemap">Site Map</a>
      <script type="text/javascript">
      <!--
        h='&#102;&#104;&#x69;&#x73;&#x6f;&#46;&#x6f;&#114;&#x67;';
        a='&#64;';n='&#116;&#x73;&#x63;';e=n+a+h;
        document.write('<a h'+'ref'+'="ma'+'ilto'+':'+e+'">'
                       +'Contact Us'+'<\/'+'a'+'>');
      // -->
      </script>
    </div>
EOF
    
    right_index($out, $index, $item) if $index;

    print $out "<div class=\"content\">\n";

    if ($src =~ /\.md$/) {
        my $dialect 
            = 'markdown+definition_lists+header_attributes-auto_identifiers';
        print $out qx(pandoc -f $dialect "$src");
    }
    elsif ($src =~ /\.html$/) {
        print $out qx(cat "$src");
    }
    else { 
        die "Unknown file extension"; 
    }

    print $out "</div>\n";

    my $y = strftime("%y", gmtime);
    print $out <<EOF;
    <div class="footer">
      Copyright © 2013–$y, Family History Information Standards Organisation, 
      Inc.<br/> Hosting generously donated by 
      <a href="http://www.mythic-beasts.com/">Mythic Beasts, Ltd</a>.
    </div>
  </body>
</html>
EOF
    exit 1 if $?;
    close $out;
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


