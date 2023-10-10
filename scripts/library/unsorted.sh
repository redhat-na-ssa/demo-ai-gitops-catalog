#!/bin/sh

until_true(){
  until "${@}"
  do
    sleep 1
  done
}
