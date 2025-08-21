#!/bin/bash

GIT_DEMO_REPO=https://github.com/redhat-na-ssa/demo-ai-gitops-catalog.git
GIT_DEMO_NAME=demo_ops
GIT_OPS_REPO=https://github.com/redhat-cop/gitops-catalog.git
GIT_OPS_NAME=git_ops

# shellcheck disable=SC2120
term_bashrc(){
BASHRC=${1:-/home/user/.bashrc}

# avoid making everyone mad
grep -q 'OpenShift Web Terminal' "${BASHRC}" || return

# avoid running more than once
grep -q 'Enhanced' "${BASHRC}" && return

# shellcheck disable=SC2028
echo "
GIT_DEMO_REPO=${GIT_DEMO_REPO}
GIT_OPS_REPO=${GIT_OPS_REPO}

printf 'This terminal has been \e[0;32m~Enhanced~\e[0m\n'
printf 'See \033[34;1;1m'${GIT_DEMO_REPO}'\e[0m\n\n'

term_git_setup(){
  [ -z \"\${GIT_DEMO_REPO}\" ] && return
  git clone \"\${GIT_DEMO_REPO}\" ~/${GIT_DEMO_NAME:-demo_ops}
  git clone \"\${GIT_OPS_REPO}\" ~/${GIT_OPS_NAME:-git_ops}
}

__git_branch(){
  git name-rev --name-only @ 2>/dev/null
}

PS1='\e]\s\a\n\e[33m\w \e[36m\$(__git_branch)\e[m$ '

if [ -d ~/${GIT_DEMO_NAME:-demo_ops} ]; then
  cd ~/${GIT_DEMO_NAME:-demo_ops}
  . scripts/functions.sh
fi

[ -e ~/.venv/bin/activate ] && . ~/.venv/bin/activate

PATH=\${KREW_ROOT:-\$HOME/.krew}/bin:\$PATH
PATH=\${GIT_ROOT}/scratch/bin:\$PATH

[ -d ~/${GIT_DEMO_NAME:-demo_ops} ] || term_git_setup

[ -d \"\${GIT_ROOT}/scratch/bash\" ] && . <(cat \${GIT_ROOT}/scratch/bash/*.sh)
" >> "${BASHRC}"
}

term_git_setup(){
  [ -z "${GIT_DEMO_REPO}" ] && return
  git clone "${GIT_DEMO_REPO}" ~/"${GIT_DEMO_NAME:-demo_ops}" || echo "[OK]"
  git clone "${GIT_OPS_REPO}" ~/"${GIT_OPS_NAME:-git_ops}" || echo "[OK]"
}

term_bin_setup(){

  term_git_setup

  cd ~/${GIT_DEMO_NAME:-demo_ops} || return 0
  # shellcheck disable=SC1091
  . scripts/functions.sh

  # [ -d ~/.venv ] || python3 -m venv ~/.venv

  # kludge
  which unzip || bin_check busybox

  bin_check yq
  bin_check oc-mirror
  bin_check krew
  bin_check kubectl-operator
  bin_check crane

  bin_check rclone
  bin_check restic

  bin_check sops
  bin_check age
}

term_init(){
  term_bashrc
  term_bin_setup
}
