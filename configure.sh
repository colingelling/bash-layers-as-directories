#!/bin/bash

# format - hidden:layers:repository
# explanation:
# the first layers will be hidden directories as its content can be used to configure applications, deployment subjects and more of that type
# upcoming layers (1 and up) are there to group what is next such as the configuration files
# the final tag (always need to be set as last one) are repositories used as sources. With that, content could be set to the layered directory path 

prep() {

  # define working directory
  root_dir="./custom-directories"

  DEPLOYMENT_DIRECTORY_ASSIGNMENT=(
    ".hidden_layer1:directory1:repository_1"
    ".hidden_layer1:directory2:repository_2"
    ".hidden_layer2:directory1:subdirectory1:repository_3"
    ".hidden_layer3:directory1:subdirectory1:innerdirectory1:repository_4"
  )

}

_main() {

  # include function
  prep

  # defined root_dir need to exist before continuing
  if [ ! -d "$root_dir" ]; then 
  echo "mkdir $root_dir"; mkdir $root_dir; 
  else echo "$root_dir already has been set"; fi

  for collection in ${DEPLOYMENT_DIRECTORY_ASSIGNMENT[@]}; do

      # split collection into array
      IFS=':' read -r -a layers <<< "$collection"

      all_values="${collection}"
      all_values_slashed=$(echo ${collection} | tr : /)

      # extract all layers
      path_format=$(echo ${collection%:*} | tr : /)

      # extract the repository from the last array element
      source_repositories="${layers[-1]}"

      # configure all layers as directories
      if [ ! -d "$root_dir/$path_format" ]; then 
      echo && echo "mkdir -p $root_dir/$path_format"; mkdir -p $root_dir/$path_format; 
      else echo && echo "$root_dir/$path_format exists"; fi

      # the following lines are for sourcing/comparison purposes
      echo && echo "All values: " $all_values
      echo "All values by '/': " $all_values_slashed
      echo "All layers in path format: " $path_format
      echo "Repository source: " $source_repositories

  done

}

_main