<?php
set_include_path('..');

include_once('include/database.php');
include_once('include/forms.php');
include_once('include/perms.php');

$page_title = 'Approve Account';

$ancestral_pages = [
  (object)[ 'url' => '../..', 'title' => 'Technical Work' ],
];

function content() {
  global $config;
  if (!user_logged_in()) return must_log_in();

  $groups = fetch_wol('*', 'group_membership JOIN groups ON group_id=groups.id',
                      array(field_eq_clause('user_id', user_logged_in()),
                            "code='tsc'"));
  if (count($groups) != 1) 
    $errors[] = 'Only TSC members can approve new accounts';

  if (!array_key_exists('id',$_GET))
    $errors[] = 'No user ID';

  if (count($errors) == 0) {
    $user = fetch_one_or_none('users', 'id', $_GET['id']);
    if (!$user)
      $errors[] = 'No such user';
    if (!$user->date_verified)
      $errors[] = 'User has not yet been verified';
    if ($user->date_approved)
      $errors[] = 'User has already been approved';
  }

  if (count($errors)) {
    page_header("Error approving account");
    show_error_list($errors);
    return;
  }

  if (!$user->date_approved)
    update_all( 'users', array(
      'date_approved' => date('Y-m-d H:i:s'),
      'approved_by' => user_logged_in()
    ), 'id', $user->id );

  $root = 'http://'.$config['domain'].$config['http_path'];

  $msg = <<<EOF
Dear $user->name,

Your FHISO technical account has been approved.  To log in, please use
the following link:

  http://tech.fhiso.org/account/login

--
Family History Information Standards Organisation, Inc.
Technical website:               http://tech.fhiso.org/
EOF;

  mail( sprintf('"%s" <%s>', $user->name, $user->email_address),
        "FHISO account approved", $msg, 'From: tsc@fhiso.org' )
    or die('Unable to send email');
  
  page_header("Account approved"); ?>

  <p>Thank you for approving <?php esc($user->name) ?>'s account.</p>

<?php }

include('include/template.php');

