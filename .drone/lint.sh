#!/usr/bin/env bash
set -x
set -eo pipefail

# env
# ssh -o StrictHostKeyChecking=false -T git@github.com || true
# sleep 10000
# rm ansible/requirements.yml 2>/dev/null

while read file ; do
  echo checking file $file...
  # if [[ "$file" =~ ansible/playbooks/.*\.ya?ml ]] ; then
  #   cd ansible
  #   ansible-lint -c .ansible-lint "../$file"
  #   cd -
  # fi
  if [[ "$file" =~ ansible/.*\.ya?ml ]] ; then
    yamllint -s -c .yamllint "$file"
  fi
done <<< $(git diff --name-only --diff-filter=ACMR HEAD~1 main)
