<?php

$site = 'https://fhiso.org';
$page_name = 'bylaws';

# This file must contain an application password 
#   https://en-gb.wordpress.org/plugins/application-passwords/
# in the form  
#   Username:Password
# For obvious reasons we don't want this password adding to git.
$password = file_get_contents(dirname(__FILE__)."/.wp-app-password");
if ($password === FALSE) die("Unable to read .wp-app-password");
$password = base64_encode(trim($password));
$headers = array("Authorization: Basic $password");


# Find the relevant page id.
$url = $site.'/wp-json/wp/v2/pages?slug='.urlencode($page_name);

$ch = curl_init($url);
curl_setopt($ch, CURLOPT_CUSTOMREQUEST, "GET");
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);

$result = json_decode(curl_exec($ch));
if (count($result) != 1) die("Multiple pages match");
$page_id = $result[0]->id;

$url = "$site/wp-json/wp/v2/pages/$page_id";

#$ch = curl_init($url);
#curl_setopt($ch, CURLOPT_CUSTOMREQUEST, "GET");
#curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
#curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
#
#$result = json_decode(curl_exec($ch));
#print $result->content->rendered."\n";

$data = array( 'content' => '<p>Also available as a <a href="/files/governance/by-laws.pdf">PDF</a><img src="/pdf.png" style="vertical-align: bottom; padding: 0"/></p>'."\n" );

while ($line = fgets(STDIN)) {
  if (preg_match('/^<h1>(.*)<\/h1>\s*$/', $line, $matches))
    $data['title'] = $matches[1];
  else 
    $data['content'] .= $line;
}

#print $data['content']."\n";
#exit(0);

$datastr = json_encode($data);
$headers[] = 'Content-Type: application/json';
$headers[] = 'Content-Length: ' . strlen($datastr);

$ch = curl_init($url);
curl_setopt($ch, CURLOPT_CUSTOMREQUEST, "POST");
curl_setopt($ch, CURLOPT_POSTFIELDS, $datastr);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);

$result = curl_exec($ch);
#echo $result;
