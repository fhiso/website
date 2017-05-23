#!/usr/bin/php
<?php

set_include_path(dirname(__FILE__).'/../include');
include_once('database.php');

function fetch_types() {
    global $dbh;
    if (!$dbh) db_connect();

    $result = mysqli_query($dbh, "SELECT * FROM cfps_types")
      or die('Cannot execute SELECT: ' . mysqli_error($dbh));

    $objs = array();
    while ($obj = mysqli_fetch_object($result))
        $objs[ $obj->name ] = $obj;
    return $objs;
}

$json = file_get_contents( dirname(__FILE__).'/masterlist.json' )
    or die('Cannot not read JSON');
$data = json_decode($json, true)
    or die('Unable to parse JSON');

$types = fetch_types();

foreach (array_keys($data) as $id) {
    # Get shared details from the first version
    $o = $data[$id]['versions'][0];

    $cfps = array(
        'id'              => $id,
        'given_name'      => $o['first'],
        'surname'         => $o['last'],
        'email'           => $o['email'],
        'submission_type' => $types[$o['type']]->id,
        'date_created'    => $o['date'],
    );
    insert_array_contents('cfps', $cfps);

    if ($o['type'] == 'Comment')
        insert_array_contents('cfps_references', array(
            'cfps_id'            => $id,
            'references_id'      => $o['cfps'],
            'is_primary_subject' => true ));

    $latest_version = 0;

    foreach ($data[$id]['versions'] as $v) {
        $version = array(
            'id'              => $id,
            'cfps_id'         => $id,
            'version_created' => $v['date'],
            'title'           => $v['title'],
            'language'        => $v['language'],
            'description'     => $v['description'],
            'keywords'        => $v['keywords'],
            'version'         => $v['version']
        );

        if (array_key_exists('changes', $v))
            $version['changelog'] = $v['changes'];
        
        if (array_key_exists('subnum', $v))
            $version['id'] = $v['subnum'];

        insert_array_contents('papers', $version);

        if ($version['id'] > $latest_version)
            $latest_version = $version['id'];
    }

    update_all( 'cfps', array('latest_version' => $latest_version), 'id', $id );
}

foreach (array_keys($data) as $id) {
    foreach ($data[$id]['seealso'] as $a) 
        if ($a < $id)
            insert_array_contents('cfps_references', array(
                'cfps_id'            => $id,
                'references_id'      => $a ));
}
