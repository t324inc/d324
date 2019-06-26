<?php

require __DIR__ . '/../vendor/autoload.php';

// Make it a plain text file
header('Content-Type:text/plain');

if(getenv('STAGING_ROBOTS_TXT') === '1') {
  // Output staging robots.txt
  ?>
# This is the staging robots.txt file.  Turn this off in your .env file when the site is live
User-agent: *
Disallow: /
  <?php
}
else {
  // Output live robots.txt
  echo file_get_contents( "robots.txt" );
}
?>
