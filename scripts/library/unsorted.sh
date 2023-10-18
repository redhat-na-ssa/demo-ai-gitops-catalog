#!/bin/bash

until_true(){
  echo "Running:" "${@}"
  until "${@}"
  do
    sleep 1
    echo "and again..."
  done

  echo "[OK]"
}

fake_argocd(){
  if [ ! -f "${1}/kustomization.yaml" ]; then
    echo "Please provide a dir with \"kustomization.yaml\""
    return
  fi

  until_true oc apply -k "${1}"
}

select_folder(){
  FOLDER="${1:-options}"
  PS3="Select by number: "
  
  [ -d "${FOLDER}" ] || return

  echo "Options"

  pushd "${FOLDER}" >/dev/null || return
  
  select selected in */
  do
    [ -d "${selected}" ] && break
    echo ">>> Invalid Selection <<<";
  done

  if [ -n "${selected}" ]; then
    echo "Selected: ${selected}"
  else
    select_folder "${FOLDER}"
  fi

  popd >/dev/null || return
}

reset_wordlist(){
  pyspelling | sort -u | grep -E -v ' |---|/|^$' > .wordlist-md
}
