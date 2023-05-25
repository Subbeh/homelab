#!/usr/bin/env bash

set -eo pipefail

echo "${ANSIBLE_VAULT_PASSWORD:?not set}" > $HOME/.ansible_vault

while read file ; do
  echo checking file $file...
  if [[ "$file" =~ ansible/(roles|playbooks|tasks)/.*\.ya?ml ]] ; then
    pushd ansible
    ansible-lint -v -c .ansible-lint "${file#*/}"
    popd
  fi
  if [[ "$file" =~ ansible/.*\.ya?ml$ ]] ; then
    yamllint -s -c .yamllint "$file"
  fi
done <<< $(git log --name-only --oneline --diff-filter=ACMR origin/main@{1}..origin/main | awk 'length($1) != 7')
