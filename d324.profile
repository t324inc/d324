<?php

/**
 * @file
 * Enables modules and site configuration for a D324 site installation.
 */

use Symfony\Component\Yaml\Yaml;
use Drupal\Core\Form\FormStateInterface;
use Drupal\language\Entity\ConfigurableLanguage;
use Drupal\d324\Config\ConfigBit;
use Drupal\d324\Form\AssemblerForm;
use Drupal\d324\Form\DevelopmentToolsAssemblerForm;
use Drupal\d324\Entity\D324EntityDefinitionUpdateManager;

/**
 * Implements hook_form_FORM_ID_alter() for install_configure_form().
 *
 * Allows the profile to alter the site configuration form.
 */
function d324_form_install_configure_form_alter(&$form, FormStateInterface $form_state) {
    // Add a placeholder as example that one can choose an arbitrary site name.
    $form['site_information']['site_name']['#attributes']['placeholder'] = t('My Official Site Name');

    // Default site email noreply@t324.com .
    $form['site_information']['site_mail']['#default_value'] = 'noreply@t324.com';
    $form['site_information']['site_mail']['#attributes']['style'] = 'width: 25em;';

    // Default user 1 username should be 'T324Admin'.
    $form['admin_account']['account']['name']['#default_value'] = 'T324Admin';
    $form['admin_account']['account']['name']['#attributes']['disabled'] = TRUE;
    $form['admin_account']['account']['mail']['#default_value'] = 'drupal@t324.com';
    $form['admin_account']['account']['mail']['#description'] = t('In most case, and for <a target="_blank" href="@link">T324</a> specific use, we recommend this to always be <em>drupal@t324.com</em>.', array('@link' => 'http://t324.com'));
}

/**
 * Implements hook_install_tasks().
 */
function d324_install_tasks(&$install_state) {

    return array(
        'd324_extra_components' => array(
            'display_name' => t('Extra components'),
            'display' => TRUE,
            'type' => 'form',
            'function' => AssemblerForm::class,
        ),
        'd324_assemble_extra_components' => array(
            'display_name' => t('Assemble extra components'),
            'display' => TRUE,
            'type' => 'batch',
        ),
        'd324_development_tools' => array(
            'display_name' => t('Development tools'),
            'display' => TRUE,
            'type' => 'form',
            'function' => DevelopmentToolsAssemblerForm::class,
        ),
        'd324_assemble_development_tools' => array(
            'display_name' => t('Assemble development tools'),
            'display' => TRUE,
            'type' => 'batch',
        ),
    );
}

/**
 * Implements hook_install_tasks_alter().
 */
function d324_install_tasks_alter(array &$tasks, array $install_state) {
    $tasks['install_finished']['function'] = 'd324_after_install_finished';
}

/**
 * Batch job to assemble D324 extra components.
 *
 * @param array $install_state
 *   The current install state.
 *
 * @return array
 *   The batch job definition.
 */
function d324_assemble_extra_components(array &$install_state) {

    // Default D324 components, which must be installed.
    $default_components = ConfigBit::getList('configbit/default.components.d324.bit.yml', 'install_default_components', TRUE, 'dependencies', 'profile', 'd324');

    $batch = [];

    // Install default components first.
    foreach ($default_components as $default_component) {
        $batch['operations'][] = ['d324_assemble_extra_component_then_install', (array) $default_component];
    }

    // Install selected extra features.
    $selected_extra_features = [];
    $selected_extra_features_configs = [];

    if (isset($install_state['d324']['extra_features_values'])) {
        $selected_extra_features = $install_state['d324']['extra_features_values'];
    }

    if (isset($install_state['d324']['extra_features_configs'])) {
        $selected_extra_features_configs = $install_state['d324']['extra_features_configs'];
    }

    // Get the list of extra features config bits.
    $extraFeatures = ConfigBit::getList('configbit/extra.components.d324.bit.yml', 'show_extra_components', TRUE, 'dependencies', 'profile', 'd324');

    // If we do have selected extra features.
    if (count($selected_extra_features) && count($extraFeatures)) {
        // Have batch processes for each selected extra features.
        foreach ($selected_extra_features as $extra_feature_key => $extra_feature_checked) {
            if ($extra_feature_checked) {

                // If the extra feature was a module and not enabled, then enable it.
                if (!\Drupal::moduleHandler()->moduleExists($extra_feature_key)) {
                    // Add the checked extra feature to the batch process to be enabled.
                    $batch['operations'][] = ['d324_assemble_extra_component_then_install', (array) $extra_feature_key];
                }

                if (count($selected_extra_features_configs) &&
                    isset($extraFeatures[$extra_feature_key]['config_form']) &&
                    $extraFeatures[$extra_feature_key]['config_form'] == TRUE &&
                    isset($extraFeatures[$extra_feature_key]['formbit'])) {

                    $formbit_file_name = drupal_get_path('profile', 'd324') . '/' . $extraFeatures[$extra_feature_key]['formbit'];

                    if (file_exists($formbit_file_name)) {

                        // Added the selected extra feature configs to the batch process
                        // with the same function name in the formbit.
                        $batch['operations'][] = ['d324_save_editable_config_values',
                            (array) [
                                $extra_feature_key,
                                $formbit_file_name,
                                $selected_extra_features_configs,
                            ],
                        ];
                    }
                }
            }
        }

        // Hide Warnings and status messages.
        $batch['operations'][] = ['d324_hide_warning_and_status_messages', (array) TRUE];

        // Fix entity updates to clear up any mismatched entity.
        $batch['operations'][] = ['d324_fix_entity_update', (array) TRUE];
    }

    // Install selected Demo content.
    $selected_demo_content = [];
    $selected_demo_content_configs = [];

    if (isset($install_state['d324']['demo_content_values'])) {
        $selected_demo_content = $install_state['d324']['demo_content_values'];
    }

    if (isset($install_state['d324']['demo_content_configs'])) {
        $selected_demo_content_configs = $install_state['d324']['demo_content_configs'];
    }

    // Get the list of demo content config bits.
    $demoContent = ConfigBit::getList('configbit/demo.content.d324.bit.yml', 'show_demo', TRUE, 'dependencies', 'profile', 'd324');

    // If we do have demo_content and we have selected demo_content.
    if (count($selected_demo_content) && count($demoContent)) {
        // Have batch processes for each selected demo content.
        foreach ($selected_demo_content as $demo_content_key => $demo_content_checked) {
            if ($demo_content_checked) {

                // If the demo content was a module and not enabled, then enable it.
                if (!\Drupal::moduleHandler()->moduleExists($demo_content_key)) {
                    // Add the checked demo content to the batch process to be enabled.
                    $batch['operations'][] = ['d324_assemble_extra_component_then_install', (array) $demo_content_key];
                }

                if (count($selected_demo_content_configs) &&
                    isset($demoContent[$demo_content_key]['config_form']) &&
                    $demoContent[$demo_content_key]['config_form'] == TRUE &&
                    isset($demoContent[$demo_content_key]['formbit'])) {

                    $formbit_file_name = drupal_get_path('profile', 'd324') . '/' . $demoContent[$demo_content_key]['formbit'];
                    if (file_exists($formbit_file_name)) {

                        // Added the selected development configs to the batch process
                        // with the same function name in the formbit.
                        $batch['operations'][] = ['d324_save_editable_config_values',
                            (array) [
                                $demo_content_key,
                                $formbit_file_name,
                                $selected_demo_content_configs,
                            ],
                        ];
                    }
                }
            }
        }

        // Hide Warnings and status messages.
        $batch['operations'][] = ['d324_hide_warning_and_status_messages', (array) TRUE];

        // Fix entity updates to clear up any mismatched entity.
        $batch['operations'][] = ['d324_fix_entity_update', (array) TRUE];

    }


    // Uninstall list of not needed modules after the config had been loaded.
    // To be loaded from a ConfigBit yml file.
    $uninstall_components = ['d324_default_content'];
    if (count($uninstall_components) > 0) {
        foreach ($uninstall_components as $uninstall_component)
            $batch['operations'][] = ['d324_uninstall_component', (array) $uninstall_component];
    }


    return $batch;
}

/**
 * Batch job to assemble D324 extra components.
 *
 * @param array $install_state
 *   The current install state.
 *
 * @return array
 *   The batch job definition.
 */
function d324_assemble_development_tools(array &$install_state) {

    $batch = [];

    // Install selected Development tools.
    $selected_development_tools = [];
    $selected_development_configs = [];

    if (isset($install_state['d324']['development_tools_values'])) {
        $selected_development_tools = $install_state['d324']['development_tools_values'];
    }

    if (isset($install_state['d324']['development_tools_configs'])) {
        $selected_development_configs = $install_state['d324']['development_tools_configs'];
    }

    // Development tools.
    $developmentTools = ConfigBit::getList('configbit/development.tools.d324.bit.yml', 'show_development_tools', TRUE, 'dependencies', 'profile', 'd324');

    // If we do have development tools and we have selected development tools.
    if (count($selected_development_tools) && count($developmentTools)) {
        // Have batch processes for each selected development tool.
        foreach ($selected_development_tools as $development_tool_key => $development_tool_checked) {
            if ($development_tool_checked) {

                // If the development tool was a module and not enabled, then enable it.
                if (!\Drupal::moduleHandler()->moduleExists($development_tool_key)) {
                    // Add checked development tool to the batch process to be enabled.
                    $batch['operations'][] = ['d324_assemble_extra_component_then_install', (array) $development_tool_key];
                }

                if (count($selected_development_configs) &&
                    isset($developmentTools[$development_tool_key]['config_form']) &&
                    $developmentTools[$development_tool_key]['config_form'] == TRUE &&
                    isset($developmentTools[$development_tool_key]['formbit'])) {

                    $formbit_file_name = drupal_get_path('profile', 'd324') . '/' . $developmentTools[$development_tool_key]['formbit'];
                    if (file_exists($formbit_file_name)) {

                        // Added the selected development configs to the batch process
                        // with the same function name in the formbit.
                        $batch['operations'][] = ['d324_save_editable_config_values',
                            (array) [
                                $development_tool_key,
                                $formbit_file_name,
                                $selected_development_configs,
                            ],
                        ];
                    }
                }
            }
        }

        // Hide Warnings and status messages.
        $batch['operations'][] = ['d324_hide_warning_and_status_messages', (array) TRUE];

        // Fix entity updates to clear up any mismatched entity.
        $batch['operations'][] = ['d324_fix_entity_update', (array) TRUE];
    }

    return $batch;
}

/**
 * Batch function to assemble and install needed extra components.
 *
 * @param string|array $extra_component
 *   Name of the extra component.
 */
function d324_assemble_extra_component_then_install($extra_component) {
    \Drupal::service('module_installer')->install((array) $extra_component, TRUE);
}

/**
 * Batch function to save editable config values for extra components.
 *
 * @param string|array $extra_component_machine_name
 *   Machine name key of the extra component.
 * @param string|array $formbit_file_name
 *   FormBit file name.
 * @param string|array $editable_config_values
 *   Editable config values.
 */
function d324_save_editable_config_values($extra_component_machine_name, $formbit_file_name, $editable_config_values) {
    include_once $formbit_file_name;
    call_user_func_array($extra_component_machine_name . "_submit_formbit", array($editable_config_values));
}

/**
 * Batch function to add selected langauges then fetch all traslation.
 *
 * @param string|array $language_code
 *   Language code to install and fetch all traslation.
 */
function d324_configure_language_and_fetch_traslation($language_code) {
    ConfigurableLanguage::createFromLangcode($language_code)->save();
}

/**
 * Batch function to fix entity updates to clear up any mismatched entity.
 *
 * Entity and/or field definitions, The following changes were detected in
 * the entity type and field definitions.
 *
 * @param string|array $entity_update
 *   To entity update or not.
 */
function d324_fix_entity_update($entity_update) {
    if ($entity_update) {
        \Drupal::classResolver()
            ->getInstanceFromDefinition(D324EntityDefinitionUpdateManager::class)
            ->applyUpdates();
    }
}

/**
 * Batch function to Uninstall list of not needed modules after the config had been loaded.
 *
 * @param string|array $uninstall_component
 *   Name of the extra component.
 */
function d324_uninstall_component($uninstall_component) {
    if (\Drupal::moduleHandler()->moduleExists($uninstall_component)) {
        \Drupal::service('module_installer')->uninstall((array) $uninstall_component, FALSE);
    }
}

/**
 * D324 after install finished.
 *
 * Lanuch auto D324 Tour auto launch after install.
 *
 * @param array $install_state
 *   The current install state.
 *
 * @return array
 *   A renderable array with a redirect header.
 */
function d324_after_install_finished(array &$install_state) {

    // Mark all updates by the update helper checklist as successful on install.
    if (\Drupal::moduleHandler()->moduleExists('update_helper_checklist')) {
        $checkList = \Drupal::service('update_helper_checklist.update_checklist');
        $checkList->markAllUpdates();
    }

    // Activate D324 Bootstrap Paragraphs Settings in the active config.
    if (\Drupal::moduleHandler()->moduleExists('d324_bootstrap_paragraphs')) {
        $profile_path = drupal_get_path('profile', 'd324') . '/config/optional/';
        $config_path = $profile_path . 'd324_bootstrap_paragraphs.settings.yml';
        $config_content = file_get_contents($config_path);
        $config_data = (array) Yaml::parse($config_content);
        $config_factory = \Drupal::configFactory()->getEditable('d324_bootstrap_paragraphs.settings');
        $config_factory->setData($config_data)->save(TRUE);
    }

    global $base_url;

    // After install direction.
    $after_install_direction = $base_url . '/?welcome';

    install_finished($install_state);
    $output = [];

    // Clear all messages.
    drupal_get_messages();

    $output = [
        '#title' => t('D324'),
        'info' => [
            '#markup' => t('<p>Congratulations, you have installed D324!</p><p>If you are not redirected to the front page in 5 seconds, Please <a href="@url">click here</a> to proceed to your installed site.</p>', [
                '@url' => $after_install_direction,
            ]),
        ],
        '#attached' => [
            'http_header' => [
                ['Cache-Control', 'no-cache'],
            ],
        ],
    ];

    $meta_redirect = [
        '#tag' => 'meta',
        '#attributes' => [
            'http-equiv' => 'refresh',
            'content' => '0;url=' . $after_install_direction,
        ],
    ];
    $output['#attached']['html_head'][] = [$meta_redirect, 'meta_redirect'];

    return $output;
}

/**
 * Batch function to hide warning messages.
 *
 * @param bool $hide
 *   To hide or not.
 */
function d324_hide_warning_and_status_messages($hide) {
    if ($hide && !isset($_SESSION['messages']['error'])) {
        unset($_SESSION['messages']);
    }
}

/**
 * Implements hook_toolbar_alter().
 */
function d324_toolbar_alter(&$items) {
    if (\Drupal::currentUser()->hasPermission('access toolbar')
        && !empty($items['admin_toolbar_tools'])) {
        $items['admin_toolbar_tools']['#attached']['library'][] = 'd324/toolbar.icon';
    }
}