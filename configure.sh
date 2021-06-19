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
    ".level1-dir1:level2-dir1:level3-dir1:repository"
    ".level1-dir1:level2-dir2:repository"
    ".level1-dir2:level2-dir1:level3-dir1:level4-dir1:repository"
    ".level1-dir3:level2-dir1:level3-dir1:repository"
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

    layer_collection+=($all_layers)

    # the following lines are for sourcing/comparison purposes
    # All values in path format: $all_values
    # All layers in path format: $all_layers
    # Repository source: $source_repositories

  done

}

cleanup() {

  server_content=($(find "$root_dir" -maxdepth 1 -name ".*" -type d | sort))
  for first_layer in ${server_content[@]}; do

    # get the first layer of the live server to set a base where to start from
    crop="${first_layer##$root_dir/}"
    first_layers+=($crop)

  done

  for first in ${first_layers[@]}; do

    # we need a live path equal formatted to assigned valus, so we're only looking for directories to built up from $first_layer
    base_path="$root_dir/$first"
    path_collection+=($(find "$base_path" -type d | sort))

  done

  for live_path in ${path_collection[@]}; do

    # since the $root_dir is excluded from assigned values, it can be removed here also
    crop="${live_path##$root_dir/}"

    # looking for matches that are NOT existend within the assigned collection of layers
    if [[ ! "${layer_collection[@]}" =~ "$crop" ]]; then

      echo && echo "$crop is going to be removed since it was not assigned as layer"
      echo "rm -rf $root_dir/$crop"
      rm -rf $root_dir/$crop

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