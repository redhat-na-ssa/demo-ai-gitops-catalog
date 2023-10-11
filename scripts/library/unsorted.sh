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
