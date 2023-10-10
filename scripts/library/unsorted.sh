#!/bin/sh

run_until_true(){
  until "$@"
  do
    "$@"
    sleep 1
  done
}
