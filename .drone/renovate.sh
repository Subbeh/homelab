#!/usr/bin/env bash
set -x
set -eo pipefail

CONTAINER_PLAYBOOK=playbooks/container.yml

git config --global --add safe.directory /drone/src
echo "${ANSIBLE_VAULT_PASSWORD:?not set}" > $HOME/.ansible_vault
mkdir -p $HOME/.ssh && echo "${SSH_KEY:?not set}" > $HOME/.ssh/id_ed25519 && chmod -R 600 $HOME/.ssh
cat $HOME/.ssh/id_ed25519
cd ansible

while read file ; do
  echo checking file $file...
  if [[ "$file" == ansible/containers/*.yml ]] ; then
    container=$(echo "$file" | sed 's#.*/\(.\+\).ya\?ml#\1#')
    echo running container script for $container...
    ANSIBLE_HOST_KEY_CHECKING=false ansible-playbook "${CONTAINER_PLAYBOOK:?not set}" --tags $container
  fi
done <<< $(git diff --name-only --diff-filter=ACMR HEAD~1 main)
