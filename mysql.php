#!/usr/bin/php
<?php
set_include_path(dirname(__FILE__));
include_once('include/utils.php');

$cfg = $config['database'];

pcntl_exec('/usr/bin/mysql', array( $cfg['database'],
  '-u'.$cfg['username'], '-p'.$cfg['password'], '-h'.$cfg['hostname'] ));

