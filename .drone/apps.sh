#!/usr/bin/env bash

set -xeuo pipefail

APP_PLAYBOOK=playbooks/app.yml
APP=${APP:-}

run_playbook() {
	if [[ ${1:-} ]]; then
		echo running app script for $1...
		ANSIBLE_HOST_KEY_CHECKING=false ansible-playbook "${APP_PLAYBOOK:?not set}" -e "app=$1" -e "ci=true"
	fi
}

main() {
	pushd ansible

	git config --global --add safe.directory /drone/src
	echo "${ANSIBLE_VAULT_PASSWORD:?not set}" >$HOME/.ansible_vault
	if [ ! -r $HOME/.ssh/id_ed25519 ]; then
		mkdir -p $HOME/.ssh && echo "${DRONE_SSH_KEY:?not set}" >$HOME/.ssh/id_ed25519 && chmod -R 600 $HOME/.ssh
	fi

	if [[ $APP ]]; then
		run_playbook $APP
	else
		while read app; do
			run_playbook $app
		done <<<$(git diff --name-only --diff-filter=ACMR HEAD~1 main | grep -oP '(?<=ansible/)apps/[^/]*.ya?ml' | xargs awk -F: '/^[^ -]/{ print $1 }')
	fi
}

main $@
