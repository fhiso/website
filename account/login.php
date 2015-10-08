<?php
set_include_path('..');

include_once('include/database.php');
include_once('include/forms.php');
include_once('include/perms.php');

$page_title = 'Login';

$ancestral_pages = [
  (object)[ 'url' => '..', 'title' => 'Technical Work' ],
];

function set_login_cookie($uid, $expires) {
  global $config;
  setcookie( 'uid', $uid, $expires, '/' ); 
  setcookie( 'auth', crypt($uid . $config['auth']['secret']), $expires, '/' );
}  

function redirect_away() {
  if (array_key_exists('return', $_GET))
    do_redirect($_GET['return']);
  else
    do_redirect(''); # index.php
  exit;
}

# We do this before rendering the page so that we can update the menu
function do_login() {
  global $errors;  $errors = array();
  if (!array_key_exists('email', $_POST) || !$_POST['email'] ||
      !array_key_exists('password', $_POST) || !$_POST['password'])
    $errors[] = "Please provide both an email address and a password";

  if (count($errors)) return;

  $email = $_POST['email'];
  $password = $_POST['password'];

  error_log("Login attempt from <$email>");

  $users = fetch_all('users', 'email_address', $email);
  if (count($users) > 1) die('Multiple users with that address!');

  if (count($users) == 0) 
    $errors[] = 'Incorrect email address';
  
  elseif (crypt($password, $users[0]->password_crypt)
            != $users[0]->password_crypt) 
    $errors[] = 'Incorrect password';
  
  elseif (!$users[0]->date_verified) 
    $errors[] = 'Your account is not yet activated';
  
  elseif (!$users[0]->date_approved) 
    $errors[] = 'Your account is not yet approved';

  if (count($errors)) return;
   
  $forever = (array_key_exists('forever', $_POST) && $_POST['forever']);
  set_login_cookie( $uid = $users[0]->id, $forever ? 2147483647 : 0 );
  error_log("Login succeeded from <$email>");
  redirect_away();
}

function content() { 
  global $errors; ?>

  <h2>Login</h2>

  <p>If you have not yet registered for an account, you will need to
    <a href="register">register</a> before you can log in.
    If you have have forgotten your password, you can
    <a href="request-reset">reset it</a>.</p>

  <?php show_error_list($errors); ?>

    <form method="post" action="" accept-charset="UTF-8">
      <div class="fieldrow">
        <?php text_field($_POST, 'email', 'Email address') ?>
      </div>

      <div class="fieldrow">
        <div>
          <label for="password">Password</label>
          <input type="password" id="password" name="password" />
        </div>
      </div>

      <div class="fieldrow">
        <input type="checkbox" id="forever" name="forever" value="1"
               checked="checked" />
        <label for="forever">Stay logged in?
          <br/><span class="label-extra">If you are using a shared computer,
          you should not set this option.</span></label>
      </div>

      <div class="fieldrow">
        <input type="submit" name="login" value="Login" />
        <br/><span class="note">(This sets a cookie,
          which logging out clears.)</span>
      </div>
      <?php if (array_key_exists('return', $_GET))
        hidden_field('return', $_GET['return']);
      elseif (array_key_exists('return', $_POST))
        hidden_field('return', $_POST['return']);
      ?>
    </form>
<?php }

if (user_logged_in())
  redirect_away();
if (array_key_exists('login', $_POST)) 
  do_login();
include('include/template.php');
