#!/usr/bin/env bash
set -xeuo pipefail

echo "${ANSIBLE_VAULT_PASSWORD:?not set}" >$HOME/.ansible_vault

if [[ ${DEBUG:-} ]]; then
	sleep 600
fi

while read file; do
	echo checking file $file...
	if [[ "$file" =~ ansible/(roles|playbooks|tasks)/.*\.ya?ml ]]; then
		pushd ansible
		ansible-lint -v -c .ansible-lint "${file#*/}"
		popd
	fi
	if [[ "$file" =~ ansible/.*\.ya?ml$ ]]; then
		yamllint -s -c .yamllint "$file"
	fi
done <<<$(git diff --name-only --diff-filter=ACMR HEAD~1 main)
