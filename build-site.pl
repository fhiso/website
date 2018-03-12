#!/usr/bin/perl

use strict;
use warnings;

use Perl6::Slurp;
use File::Copy;
use File::Touch;
use File::Basename;
use File::Temp;
use FindBin;
use POSIX qw/strftime/;
use XML::LibXML;
use Cwd;

my $outdir = '../www-build';
my $uploaddir = '../www-upload';
my $urlbase = 'http://tech.fhiso.org/';

my $verbose = grep { $_ eq '-v' || $_ eq '--verbose' } @ARGV;

sub page_title($) { 
    my ($i) = @_;
    return exists $i->{index} ? $i->{index}->{title} : $i->{title};
}

sub write_link {
    my ($file, $dir, $item) = @_;

    my $dest = $item->{dest};
    $dest =~ s!^http://(fhiso.org)/!%{ENV:scheme}://$1/!;
    open my $out, '>>', "$outdir/.redirects" or die "Unable to open .redirects";
    print $out "RewriteRule ^$dir$file((-\\d{8})?(\\.\\w+)??)(\\.php)?\$ \\\n";
    print $out "\t$dest\$1 \\\n";
    print $out "\t[L,R=301,E=limitcache:1]\n";
    close $out;
}

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

    my $title = $item->{title}; $title =~ s/'/\\'/g;
    print $out "\$page_title = '$title';\n\n";

    my $root;
    print $out "\$ancestral_pages = [\n";
    for my $i (0 .. $#$crumbs) {
        if (@$crumbs) {
            my $t = $crumbs->[$i]; $t =~ s/'/\\'/g;
            my $depth = $#$crumbs-$i;  
            $depth++ if $dest =~ m!/index\.php$!;
            my $url = join( '/', ('..') x $depth ) || '.';
            print $out "  (object)[ 'url' => '$url', 'title' => '$t' ],\n"
                if $t;
            $root = $url unless defined $root;
        }
    }
    print $out "];\n\n";
    
    if ($index) { 
        print $out "\$child_pages = [\n";
        foreach my $key (sort { $a eq $b ? 0 :
                                $a eq 'index' ? -1 :
                                $b eq 'index' ? +1 : 
                                lc(page_title($index->{$a})) 
                                  cmp lc(page_title($index->{$b})) }
                         grep { exists $index->{$_}->{index} 
                                    ? not $index->{$_}->{index}->{unlinked}
                                    : not $index->{$_}->{unlinked} }
                              keys %$index) {
            my $i = $index->{$key};
            my $t = page_title($i); $t =~ s/'/\\'/g;
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

    my $phpxtra = '';
    if ($src =~ m!^(\.\./[^/]+)/(.*)\.md$!) {
        my $path = $1;
        my $html = "$2.html";

        my $md = slurp $src or die;
        if ($md =~ /^numbersections:\s*true$/m) {
            $phpxtra = "\$docclass = 'numbersections';\n"; 
        } else {
            $phpxtra = "\$docclass = '';\n"; 
        }

        my @make = ('make'); 
        push @make, '-s' unless $verbose; 
        system @make, '-C', $path, $html and die;
        print $out qx(cat "$path/$html");
        unlink "$path/$html";
    }
    elsif ($src =~ /\.(html|php)$/) {
        print $out qx(cat "$src");
    }
    else { 
        die "Unknown file extension"; 
    }

    print $out "<?php }\n\n";

    print $out $phpxtra;
    my $template = $dir =~ m!^TR/! ? 'trtemplate.php' : 'template.php';
    print $out "include('include/$template');\n";
    exit 1 if $?;
    close $out;
}

sub write_pdf {
    my ($src, $dest, $upload) = @_;

    $src =~ m!^([^/]+)/(.*)\.md$!;
    my $path = $1;
    my $pdf = "$2.pdf";
    my @make = ('make'); 
    push @make, '-s' unless $verbose; 
    system @make, '-C', "../$path", $pdf and die;

    if ($src =~ /-([0-9]{8})\.([a-z]+)$/) { 
      my $filedate = $1;
      # We don't want to overwrite old PDFs
      my $yesterday = strftime '%Y%m%d', gmtime(time() - 3600*24);
      return if $filedate < $yesterday;
      $dest .= "-$filedate"; 
    }
    $dest .= '.pdf';

    system "cp -p \"../$path/$pdf\" \"$outdir/$dest\"";
    if ($upload) {
      (my $dest2 = $dest) =~ s!.*/!!;
      touch "$uploaddir/$dest2";
    }
}

sub write_html {
    my ($file, $dir, $item, $crumbs, $index) = @_;
    write_html_1($file, $dir, $item, $crumbs, $index);

    if ($item->{versioned}) {
        if ($item->{releases}) {
            my $dir = '../' . dirname $item->{src};
            my ($base, $ext) = basename($item->{src}) =~ /(.*)\.([a-z]+)$/
                or die "Unexpected filename: $item->{src}";
            foreach my $rel (split /\s+/, $item->{releases}) {
                my $tmp = tmpnam($dir, 'rel');
                my ($dest, $branch);
                if ($rel =~ /^\d+$/) {
                    $dest = "$base-$rel.$ext";
                    $branch = "origin/releases-$rel";
                } else {
                    $dest = "$base-dev.$ext";
                    $branch = "origin/$rel";
                }
                system("cd '$dir'; "
                       . "git show '$branch':'$base.$ext' > '$tmp'; "
                       . "if test \\! -e '$dest' || ! cmp -s '$tmp' '$dest'; "
                       . "then mv '$tmp' '$dest'; else "
                       . "rm '$tmp'; "
                       . "fi");
            }
        }

        my $old_pat = "../$item->{src}";
        my $date_pat = "[0-9]" x 8;   $date_pat = "{$date_pat,dev}";
        $old_pat =~ s/\.([a-z]+)$/-$date_pat\.$1/;
        foreach my $old (glob $old_pat) {
            next unless -e $old;
            $old =~ s!^\.\./!!;
            write_html_1( $file, $dir, 
                          { src => $old, title => $item->{title} }, 
                          $crumbs, $index );
            write_pdf($old, $dir.$file, $item->{upload});
        }

        write_pdf($item->{src}, $dir.$file, $item->{upload});
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
        elsif ( $i->{link} ) {
            write_link( $file, $dir, $i );
        }
        else { 
            write_html( $file, $dir, $i, \@crumbs, $desc );
        }
    }
}

sub recurse_public_sitemap {
    my ($mdout, $xmlout, $indent, $path, $desc) = @_;
    foreach my $key (sort { lc(page_title($desc->{$a})) 
                              cmp lc(page_title($desc->{$b})) } 
                     grep { not $desc->{$_}->{unlinked} }
                     keys %$desc) {
        next if $key eq 'index';
        my $i = $desc->{$key};
        my $t = page_title($i);
        $key .= '/' if exists $i->{index};
        print $mdout "$indent*   [$t](/$path$key)\n";
        print $xmlout "  <url>\n    <loc>$urlbase$path$key</loc>\n  </url>\n";
        recurse_public_sitemap($mdout, $xmlout, "$indent    ", "$path$key", $i) 
            if exists $i->{index};
    }   
}

sub recurse_parse_sitemap {
    my ($xml) = @_;

    my $dir = {
        'index' => { src   => $xml->findvalue('index/@src'), 
                     title => $xml->getAttribute('title') } 
    };
    $dir->{index}->{unlinked} = 1 if $xml->getAttribute('unlinked');

    foreach my $p ($xml->findnodes('page | link')) {
        my $desc = { title => $p->getAttribute('title') };

        foreach (qw/src dest releases/) {
          if (my $val = $p->getAttribute($_)) { $desc->{$_} = $val; }
        }

        # Boolean attributes
        foreach (qw/unlinked versioned upload/) {
            $desc->{$_} = 1 if $p->getAttribute($_);
        }
        if ($p->nodeName eq 'link') { $desc->{link} = 1; }
            
        $dir->{ $p->getAttribute('name') } = $desc
    }

    foreach my $p ($xml->findnodes('directory')) {
        my ($n, $v) = recurse_parse_sitemap($p);
        $dir->{$n} = $v;
    }

    return $xml->getAttribute('name') => $dir;
}

sub read_sitemap {
    my ($xmlfile) = @_;
    my $dom = XML::LibXML->load_xml( location => $xmlfile );

    my (undef, $site) = recurse_parse_sitemap( $dom->documentElement );
    return $site;
}

sub generate_public_sitemap($) {
    my ($site) = @_;

    open my $sitemapxml, '>', "$outdir/sitemap.xml" or die;
    print $sitemapxml <<EOF;
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
EOF

    open my $sitemap, '>', "$FindBin::Bin/sitemap.md" or die;
    print $sitemap "# Site Map\n";
    print $sitemap "<div class=\"sitemap\">\n";
    print $sitemap "[$site->{index}->{title}](/)\n\n";
    
    recurse_public_sitemap( $sitemap, $sitemapxml, '', '', $site );
    
    print $sitemap "</div>\n";
    close $sitemap;
    
    print $sitemapxml "</urlset>\n";
    close $sitemapxml;
    
    write_html( 'sitemap', '', { src => 'website/sitemap.md', 
                                 title => 'Site Map' },
                [ $site->{index}->{title} ], $site );
}


chdir "$FindBin::Bin";

mkdir $outdir unless -d $outdir;

my $site = read_sitemap( "../tsc-governance/sitemap.xml" );
generate_public_sitemap $site;

# Build the actual site
recurse $site;

# Unlinked site, but not especially secret (or it wouldn't be in Github!)
mkdir "$outdir/board" unless -d "$outdir/board";
recurse read_sitemap( "../tsc-governance/board/sitemap.xml" ), 'board/', '';
