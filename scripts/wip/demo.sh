#!/bin/bash

demo_all(){

  echo "setup: enhanced web terminal"
  apply_firmly "${GIT_ROOT}/bootstrap/web-terminal"
  
  echo "setup: argocd for a default cluster"
  apply_firmly "${GIT_ROOT}/bootstrap/argo-managed"

  echo "setup: all-the-things demo"
  apply_firmly "${GIT_ROOT}/demos/all-the-things"

}

demo_list(){
  # shellcheck disable=SC2010
  ls -1 "${GIT_ROOT}/demos" | grep -Ev 'base'
}