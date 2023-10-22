#!/bin/bash

select_folder(){
  FOLDER="${1:-options}"
  PS3="Select by number: "
  
  [ -d "${FOLDER}" ] || return

  echo "Options"

  pushd "${FOLDER}" >/dev/null || return
  
  select selected_folder in */
  do
    [ -d "${selected_folder}" ] && break
    echo ">>> Invalid Selection <<<";
  done

  if [ -n "${selected_folder}" ]; then
    echo "Selected: ${selected_folder}"
  else
    select_folder "${FOLDER}"
  fi

  popd >/dev/null || return
}

reset_wordlist(){
  pyspelling | sort -u | grep -E -v ' |---|/|^$' > .wordlist-md
}
