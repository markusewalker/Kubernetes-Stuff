#!/bin/bash

# Authored By   : Markus Walker
# Date Modified : 1/30/23

# Description   : To install eksctl on the client machine.

macEKS() {
	echo -e "\nVerifying that Homebrew is installed..."
	which brew
	[[ $? != 0 ]] && echo -e "\nHomebrew is not installed. Please install Homebrew before running this script." && exit 1

	echo -e "\nInstalling Weaveworks Homebrew tap..."
	brew tap weaveworks/tap

	echo -e "\nSeeing if eksctl is installed..."
	eksctl version
	if [[ $? != 0 ]]; then
		echo -e "\nInstalling eksctl..."
		brew install eksctl

		echo -e "\nVerifying eksctl is installed..."
		eksctl version
	else
		echo -e "\nUpgrading eksctl..."
		brew upgrade eksctl && brew link --overwrite eksctl
	fi
}

linuxEKS() {
	echo -e "\nDownload latest version of eksctl..."
	curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp

	echo -e "\nMove binary to /usr/local/bin..."
	sudo mv /tmp/eksctl /usr/local/bin

	echo -e "\nVerifying eksctl is installed..."
	eksctl version
}

usage() {
	cat << EOF

$(basename $0)

Install eksctl on the current client machine. The script works on Linux and macOS.

Examples of usage:

	$ ./$(basename $0)

EOF
}

while getopts "h" opt; do
	case ${opt} in
		h)
			usage
			exit 0;;
	esac
done

echo -e "\x1B[96m============================================"
echo -e "\t\tSetup eksctl"
echo -e "============================================"
echo -e "This script will install eksctl on a Linux or macOS machine."
echo -e "------------------------------------------------------------------\x1B[0m\n"


Main() {
	OS=`uname -s`

	[[ "${OS}" = "Darwin" ]] && macEKS
	[[ "${OS}" = "Linux" ]] && linuxEKS
}

Main "$@"
