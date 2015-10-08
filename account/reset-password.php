<?php
set_include_path('..');

include_once('include/database.php');
include_once('include/forms.php');
include_once('include/perms.php');

$page_title = 'Reset Password';

if (preg_match('/reset-password\/[0-9a-f]+$/', $_SERVER['REQUEST_URI']))
  $ancestral_pages = [
    (object)[ 'url' => '../..', 'title' => 'Technical Work' ],
  ];
else {
  $ancestral_pages = [
    (object)[ 'url' => '..', 'title' => 'Technical Work' ],
  ];
  if (user_logged_in())
    $ancestral_pages[] = (object)[ 'url' => '.', 'title' => 'Account' ];
}

function content() {
  $errors = array();

  if (user_logged_in())
    $uid = user_logged_in();

  else {
    if (!array_key_exists('token', $_GET) || !$_GET['token'])
      $errors[] = 'Invalid reset token';

    $token = $_GET['token'];

    $user = fetch_one_or_none('users', 'activation_token', $_GET['token']);
    if (count($user) != 1)
      $errors[] = 'Invalid reset token';

    if (count($errors)) {
      page_header('Reset failed');
      show_error_list($errors);
      return;
    }

    $uid = $user->id;
  }
  page_header('Reset password');

  if (array_key_exists('reset',$_POST)) {
    if (!isset($_POST['password']) || !isset($_POST['password2'])
        || !$_POST['password'])
      $errors[] = "Please provide a password";

    else {
      $password = $_POST['password'];
      $password2 = $_POST['password2'];
      if ($password != $password2)
        $errors[] = "Passwords do not match";

      else {
        update_all('users', array('password_crypt' => crypt($password),
                                  'activation_token' => null),
                   'id', $uid); ?>
        <p>Your password has been reset.<?php if (!user_logged_in()) { ?>
          You may now wish to <a href="/account/login">log in</a>.<?php } ?></p>
        <?php return;
      }
    }
    show_error_list($errors);
  } ?>

    <form method="post" action="" accept-charset="UTF-8">
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
        <input type="submit" name="reset" value="Reset" />
      </div>
    </form>
<?php
}

include('include/template.php');

