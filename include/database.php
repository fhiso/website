<?php

include_once('utils.php');

function db_connect() {
    global $dbh, $config;
    if ($dbh) return;

    $cfg = $config['database'];
    
    $dbh = mysql_connect( $cfg['hostname'], $cfg['username'], $cfg['password'] )
        or die('Could not connect to database: '. mysql_error() );
 
    mysql_select_db($cfg['database'], $dbh)
        or die('Could not select database');

    mysql_set_charset('utf8', $dbh)
        or die('Could not set database character set');
}

function exec_sql($sql) {
    global $dbh, $config;
    $cfg = $config['database'];
    if (array_key_exists('log_sql', $cfg) && $cfg['log_sql']) 
        error_log($sql);

    if (!$dbh) db_connect();
    $result = mysql_query($sql, $dbh);
    if (!$result) die('Cannot execute SQL: ' . mysql_error($dbh));
    return $result;
}

function insert_array_contents($table, $fields) {
    global $dbh;
    if (!$dbh) db_connect();

    # Generate both fields simultaneously, as it's not clear array_keys
    # is guaranteed to return in a consistent ordering (although empirically
    # it does seem to).
    $values = array(); $keys = array();
    foreach ( array_keys($fields) as $field ) {
        array_push( $keys, $field );
        array_push( $values, sprintf("'%s'", 
            mysql_real_escape_string($fields[$field], $dbh) ) );
    }

    $sql = 'INSERT INTO ' . $table . ' (' . join(', ', $keys) . ')'
         . ' VALUES (' . join(', ', $values) . ')';
    exec_sql($sql);
    return mysql_insert_id($dbh);
}

function fetch_objs_with_sql($sql) {
  $result = exec_sql($sql);

  $objs = array();
  while ($obj = mysql_fetch_object($result))
    array_push($objs, $obj);

  return $objs;
}

function join_as_sql($val, $sep) {
    if (is_array($val)) return join($sep, $val);
    else return $val;
}

function fetch_wghol($fields, $tables, $where, $groupby = null, $having = null,
                     $order = null, $limit = null, $offset = null) {
    if (!$fields) $sql = "SELECT *";
    else $sql = "SELECT ".join_as_sql($fields, ', ');

    if (!$tables) die('Missing table name');
    $sql .= " FROM ".join_as_sql($tables, ', ');

    if ($where) $sql .= " WHERE ".join_as_sql($where, ' AND ');
    if ($groupby) $sql .= " GROUP BY ".join_as_sql($groupby, ', ');
    if ($having) $sql .= " HAVING ".join_as_sql($having, ' AND ');
    if ($order) $sql .= " ORDER BY ".join_as_sql($order, ', ');

    if ($limit) {
        $sql .= sprintf(" LIMIT %d", $limit);
        if ($offset) $sql .= sprintf(" OFFSET %d", $offset);
    }

    return fetch_objs_with_sql($sql);
}

function field_eq_clause($key, $id) {
    global $dbh;
    if (!$dbh) db_connect();
    if ($key == null) return null;
    return sprintf("%s='%s'", $key, mysql_real_escape_string($id, $dbh));
}

function fetch_all($table, $key, $id, $order = null) {
    return fetch_wghol('*', $table, field_eq_clause($key, $id), 
                       null, null, $order);
}

function update_where($table, $fields, $where) {
    global $dbh;
    $sets = array();
    foreach ( array_keys($fields) as $field ) {
        if (isset($fields[$field]))
            array_push( $sets, field_eq_clause($field, $fields[$field]) );
        else 
            array_push( $sets, sprintf( "%s=NULL", $field) );
    }

    $sql = "UPDATE $table SET " . join(', ', $sets) . " WHERE $where";
    exec_sql($sql);
}

function update_all($table, $fields, $key, $id) {
  update_where($table, $fields, field_eq_clause($key, $id));
}

