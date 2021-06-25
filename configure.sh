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

  _prepareArrayData

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

_prepareArrayData() {

  for collection in "${DEPLOYMENT_DIRECTORY_ASSIGNMENT[@]}"; do

    # split collection into array
    IFS=':' read -r -a layers <<< "$collection"

    # extract all values in path format for easy comparing   
    all_values+="($(echo "${collection}" | tr : /))"

    # extract the repository from the last array element
    source_repositories+=("${layers[-1]}")
    
    # extract all layers
    all_layers="$(echo "${collection%:*}" | tr : /)"
    layer_collection+=("$all_layers")

    mapfile -t u_values < <(echo "${layers[0]}" | tr ' ' '\n' | sort -u | tr '\n' ' ')
    if [[ -n "${u_values[*]}" ]]; then

      for value in "${u_values[@]}"; do
        first_layers+=("$value")
      done

    else
      echo "Variable 'u_values' seems empty, exiting.. " && exit 1
    fi

    # the following lines are for sourcing/comparison purposes
    # All values in path format: $all_values
    # All layers in path format: $all_layers
    # Repository source: $source_repositories

  done

}

configureDirectoriesByLayer() {

  if [[ -n "${layer_collection[*]}" ]]; then

    for layers in "${layer_collection[@]}"; do

      # configure all layers as directories
      if [ ! -d "$root_dir/$layers" ]; then 

        echo && echo "Directory '$root_dir/$layers' does not exist yet"
        echo "mkdir -p $root_dir/$layers" 
        mkdir -p "$root_dir/$layers"

      else 
        echo && echo "Directory '$root_dir/$layers' already exists, nothing to do here" 
      fi

    done

  else
    echo "Variable 'all_layers' seems empty, empty, exiting.." && exit 1
  fi

}

_collectFirstLayersAsDirectories() {

  mapfile -t server_content < <(find "$root_dir" -maxdepth 1 -name ".*" -type d | sort)
  if [[ -n "${server_content[*]}" ]]; then

    for first_layer in "${server_content[@]}"; do

      # get the first layer of the live server to set a base where to start from
      crop="${first_layer##$root_dir/}"
      first_live_layers+=("$crop")

    done

  else
    echo "Command 'find $root_dir -maxdepth 1 -name .* -type d | sort' returned empty, exiting.." && exit 1
  fi

}

_collectFirstLayerPaths() {

  _collectFirstLayersAsDirectories # pass

  if [[ -n "${first_live_layers[*]}" ]]; then

    for first_dir in "${first_live_layers[@]}"; do

      # we need a live path equal formatted to assigned values, so we're only looking for directories to built up from $first_layer
      base_path="$root_dir/$first_dir"
      mapfile -t path_collection < <(find "$base_path" -type d | sort)

    done

  else
    echo "Variable 'first_layers' seems empty, exiting.." && exit 1
  fi

}

cleanup() {

  _collectFirstLayerPaths

  if [[ -n "${path_collection[*]}" ]]; then

    for live_path in "${path_collection[@]}"; do

      # since the $root_dir is excluded from assigned values, it also can be removed here
      result="${live_path##$root_dir/}"

      # looking for matches that are NOT existend within the assigned collection of layers
      if [[ ! "${layer_collection[*]}" =~ $result ]]; then

        echo "Directory '$result' does not belong here"

        echo && echo "$result is going to be removed since it was not assigned as layer"
        final="$root_dir/$result"

        echo "rm -rf $final"
        rm -rf "$final"

      fi     

    done

  else
    echo "Variable 'path_collection' seems empty, exiting.." && exit 1
  fi

}

main() {

  # include function
  prepareVars

  # set root directory
  configureRootDir

  # set assigned values as layered directories
  configureDirectoriesByLayer

  # remove everything that is not equal to assigned values
  cleanup

  # figure out why for example ./custom-directories/.level1-dir1/level2-dir1/level3-dir1 could'nt be removed instead of a path with a new value ./custom-directories/.level1-dir4/level2-dir1/level3-dir1

}

main