# D324 Scripts

## Quick tip on how to use this script command file.

Default settings could be changed in scripts.settings.yml

# Create a D324theme sub theme ( Bootstrap 4 ) SASS

Before we generate the new sub theme we need to have the following tools
* 1. npm and nodejs : Helps getting the bootstrap 4 and popper packages. 
        [Bootstrap standard build tools](https://getbootstrap.com/docs/4.0/getting-started/build-tools/)
```
$ curl -sL https://deb.nodesource.com/setup | sudo bash -
$ apt install nodejs
$ apt install build-essential

$ curl -L https://npmjs.com/install.sh | sh
$ apt install npm
```

* 2. Gulp : Helps compiling SASS to CSS
```
npm install gulp-cli -g
npm install gulp -D
```

After we make sure that we do have all the tools we could change directory
 in the terminal to:

```
$ cd PROJECT_DIR_NAME/web/profiles/d324/scripts
$ bash ./create-new-d324theme.sh
```

* Activate your new sub theme by going to Appearance in our D324 site.
* Search for THEME_NAME of the generated new sub theme and click on Install
 and set as default.
