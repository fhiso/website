<?php
set_include_path('..');

include('include/utils.php');

function logout() {
  global $config;
  unset($_COOKIE['uid']); setcookie('uid', NULL, -1, '/');
  unset($_COOKIE['auth']); setcookie('auth', NULL, -1, '/');
}

logout();
do_redirect('');

