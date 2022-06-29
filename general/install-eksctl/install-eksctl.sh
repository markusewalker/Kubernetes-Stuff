#!/bin/bash

# Authored By   : Markus Walker
# Date Modified : 9/4/21

# Description   : To install eksctl on the client machine. Checks to see
#		  if the machine is macOS or Linux.

# Install eksctl on a macOS client machine.
macosEKS() {
	echo -e "\nVerifying that Homebrew is installed..."
	# Verify if brew is installed. If not, install it. If so, run brew update.
	which brew
	if [[ $? != 0 ]]; then
		echo -e "\nSetting up Homebrew..."
		/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
	else
		echo -e "\nUpdating HomeBrew..."
		brew update
	fi

	echo -e "\nInstalling Weaveworks Homebrew tap..."
	brew tap weaveworks/tap

	echo -e "\nSeeing if eksctl is installed..."
	# Verify if eksctl is installed. If not, install it. If so, upgrade eksctl.
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

# Install eksctl on a Linux client machine.
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

[Usage Description]

Install eksctl on the current client machine. The script will run
a check to verify if this is a macOS or a Linux machine. 

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


# Main function for the script.
main() {
	OS=`uname -s`

	if [[ "${OS}" = "Darwin" ]]; then
		macosEKS
	elif [[ "${OS}" = "Linux" ]]; then
		linuxEKS
	fi
}

main "$@"
