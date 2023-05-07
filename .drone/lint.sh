#!/usr/bin/env bash

set -x
set -eo pipefail

echo "${ANSIBLE_VAULT_PASSWORD:?not set}" > $HOME/.ansible_vault

while read file ; do
  echo checking file $file...
  if [[ "$file" =~ ansible/playbooks/.*\.ya?ml ]] ; then
    cd ansible
    ansible-lint -v -c .ansible-lint "playbooks/${file##*/}"
    cd -
  fi
  if [[ "$file" =~ ansible/.*\.ya?ml$ ]] ; then
    yamllint -s -c .yamllint "$file"
  fi
done <<< $(git diff --name-only --diff-filter=ACMR HEAD~1 main)
