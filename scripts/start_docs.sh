#!/bin/sh

container_start(){
  which podman > /dev/null 2>&1 && alias podman=docker

  docker run \
    --rm -it \
    -p 8000:8000 \
    -v "${PWD}:/docs${SELINUX}" \
      docker.io/squidfunk/mkdocs-material
  
}

init(){
  which getenforce > /dev/null 2>&1 && SELINUX=:z

  which docker > /dev/null 2>&1 && container_start docker

}

init
