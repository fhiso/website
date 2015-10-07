<?php 

global $config;
$config = parse_ini_file('include/config.ini', true);

# Not sure to what extent this is necessary in PHP 5.6 ...
# After lots of experimentation, it seems that htmlentities() simply 
# doesn't do the right thing (at least in 5.3.3) with UTF-8.  Given 
# the name "Siân", for example, even with the 'UTF-8' third argument,
# it sees this as five bytes 53 69 C3 A2 6E, and escapes the fourth
# and fifth to give "Si&Atilde;&cent;n".
function esc($text) {
    print( htmlspecialchars($text, ENT_COMPAT, 'UTF-8') );
}
