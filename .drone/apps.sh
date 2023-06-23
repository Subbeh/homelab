#!/usr/bin/env bash
set -eo pipefail

APP_PLAYBOOK=playbooks/app.yml

pushd ansible

git config --global --add safe.directory /drone/src
echo "${ANSIBLE_VAULT_PASSWORD:?not set}" > $HOME/.ansible_vault
if [ ! -r $HOME/.ssh/id_ed25519 ] ; then
  mkdir -p $HOME/.ssh && echo "${SSH_KEY:?not set}" > $HOME/.ssh/id_ed25519 && chmod -R 600 $HOME/.ssh
fi

while read app ; do
  if [[ $app ]] ; then
    echo running app script for $app...
    ANSIBLE_HOST_KEY_CHECKING=false ansible-playbook "${APP_PLAYBOOK:?not set}" --tags $app
  fi
done <<< $(git diff --name-only --diff-filter=ACMR HEAD~1 main | grep -oP '(?<=ansible/)apps/.*.ya?ml'| xargs awk -F: '/^[^ -]/{ print $1 }')

