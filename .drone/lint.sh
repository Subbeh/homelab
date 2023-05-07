#!/usr/bin/env bash

set -x
set -eo pipefail

while read file ; do
  echo checking file $file...
  if [[ "$file" =~ ansible/playbooks/.*\.ya?ml ]] ; then
    cd ansible
    ansible-lint -c .ansible-lint "../$file"
    cd -
  fi
  if [[ "$file" =~ ansible/.*\.ya?ml$ ]] ; then
    yamllint -s -c .yamllint "$file"
  fi
done <<< $(git diff --name-only --diff-filter=ACMR HEAD~1 main)
