<?php

include_once('include/utils.php');

function param_value($params, $name) {
  if (preg_match('/^([^\[\]]+)\[(.*)\]$/', $name, $matches)) {
    return isset( $params[ $matches[1] ] ) && 
           isset( $params[ $matches[1] ][ $matches[2] ] )
      ? $params[ $matches[1] ][ $matches[2] ] : null;
  } else {
    return isset($params[$name]) ? $params[$name] : null;
  }
}

function print_attrs($attrs) {
  if ($attrs)
    foreach (array_keys($attrs) as $a) {
      esc($a); echo '="'; esc($attrs[$a]); echo '" ';
    }
}

function field_name_to_id($name) {
  # The ID cannot be the same as the name as the former cannot contain []
  if (preg_match('/^([^\[\]]+)\[(.*)\]$/', $name, $matches)) {
    return $matches[1] . '.' . $matches[2];
  } else {
    return $name;
  }
}

function text_field($params, $name, $label = null, $label2 = null,
                    $attrs = null) {
        
  $val = param_value($params, $name);
  $id = field_name_to_id($name);
?>          
        <div class="field">
          <?php if ($label) { ?>
          <label for="<?php esc($id) ?>">
            <?php esc($label); if ($label2) { ?>
              <span class="label-extra">(<?php esc($label2) ?>)</span>
            <?php } ?>
          </label>
          <?php } ?>
          <input type="text" id="<?php esc($id) ?>"
             name="<?php esc($name) ?>" value="<?php esc($val) ?>" <?php
             print_attrs($attrs) ?> />
        </div>
<?php }

function show_error_list($errors) {
  if (count($errors)) { ?>
      <div>
        <?php foreach ($errors as $e) { ?>
          <p class="error"><?php esc($e) ?></p>
        <?php } ?>
      </div>
  <?php }
}

function hidden_field($name, $val) { ?>
        <input type="hidden" 
               name="<?php esc($name)?>" value="<?php esc($val)?>" />
<?php } ?>


