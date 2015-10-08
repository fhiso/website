<?php
set_include_path('..');

include_once('include/database.php');
include_once('include/forms.php');
include_once('include/utils.php');
include_once('include/perms.php');

$page_title = 'Register';

$ancestral_pages = [
  (object)[ 'url' => '..', 'title' => 'Technical Work' ],
];

function validate_email_address($email) {
   # Based on http://www.linuxjournal.com/article/9585

   $atIndex = strrpos($email, "@");
   if (is_bool($atIndex) && !$atIndex) {
      return false;
   }
   else {
      $domain = substr($email, $atIndex+1);
      $local = substr($email, 0, $atIndex);
      $localLen = strlen($local);
      $domainLen = strlen($domain);

      if ($localLen < 1 || $localLen > 64)
         return false;
      
      else if ($domainLen < 1 || $domainLen > 255)
         return false;
      
      // Local part may not starts or ends with a dot
      else if ($local[0] == '.' || $local[$localLen-1] == '.')
         return false;
      
      // Local part may not contain two consecutive dots
      else if (preg_match('/\\.\\./', $local))
         return false;
     
      // Valid characters in domain are A-Z, a-z, 0-9, - and .
      else if (!preg_match('/^[A-Za-z0-9\\-\\.]+$/', $domain))
         return false;
      
      // Domain has two consecutive dots
      else if (preg_match('/\\.\\./', $domain))
        return false;
      
      else if (!preg_match('/^(\\\\.|[A-Za-z0-9!#%&`_=\\/$\'*+?^{}|~.-])+$/',
                 str_replace("\\\\","",$local))) {
         // XXX.  Not sure about this test.
         // Apparently "character not valid in local part unless 
         // local part is quoted"
         if (!preg_match('/^"(\\\\"|[^"])+"$/',
             str_replace("\\\\","",$local)))
           return false;
      }
      // Is the domain in DNS?
      if (!checkdnsrr($domain,"MX") && !checkdnsrr($domain,"A"))
         return false;
   }
   return true;
}

function send_activation_email($email, $name, $token, $uid) {
  error_log("Sending activation token '$token' to <$email> (uid: $uid)");

  $msg  = <<<EOF
Dear $name,

Thank you for registering with FHISO's technical website.

To activate your account, please follow the following link:

  http://tech.fhiso.org/account/activate/$token

If you did not request this account, there is no need to take any
further action, and you will not receive further mail from us.

--
Family History Information Standards Organisation, Inc.
Technical website:               http://tech.fhiso.org/
EOF;

  mail( sprintf('"%s" <%s>', $name, $email), "FHISO account activation", $msg,
        'From: tsc@fhiso.org' )
    or die('Unable to send email');
}

function content() {
  $errors = array();
  if (array_key_exists('register', $_POST)) {
    $name = $_POST['name'];
    $email = $_POST['email'];
    $password = $_POST['password'];
    $password2 = $_POST['password2'];

    if (!$name || !$email || !$password || !$password2) {
      $errors[] = "Please fill in all the fields";
    }
    if ($password && $password2 && $password != $password2) {
      $errors[] = "Passwords do not match";
      $_POST['password'] = ''; $_POST['password2'] = '';
    }
    if ($email && !validate_email_address($email)) {
      error_log("Invalid email address <$email> while registering");
      $errors[] = "Invalid email address";
    }
    if (count($errors) == 0 && 
        count(fetch_all('users', 'email_address', $email))) {
      $errors[] = "A user with this email address already exists";
    }

    if (count($errors) == 0) {
      $token = make_random_token();
      $data = array( 
        'name'             => $name,
        'email_address'    => $email,
        'password_crypt'   => crypt($password),
        'date_registered'  => date('Y-m-d H:i:s'),
        'activation_token' => $token
      );
      $uid = insert_array_contents('users', $data);
      send_activation_email($email, $name, $token, $uid); ?>

      <h2>Account registered</h2>

      <p>An email has just been sent to the email address you supplied.  This
        contains a link which you should follow to activate your account.</p>
      
      <?php 
        return;
    }
  }
  
  page_header('Register for an account');
  show_error_list($errors); ?>

    <form method="post" action="" accept-charset="UTF-8">
      <div class="fieldrow">
        <?php text_field($_POST, 'name', 'Name', 'publicly visible') ?>
      </div>

      <div class="fieldrow">
        <?php text_field($_POST, 'email', 'Email address') ?>
      </div>

      <div class="fieldrow">
        <div>
          <label for="password">Password</label>
          <input type="password" id="password" name="password" 
            value="<?php esc($_POST['password']) ?>" />
        </div>
        <div>
          <label for="password2">Confirm password</label>
          <input type="password" id="password2" name="password2" 
            value="<?php esc($_POST['password2']) ?>" />
        </div>
      </div>

      <div class="fieldrow">
        <input type="submit" name="register" value="Register" />
      </div>
    </form>
  <?php
}

include('include/template.php');

