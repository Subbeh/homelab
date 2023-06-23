#!/usr/bin/env bash
set -eo pipefail

APP_PLAYBOOK=playbooks/app.yml

git config --global --add safe.directory /drone/src
echo "${ANSIBLE_VAULT_PASSWORD:?not set}" > $HOME/.ansible_vault
if [ ! -r $HOME/.ssh/id_ed25519 ] ; then
  mkdir -p $HOME/.ssh && echo "${SSH_KEY:?not set}" > $HOME/.ssh/id_ed25519 && chmod -R 600 $HOME/.ssh
fi

pushd ansible

while read file ; do
  echo checking file $file...
  if [[ "$file" == ansible/apps/*.yml ]] ; then
    app=$(echo "$file" | sed 's#.*/\(.\+\).ya\?ml#\1#')
    echo running app script for $app...
    ANSIBLE_HOST_KEY_CHECKING=false ansible-playbook "${APP_PLAYBOOK:?not set}" --tags $app
  fi
done <<< $(git diff --name-only --diff-filter=ACMR HEAD~1 main | xargs awk -F: '/^[^ ]\w/ { print $1 }')
