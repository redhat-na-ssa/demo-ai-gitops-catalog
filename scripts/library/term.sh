#!/bin/bash

GIT_AI_REPO=https://github.com/codekow/demo-ai-gitops-catalog.git
GIT_OPS_REPO=https://github.com/redhat-cop/gitops-catalog.git


term_init(){
# avoid making everyone mad
grep -q 'OpenShift Web Terminal' ~/.bashrc || return 1

# shellcheck disable=SC2028
echo "
echo
GIT_AI_REPO=${GIT_AI_REPO}
printf 'This terminal has been \e[0;32m~Enhanced~\e[0m\n'
printf 'See \033[34;1;1m'${GIT_AI_REPO}'\e[0m\n\n'

__git_branch(){
  git name-rev --name-only @ 2>/dev/null
}

PS1='\e]\s\a\n\e[33m\w \e[36m\$(__git_branch)\e[m$ '

if [ -e ai_ops ]; then
  cd ai_ops
  . scripts/functions.sh
fi

[ -e ~/.venv/bin/activate ] && . ~/.venv/bin/activate
[ -e ~/ai_ops/scratch/bin/restic.bash ] && . ~/ai_ops/scratch/bin/restic.bash

" >> ~/.bashrc

  git clone "${GIT_AI_REPO}" ai_ops
  git clone "${GIT_OPS_REPO}" ops
  cd ai_ops || return
  # shellcheck disable=SC1091
  . scripts/functions.sh

  [ -d ~/.venv ] || platform-python -m venv ~/.venv

  bin_check busybox

  bin_check oc-mirror
  bin_check rclone
  bin_check restic
}
