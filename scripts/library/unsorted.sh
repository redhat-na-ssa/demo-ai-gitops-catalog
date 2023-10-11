#!/bin/sh

until_true(){
  echo "Running:" "${@}"
  until "${@}"
  do
    sleep 1
    echo "and again..."
  done

  echo "[OK]"
}

select_folder(){
  FOLDER="${1:-options}"
  PS3="Select by number: "
  
  [ -d "${FOLDER}" ] || return

  echo "Options"

  pushd "${FOLDER}" >/dev/null
  
  select selected in */
  do
    [ -d "${selected}" ] && break
    echo ">>> Invalid Selection <<<";
  done

  if [ -n "${selected}" ]; then
    echo "Selected: ${selected}"
  else
    select_folder
  fi

  popd >/dev/null
}
