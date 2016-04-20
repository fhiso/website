<?php

include_once('include/utils.php');
include_once('include/perms.php');

header('Content-Type: text/html; charset=utf-8');

$path = preg_split( '/\//', 
                    preg_replace('/\.php$/', '', $_SERVER['PHP_SELF']) );
$vers = glob( preg_replace( '/(?:-[0-9]{8})$/', '', 
                            $path[count($path)-1] )
              . '-' . str_repeat('[0-9]', 8) . '.php' );

$pdf = glob( $path[count($path)-1].".pdf" );
if (count($pdf) == 1) $pdf = $pdf[0]; else $pdf = null;

if ($pdf) header("Link: <$pdf>; rel=alternate; type=application/pdf")

?><!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml" lang="en" xml:lang="en">
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    <meta http-equiv="Content-Style-Type" content="text/css" />
    <meta name="author" 
          content="Family History Information Standards Organisation, Inc." />
    <title><?php esc($page_title) ?></title>
    <link rel="stylesheet" href="/fhiso.css" type="text/css" />
    <?php if ($pdf) { ?><link rel="alternate" href="<?php esc($pdf) 
      ?>" type="application/pdf" /><?php } ?>
    <?php if (function_exists('header_content')) header_content() ?>
  </head>
  <body>
    <div class="header">
      <?php if ($_SERVER['SERVER_NAME'] == 'test.tech.fhiso.org') { ?>
      <div class="right" style="border: 2px solid red"
        ><a href="/" style="color: red">Testing<br/>Site</a></div>
      <?php } else { ?>
      <div class="right"><a href="/">Technical<br/>Site</a></div>
      <?php } ?>
      <div class="logo"><a href="http://fhiso.org/"><img src="/fhiso.png" 
           alt="Family History Information Standards Organisation" /></a></div>
    </div>
    <div class="navbar menu1">
      <?php global $ancestral_pages, $page_title; ?>
      <a class="navitem" href="http://fhiso.org/">Home</a>
      <?php foreach ($ancestral_pages as $a) { ?>
      <span class="sep">/</span>
      <a class="navitem" href="<?php esc($a->url) ?>"><?php esc($a->title) 
        ?></a>
      <?php } ?>
      <span class="sep">/</span>
      <span class="navitem active"><?php esc($page_title); ?></span>
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
      <?php if (user_logged_in()) { ?>
      <a href="/account/logout">Log out</a>
      <a href="/account">Account</a>
      <?php } else { ?>
      <a href="/account/register">Register</a>
      <a href="/account/login">Log in</a>
      <?php } ?>
    </div>
    <?php 

    if (isset($child_pages) && count($child_pages) || count($vers) || $pdf) { ?>
    <div class="right">
      <?php if (isset($child_pages) && count($child_pages)) { ?>
        <h2>Related Links</h2>
        <ul class="related">
          <?php foreach ($child_pages as $c) { ?>
            <li<?php if ($c->url == 'index') { ?> class="index" <?php } 
              ?>><?php if ($c->url != $path[count($path)-1]) { 
              ?><a href="<?php esc($c->url) ?>"><?php } esc($c->title);
              if ($c->url != $path[count($path)-1]) { ?></a><?php } ?></li>
          <?php } ?>
        </ul>
      <?php } ?>
      <?php if (count($vers)) { ?>
      <h2>Versions</h2>
      <ul class="related">
        <?php $v = preg_replace( '/(?:-[0-9]{8})$/', '',
                                 $path[count($path)-1] ); ?>
          <li><?php if ($v != $path[count($path)-1]) { ?><a href="<?php 
            esc($v) ?>"><?php } ?>Latest<?php
            if ($v != $path[count($path)-1]) { ?></a><?php } ?></li>
        <?php foreach (array_reverse($vers) as $v) { 
          $v = preg_replace('/\.php$/', '', $v); ?>
          <li><?php if ($v != $path[count($path)-1]) { ?><a href="<?php 
            esc($v) ?>"><?php }
            esc(preg_replace('/^.*([0-9]{4})([0-9]{2})([0-9]{2})$/', 
                             '$1-$2-$3', $v));
            if ($v != $path[count($path)-1]) { ?></a><?php } ?></li>
        <?php } ?>
      </ul> 
      <?php } ?>
      <?php if ($pdf) { ?>
      <h2>Download</h2>
      <ul class="related">
        <li><a href="<?php esc($pdf) ?>">as PDF <img src="/pdf.png"/></a></li>
      </ul>
      <?php } ?>
    </div>
    <?php } ?>
    <div class="content">
      <?php content(); ?>
    </div>
    <div class="footer">
      Copyright © 2012&ndash;<?php esc(date('Y')) ?>,
      <a href="http://fhiso.org/">Family History
      Information Standards Organisation, Inc</a>.<br/>
      Hosting generously donated by 
      <a href="http://www.mythic-beasts.com/">Mythic Beasts, Ltd</a>.
    </div>
  </body>
</html>
 
