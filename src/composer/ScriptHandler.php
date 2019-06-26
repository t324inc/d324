<?php

namespace D324\composer;

use Composer\Semver\Comparator;
use Symfony\Component\Filesystem\Filesystem;
use Composer\EventDispatcher\Event;

/**
 * D324 Composer Script Handler.
 */
class ScriptHandler {

  /**
   * Get the Drupal root directory.
   *
   * @param string $project_root
   *    Project root.
   *
   * @return string
   *    Drupal root path.
   */
  protected static function getDrupalRoot($project_root) {
    return $project_root . '/web';
  }

  /**
   * Create required files.
   *
   * @param Event $event
   *   Event of creeate required files.
   */
  public static function createRequiredFiles(Event $event) {

    $fs = new Filesystem();
    $drupal_root = static::getDrupalRoot(getcwd());

    $dirs = [
      'modules',
      'profiles',
      'themes',
      'libraries',
      '../patches'
    ];

    // Required for unit testing.
    foreach ($dirs as $dir) {
      if (!$fs->exists($drupal_root . '/' . $dir)) {
        $fs->mkdir($drupal_root . '/' . $dir);
        $fs->touch($drupal_root . '/' . $dir . '/.gitkeep');
      }
    }

    // Prepare the settings file for installation.
    if (!$fs->exists($drupal_root . '/sites/default/settings.php') and $fs->exists($drupal_root . '/sites/default/default.settings.php')) {
      $fs->copy($drupal_root . '/sites/default/default.settings.php', $drupal_root . '/sites/default/settings.php');
      $fs->chmod($drupal_root . '/sites/default/settings.php', 0666);
      $event->getIO()->write("Create a sites/default/settings.php file with chmod 0666");
      // Alter settings.php file.
      $settings = fopen($drupal_root . '/sites/default/settings.php', 'a+');
      $settings_extra = file_get_contents($drupal_root . '/profiles/d324/src/assets/settings_extra');
      fwrite($settings, $settings_extra);
      fclose($settings);
    }

    // Prepare the services file for installation.
    if (!$fs->exists($drupal_root . '/sites/default/services.yml') and $fs->exists($drupal_root . '/sites/default/default.services.yml')) {
      $fs->copy($drupal_root . '/sites/default/default.services.yml', $drupal_root . '/sites/default/services.yml');
      $fs->chmod($drupal_root . '/sites/default/services.yml', 0666);
      $event->getIO()->write("Create a sites/default/services.yml file with chmod 0666");
    }

    $drupal_public = getenv('DRUPAL_PUBLIC') ? getenv('DRUPAL_PUBLIC') : 'sites/default/files';
    if ($drupal_public && !$fs->exists($drupal_root . '/' . $drupal_public)) {
      $oldmask = umask(0);
      $fs->mkdir($drupal_root . '/' . $drupal_public, 0777);
      $fs->touch($drupal_root . '/'. $drupal_public . '/.gitkeep');
      umask($oldmask);
      $event->getIO()->write("Created a " . $drupal_public . " directory with chmod 0777");
    }

    $drupal_private = getenv('DRUPAL_PRIVATE') ? getenv('DRUPAL_PRIVATE') : '../private';
    if ($drupal_private && !$fs->exists($drupal_root . '/' . $drupal_private)) {
      $oldmask = umask(0);
      $fs->mkdir($drupal_root . '/' . $drupal_private, 0775);
      $fs->touch($drupal_root . '/'. $drupal_private . '/.gitkeep');
      umask($oldmask);
      $event->getIO()->write("Created a " . $drupal_private . " directory with chmod 0775");
    }

    $drupal_temp = getenv('DRUPAL_TEMP') ? getenv('DRUPAL_TEMP') : '../tmp';
    if ($drupal_temp && !$fs->exists($drupal_root . '/' . $drupal_temp)) {
      $oldmask = umask(0);
      $fs->mkdir($drupal_root . '/' . $drupal_temp, 0777);
      $fs->touch($drupal_root . '/'. $drupal_temp . '/.gitkeep');
      umask($oldmask);
      $event->getIO()->write("Created a " . $drupal_temp . " directory with chmod 0777");
    }
  }

  /**
   * Checks if the installed version of Composer is compatible.
   *
   * Composer 1.0.0 and higher consider a `composer install` without having a
   * lock file present as equal to `composer update`. We do not ship with a lock
   * file to avoid merge conflicts downstream, meaning that if a project is
   * installed with an older version of Composer the scaffolding of Drupal will
   * not be triggered. We check this here instead of in drupal-scaffold to be
   * able to give immediate feedback to the end user, rather than failing the
   * installation after going through the lengthy process of compiling and
   * downloading the Composer dependencies.
   *
   * @see https://github.com/composer/composer/pull/5035
   */
  public static function checkComposerVersion(Event $event) {
    $composer = $event->getComposer();
    $io = $event->getIO();
    $version = $composer::VERSION;
    // The dev-channel of composer uses the git revision as version number,
    // try to the branch alias instead.
    if (preg_match('/^[0-9a-f]{40}$/i', $version)) {
      $version = $composer::BRANCH_ALIAS_VERSION;
    }
    // If Composer is installed through git we have no easy way to determine if
    // it is new enough, just display a warning.
    if ($version === '@package_version@' || $version === '@package_branch_alias_version@') {
      $io->writeError('<warning>You are running a development version of Composer. If you experience problems, please update Composer to the latest stable version.</warning>');
    }
    elseif (Comparator::lessThan($version, '1.0.0')) {
      $io->writeError('<error>Drupal-project requires Composer version 1.0.0 or higher. Please update your Composer before continuing</error>.');
      exit(1);
    }
  }

  /**
   * Remove .git folder from modules, themes, profiles of development branches.
   */
  public static function removeGitDirectories() {
    if(getenv('REMOVE_ALL_GIT')) {
      $drupal_root = static::getDrupalRoot(getcwd());
      exec("find " . $drupal_root . " -name '.git' | xargs rm -rf");
    }
  }

  /**
   * Post Drupal Scaffold Procedure.
   *
   * @param \Composer\EventDispatcher\Event $event
   *   The script event.
   */
  public static function postDrupalScaffoldProcedure(Event $event) {

    $fs = new Filesystem();
    $drupal_root = static::getDrupalRoot(getcwd());

    if ($fs->exists($drupal_root . '/profiles/d324/src/assets/robots.php')) {
      // Create staging robots file.
      copy($drupal_root . '/profiles/d324/src/assets/robots.php', $drupal_root . '/robots.php');
    }

    if ($fs->exists($drupal_root . '/profiles/d324/src/assets/dev.services.yml')) {
      // Create Dev Services File
      copy($drupal_root . '/profiles/d324/src/assets/dev.services.yml', $drupal_root . '/sites/default/dev.services.yml');
    }

    if ($fs->exists($drupal_root . '/profiles/d324/src/assets/dev.settings.php')) {
      // Create Dev Settings File
      copy($drupal_root . '/profiles/d324/src/assets/dev.settings.php', $drupal_root . '/sites/default/dev.settings.php');
    }

    if ($fs->exists($drupal_root . '/profiles/d324/src/assets/dev.services.yml')) {
      // Create Dev Services File
      copy($drupal_root . '/profiles/d324/src/assets/dev.services.yml', $drupal_root . '/sites/default/dev.services.yml');
    }

    if ($fs->exists($drupal_root . '/profiles/d324/src/assets/theme_debug.disable.services.yml')) {
      // Create Theme Debug Override Disable File
      copy($drupal_root . '/profiles/d324/src/assets/theme_debug.disable.services.yml', $drupal_root . '/sites/default/theme_debug.disable.services.yml');
    }

    if ($fs->exists($drupal_root . '/profiles/d324/src/assets/theme_debug.enable.services.yml')) {
      // Create Theme Debug Override Enable File
      copy($drupal_root . '/profiles/d324/src/assets/theme_debug.enable.services.yml', $drupal_root . '/sites/default/theme_debug.enable.services.yml');
    }

    if ($fs->exists($drupal_root . '/.htaccess')
      && $fs->exists($drupal_root . '/profiles/d324/src/assets/htaccess_extra')) {

      // Alter .htaccess file.
      $htaccess_path = $drupal_root . '/.htaccess';
      $htaccess_lines = file($htaccess_path);
      $lines = [];
      foreach ($htaccess_lines as $line) {
        $lines[] = $line;
        if (strpos($line, "RewriteEngine on") !== FALSE) {
          $lines = array_merge($lines, file($drupal_root . '/profiles/d324/src/assets/htaccess_extra'));
        }
      }
      file_put_contents($htaccess_path, $lines);
    }
  }
}
