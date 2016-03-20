#!/usr/bin/perl

use strict;
use warnings;

use Perl6::Slurp;
use File::Copy;
use FindBin;
use POSIX qw/strftime/;
use XML::LibXML;

my @files = ( 'style.css', 'fhiso.png', 'favicon.ico', 'columnsort.js' );

my $outdir = '../www-build';

# We use this to avoid duplicating the markdown dialect between repositories
system "make -q -C \"$FindBin::Bin/../tsc-governance\" .dialect";
my $dialect = slurp "$FindBin::Bin/../tsc-governance/.dialect";

sub write_html_1 {
    my ($file, $dir, $item, $crumbs, $index) = @_;

    my $src = "../$item->{src}";
    my $dest = "${dir}$file.php";
    my $primary = undef;
    if ($src =~ /-([0-9]{8})\.([a-z]+)$/) {
        $primary = $dest;  
        $dest = "${dir}$file-$1.php";
        $primary =~ s!^(?:.*/)?([^./]+)\.php$!$1!;
    }

    open my $out, '>', "$outdir/$dest" or die "Unable to open $outdir/$dest";
    print $out "<?php\n";

    print $out "\$page_title = '$item->{title}';\n\n";

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
            my $t = exists $i->{index} ? $i->{index}->{title} : $i->{title};
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
        print $out qx(pandoc -f "$dialect" "$src");
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
 
    my $old_pat = "../$item->{src}";
    my $date_pat = "[0-9]" x 8;
    $old_pat =~ s/\.([a-z]+)$/-$date_pat\.$1/;
    foreach my $old (glob $old_pat) {
        $old =~ s!^\.\./!!;
        write_html_1( $file, $dir, { src => $old, title => $item->{title} }, 
                      $crumbs, $index );
    }
}

sub recurse {
    my ($desc, $dir, @crumbs) = @_;
    $dir //= '';

    if (exists $desc->{'index'}) {
        my $i = $desc->{'index'};
        write_html( 'index', $dir, $i, \@crumbs, $desc );
        push @crumbs, $i->{title};
    }

    foreach my $file (keys %$desc) {
        next if $file eq 'index';
        my $i = $desc->{$file};
        if ( exists $i->{index} ) { 
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
        my $t = exists $i->{index} ? $i->{index}->{title} : $i->{title}; 
        print $out "$indent*   [$t](/$path$key)\n";
        recurse_sitemap($out, "$indent    ", "$path$key/", $i) 
            if exists $i->{index};
    }   
}

sub recurse_parse_sitemap {
    my ($xml) = @_;

    my $dir = {
        'index' => { src   => $xml->findvalue('index/@src'), 
                     title => $xml->getAttribute('title') } 
    };

    foreach my $p ($xml->findnodes('page')) {
        $dir->{ $p->getAttribute('name') } ={
          src   => $p->getAttribute('src'), 
          title => $p->getAttribute('title')
        };
    }

    foreach my $p ($xml->findnodes('directory')) {
        my ($n, $v) = recurse_parse_sitemap($p);
        $dir->{$n} = $v;
    }

    return $xml->getAttribute('name') => $dir;
}

sub read_sitemap {
    my $dom = XML::LibXML->load_xml
        ( location => "$FindBin::Bin/../tsc-governance/sitemap.xml" );

    my (undef, $site) = recurse_parse_sitemap( $dom->documentElement );
    return $site;
}

my $site = read_sitemap();

mkdir $outdir unless -d $outdir;

open my $sitemap, '>', "$FindBin::Bin/sitemap.md" or die;
print $sitemap "# Site Map\n";
print $sitemap "<div class=\"sitemap\">\n";
print $sitemap "[$site->{index}->{title}](/)\n\n";
recurse_sitemap( $sitemap, '', '', $site );
print $sitemap "</div>\n";
close $sitemap;

write_html( 'sitemap', '', { src => 'website/sitemap.md', title => 'Site Map' },
            [ $site->{index}->{title} ], $site );

foreach my $f (@files) {
  copy $f, "$outdir/";
}
recurse $site;


