<?php

$config['system.logging']['error_level'] = 'verbose';
$config['system.performance']['css']['preprocess'] = FALSE;
$config['system.performance']['js']['preprocess'] = FALSE;
$settings['cache']['bins']['render'] = 'cache.backend.null';
$settings['cache']['bins']['page'] = 'cache.backend.null';
$settings['cache']['bins']['dynamic_page_cache'] = 'cache.backend.null';
$settings['skip_permissions_hardening'] = TRUE;

// Change kint maxLevels setting:
if(file_exists($app_root . '/modules/contrib/devel/kint/kint/Kint.class.php')) {
  include_once($app_root . '/modules/contrib/devel/kint/kint/Kint.class.php');
  if(class_exists('Kint')){
    // Set the maxlevels to prevent out-of-memory. Currently there doesn't seem to be a cleaner way to set this:
    Kint::$maxLevels = 5;
  }
}
