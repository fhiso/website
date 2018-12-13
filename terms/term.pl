#!/usr/bin/perl

# This file contains the discovery implementation used on the 
# terms.fhiso.org domain.  It handles 303 redirects to HTML and PDF
# documentation and to machine-readable data in N-Triples, Turtle 
# or RDF/XML.  The latter are generated on the fly from two source 
# files written in Turtle.

use strict;
use warnings;

use List::Util qw/max/;
use RDF::Redland;
use HTTP::Status qw/status_message/;

my @source_files = qw{
  basic-concepts/basic-concepts.ttl
  sources-and-citations/citation-elements.ttl
};

sub error_code($) {
  my ($code) = @_;
  my $msg = status_message($code);
  print "Status: $code $msg\r\n\r\n";
  exit 0;
}

sub redirect_to($) {
  my ($url) = @_;
  my $msg = status_message(303);
  print "Status: 303 $msg\r\n"
      . "Location: $url\r\n"
      . "Vary: Accept\r\n\r\n";
  exit 0;
}

sub get_format_from_url($) {
  my ($url) = @_;
  if ($url =~ /\.(ttl|rdf|nt)$/) { return "$1" }
  return undef;
}

sub get_requested_format() {
  # Determine the preferred format.
  if ($ENV{HTTP_ACCEPT}) {
    my %types;
    foreach my $type (split /\s*,\s*/, $ENV{HTTP_ACCEPT}) {
      if ($type =~ s/\s*;\s*q=([01](?:\.[0-9]{0,3})?)\s*$//) {
        $types{$type} = 0+$1;
      } else {
        $types{$type} = 1;
      }
    }
  
    my $html = max( $types{'text/html'} // 0, 
                    $types{'application/xhtml+xml'} // 0 );
    my $pdf = $types{'application/pdf'} // 0;
    my $rdf = max( $types{'application/n-triples'} // 0, 
                   $types{'text/turtle'} // 0,
                   $types{'application/rdf+xml'} // 0 );
  
    if ($pdf > $html && $pdf > $rdf) { return "PDF" }
    elsif ($rdf > $html) {
      my $nt = $types{'application/n-triples'} // 0;
      my $ttl = $types{'text/turtle'} // 0;
      my $rdfx = $types{'application/rdf+xml'} // 0;
  
      if ($rdfx > $ttl && $rdfx > $nt) { return "RDF.rdf" }
      elsif ($ttl > $nt) { return "RDF.ttl" }
      else { return "RDF.nt" }
    }
    elsif ($html) { return "HTML" }
    else { return undef }
  }
  else { return "HTML" }
}

sub load_rdf_data() {
  my $model = new RDF::Redland::Model( 
    new RDF::Redland::Storage("hashes", "rdf", 
                              "new='yes',hash-type='memory'"), "" );
 
  foreach my $src (@source_files) {
    $model->load( new RDF::Redland::URI("file:///home/techsite/$src") );
  }

  return $model;
}

sub get_result_binding_iri($$) {
  my ($res, $n) = @_;
  if (!$res->finished) {
    my $defn = $res->binding_value($n);
    return $defn->uri->as_string if $defn;
  }
  return undef;
}

sub get_namespace_contents($$) {
  my ($model, $subj) = @_;

  $subj =~ s/[\/#?]$//;

  my $res = $model->query_execute( new RDF::Redland::Query(
    'CONSTRUCT { ?term a ?type } WHERE { ?term a ?type ' .
      'BIND( REPLACE( STR(?term), "^(.*)[/#?][^/#?]+$", "$1" ) AS ?ns ) ' .
      "FILTER( ?ns = \"$subj\" ) " .
    '}',
    undef, undef, "sparql") );

  return $res->as_stream;
}

sub is_namespace($$) {
  my ($model, $subj) = @_;
  my $ns = get_namespace_contents($model, $subj);
  return ($ns && !$ns->end);
}

sub get_definition_url($$) { 
  my ($model, $subj) = @_;

  my $res = $model->query_execute( new RDF::Redland::Query(
    "PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>\n" .
    "SELECT ?defn WHERE { <$subj> rdfs:isDefinedBy ?defn }",
     undef, undef, "sparql") );
  return get_result_binding_iri($res, 0);
}

sub get_object_type($$) { 
  my ($model, $subj) = @_;

  my $res = $model->query_execute( new RDF::Redland::Query(
    "SELECT ?type WHERE { <$subj> a ?type }",
     undef, undef, "sparql") );
  return get_result_binding_iri($res, 0);
}

sub handle_redirect($$) {
  my ($model, $url) = @_;

  my $fmt = get_requested_format(); 

  my $defn = get_definition_url($model, $url);
  if (not $defn and is_namespace($model, $url)) {
    if ($fmt =~ /^RDF\.(.*)$/) {
      my $ext = $1;
      $url =~ s/[\/#?]$//;
      redirect_to("$url.$ext");
    } else {
      error_code(406);
    }
  }

  error_code(404) if not defined $defn;
  
  if ($fmt eq 'HTML') {
    redirect_to($defn);
  }
  elsif ($fmt eq 'PDF') {
    my $pdf = $defn;  $pdf =~ s/#.*$//;  $pdf .= '.pdf';
    redirect_to($pdf);
  }
  elsif ($fmt =~ /^RDF\.(.*)$/) {
    redirect_to("$url.$1");
  }
  else {
    error_code(500);
  }
}

sub get_rdf_stream($$) {
  my ($model, $pattern) = @_;

  my $sparql = "CONSTRUCT { $pattern } WHERE { $pattern }";
  my $query = new RDF::Redland::Query($sparql, undef, undef, "sparql") or die;
  my $res = $model->query_execute($query) or die;

  return $res->as_stream;
}

sub get_rdf_properties($$) {
  my ($model, $subj) = @_; 
  return get_rdf_stream($model, "<$subj> ?p ?o");
}

sub get_rdf_objects_of_type($$) {
  my ($model, $type) = @_; 
  return get_rdf_stream($model, "?s a <$type>");
}

my $model = load_rdf_data();

my $url = "https://terms.fhiso.org$ENV{REQUEST_URI}";

my $fmt = get_format_from_url($url);
handle_redirect($model, $url) if not defined $fmt;
$url =~ s/\.$fmt$//;

my $output = new RDF::Redland::Model( 
  new RDF::Redland::Storage("memory"), "" ) or die;
$output->add_statements( get_rdf_properties($model, $url) );

my $type = get_object_type($model, $url);
if (not defined $type) {
  my $ns = get_namespace_contents($model, $url);
  $output->add_statements($ns);
}
elsif ($type eq 'http://www.w3.org/2000/01/rdf-schema#Class') {
  $output->add_statements( get_rdf_objects_of_type($model, $url) );
}

print "Status: 200 Okay\r\n"
    . "Content-Type: application/n-triples\r\n\r\n";

my $serializer = new RDF::Redland::Serializer
  ( $fmt eq 'rdf' ? 'rdfxml' : $fmt eq 'ttl' ? 'turtle' : 'ntriples' );
print $serializer->serialize_model_to_string(undef, $output);



