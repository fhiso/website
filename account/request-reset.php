<?php
set_include_path('..');

include_once('include/database.php');
include_once('include/forms.php');
include_once('include/perms.php');

$page_title = 'Request Password Reset';

$ancestral_pages = [
  (object)[ 'url' => '..', 'title' => 'Technical Work' ],
];

function send_reset_email($email, $name, $token) {
  error_log("Sending reset token '$token' to <$email>");

  $msg  = <<<EOF
Dear $name,

Someone, hopefully you, has requested a reset of the password for your 
account on FHISO's technical site.  To reset it please visit:

  http://tech.fhiso.org/account/reset-password/$token

If you did not request this reset, there is no need to take any further 
action, and you will not receive further mail from us.

--
Family History Information Standards Organisation, Inc.
Technical website:               http://tech.fhiso.org/
EOF;

  mail( sprintf('"%s" <%s>', $name, $email), "FHISO password reset", $msg,
        'From: tsc@fhiso.org' )
    or die('Unable to send email');
}

function content() { 
  $errors = array();
  page_header('Request password reset');

  if (array_key_exists('reset',$_POST)) {
    if (!isset($_POST['email']) || !$_POST['email'])
      $errors[] = "Please enter an email address";
    else {
      $user = fetch_one_or_none('users', 'email_address', $_POST['email']);

      if (!$user)
        $errors[] = "Incorrect email address supplied";

      if (count($errors) == 0) {
        $token = make_random_token();
        update_all('users', array('activation_token' => $token),
                   'id', $user->id ); 
        send_reset_email($user->email_address, $user->name, $token); ?>
        <p>We have sent you an email containing a link allowing you to reset 
          your password.</p>
        <?php return;
      }
    }
  } ?>
    <p>If you have forgotten your password and need it resetting, please 
      enter your email address below and we will send you an email allowing 
      you to reset your password.</p>

    <?php show_error_list($errors); ?>
 
    <form method="post" action="" accept-charset="UTF-8">
      <div class="fieldrow">
        <?php text_field($_POST, 'email', 'Email address') ?>
      </div>

      <div class="fieldrow">
        <input type="submit" name="reset" value="Reset" />
      </div>
    </form>
<?php }

include('include/template.php');

