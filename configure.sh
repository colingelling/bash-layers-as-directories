#!/bin/bash

# format - hidden:layers-as-directories:repository
# explanation:
# the first layers must be hidden directories as its content can be used to configure applications, deployment subjects and more of that type. So we don't want to let everyone be able to access this straight away
# upcoming layers (2 and up) are there to group what is next such as the configuration files
# the final tag (always need to be set as the last one) are repositories used as sources. With that, content could be set to the layered directory path 

prepareVars() {

  # define working directory
  root_dir="./custom-directories"

  DEPLOYMENT_DIRECTORY_ASSIGNMENT=(
    ".hidden1:directory1:repository_1"
    ".hidden2:directory2:repository_2"
    ".hidden3:directory1:subdirectory1:repository_3"
    ".hidden4:directory1:subdirectory1:innerdirectory1:repository_4"
  )

}

configureRootDir() {

  # defined root_dir need to exist before continuing
  if [ ! -d "$root_dir" ]; then 
  
    echo "Checking root directory '$root_dir' for existence"
    echo "mkdir $root_dir"
    mkdir $root_dir

  else 
    echo "$root_dir already has been set, nothing to do here" 
  fi

}

configureLayeredDirectories() {

  for collection in ${DEPLOYMENT_DIRECTORY_ASSIGNMENT[@]}; do

    # split collection into array
    IFS=':' read -r -a layers <<< "$collection"

    all_values=$(echo ${collection} | tr : /)

    # extract all layers
    all_layers=$(echo ${collection%:*} | tr : /)

    # extract the repository from the last array element
    source_repositories="${layers[-1]}"

    u_values=($(echo "${layers[0]}" | tr ' ' '\n' | sort -u | tr '\n' ' '))
    first_layers+=($u_values)

    # configure all layers as directories
    if [ ! -d "$root_dir/$all_layers" ]; then 

      echo && echo "Directory '$root_dir/$all_layers' does not exist yet"
      echo "mkdir -p $root_dir/$all_layers" 
      mkdir -p $root_dir/$all_layers

    else 
      echo && echo "Directory $root_dir/$all_layers exists, nothing to do here" 
    fi

    # the following lines are for sourcing/comparison purposes
    # All values in path format: $all_values
    # All layers in path format: $all_layers
    # Repository source: $source_repositories

  done

}

cleanup() {

  live_values=($(find "$root_dir" -maxdepth 1 -name ".*" | sort))
  for value in ${live_values[@]}; do

    crop="${value##$root_dir/}"
    directories+=($crop)

  done

  for live_value in ${directories[@]}; do

    if [[ ! "${first_layers[@]}" =~ "$live_value" ]]; then

      echo && echo "$live_value is not equal to the first layers that were assigned"
      path="$root_dir/$live_value"
      echo "rm -rf $path"
      rm -rf $path

    fi

  done

}

main() {

  # include function
  prepareVars

  # set root directory
  configureRootDir

  # set assigned values as layered directories
  configureLayeredDirectories

  # remove everything that is not equal to assigned values
  cleanup

}

main