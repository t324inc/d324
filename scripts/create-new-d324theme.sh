#!//bin/bash
################################################################################
## Create new D324theme Sub-Theme.
################################################################################
##
## Quick tip on how to use this script command file.
##
## Create new D324theme sub theme for a project.
## By Bash:
## -----------------------------------------------------------------------------
## cd PROJECT_DIR_NAME/web/themes/contrib/d324theme/scripts
## bash ./create-new-d324theme.sh "THEME_NAME"
##------------------------------------------------------------------------------
##
##
################################################################################

# Basic yaml parser.
parse_yaml() {
   local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
   sed -ne "s|^\($s\)\($w\)$s:$s\"\(.*\)\"$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p"  $1 |
   awk -F$fs '{
      indent = length($1)/2;
      vname[indent] = $2;
      for (i in vname) {if (i > indent) {delete vname[i]}}
      if (length($3) > 0) {
         vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
         printf("%s%s%s=\"%s\"\n", "",vn, $2, $3);
      }
   }'
}

current_path=$(pwd);
drupal_root="$current_path";

if [[ "${drupal_root: -1}" == "/" ]]; then
  drupal_root="${drupal_root::-1}";
fi

if [[ "${drupal_root: -21}" == "profiles/d324/scripts" ]]; then
  drupal_root="${drupal_root::-21}";
fi

if [[ "${drupal_root: -13}" == "profiles/d324" ]]; then
  drupal_root="${drupal_root::-13}";
fi

if [[ "${drupal_root: -8}" == "profiles" ]]; then
  drupal_root="${drupal_root::-8}";
fi

if [[ "${drupal_root: -1}" == "/" ]]; then
  drupal_root="${drupal_root::-1}";
fi

echo "Current path: $current_path";
echo "Drupal root: $drupal_root";

# Read scripts.settings.yml file
eval $(parse_yaml $drupal_root/profiles/d324/scripts/scripts.settings.yml);

if [ ! -z "$1" ]; then
  theme_name="$1";
fi

while true; do

  # Grab the theme name argument.
  if [ ! -z "$theme_name" ]; then
    if [[ ! $theme_name =~ ^[a-z][a-z0-9_]*$ ]]; then
      echo "";
      echo "---------------------------------------------------------------------------";
      echo "   Theme name is not a valid theme machine name!                           ";
      echo "   Please re-enter the machine name of your theme.                         ";
      echo "   It must contain only lowercase letters, numbers, and/or underscores.    ";
      echo "   The theme machine name must start with a letter, not a number.          ";
      echo "---------------------------------------------------------------------------";
      echo "";
      echo -n "Enter the machine name of the new theme and press [ENTER]: ";
      read theme_name;
    else
      break;
    fi
  else
    echo "";
    echo "---------------------------------------------------------------------------";
    echo "   Please add the machine name of your theme.                              ";
    echo "   It must contain only lowercase letters, numbers, and/or underscores.    ";
    echo "   The theme machine name must start with a letter, not a number.          ";
    echo "---------------------------------------------------------------------------";
    echo "";
    echo -n "Enter the machine name of the new theme and press [ENTER]: ";
    read theme_name;
  fi

done

if [ ! -z "$2" ]; then
  theme_human_name="$2";
fi

while true; do

  # Grab the theme name argument.
  if [ ! -z "$theme_human_name" ]; then
    if [[ ! $theme_human_name =~ ^[A-Za-z][A-Za-z0-9[:space:]-]*$ ]]; then
      echo "";
      echo "---------------------------------------------------------------------------";
      echo "   Theme name is not a valid theme name!                                   ";
      echo "   Please re-enter the human-readable name of your theme.                  ";
      echo "   It must contain only letters, numbers, spaces, or hyphens.              ";
      echo "   The theme name must start with a letter, not a number.                  ";
      echo "---------------------------------------------------------------------------";
      echo "";
      echo -n "Enter the human-readable name of the new theme and press [ENTER]: ";
      read theme_human_name;
    else
      break;
    fi
  else
    echo "";
    echo "---------------------------------------------------------------------------";
    echo "   Please add the human-readable name of your theme.                       ";
    echo "   It must contain only letters, numbers, spaces, underscores, or hyphens. ";
    echo "   The theme name must start with a letter, not a number.                  ";
    echo "---------------------------------------------------------------------------";
    echo "";
    echo -n "Enter the human-readable name of the new theme and press [ENTER]: ";
    read theme_human_name;
  fi

done

# Default themes creation path.
theme_path=$drupal_root/$default_themes_creation_path;
mkdir -p ${theme_path};

# Create the new D324theme subtheme if we do not have a folder with that name yet.
if [[ ! -d "$theme_path/$theme_name" ]]; then

  # 1. Copy the D324THEME_SUBTHEME folder to your custom theme location.

  cp -r ${drupal_root}/themes/d324/d324theme/SUBTHEME_KIT ${theme_path}/${theme_name};

  find ${theme_path}/${theme_name} -name "*d324_subtheme*" -exec rename "s/d324_subtheme/$theme_name/" {} ";"

  find ${theme_path}/${theme_name} -type f | xargs sed -i  "s/D324_SUBTHEME_MACHINE_NAME/$theme_name/g" ;

  find ${theme_path}/${theme_name} -type f | xargs sed -i  "s/D324_SUBTHEME_NAME/$theme_human_name/g" ;

  sed -i "s/hidden: true/hidden: false/g" ${theme_path}/${theme_name}/${theme_name}.info.yml ;

  # 10. Install needed libraries
  cd ${theme_path}/${theme_name};
  npm install;
  npm run dev;

  generated_datetime="$(date '+%Y/%m/%d - %H:%M:%S')";
  generated_log=" Generated by -- create-new-d324theme ${theme_name} ${theme_path} -- on ${generated_datetime}";

  echo "${generated_log}"  >> ${theme_path}/${theme_name}/README.md;

  echo "---------------------------------------------------------------------------";
  echo "   The new D324theme subtheme was created at \"${theme_path}/${theme_name} :) ";
  echo "---------------------------------------------------------------------------";

else
  echo "---------------------------------------------------------------------------";
  echo "   The folder \"${theme_path}\/${theme_name}\" is already in the site!       ";
  echo "---------------------------------------------------------------------------";
fi
