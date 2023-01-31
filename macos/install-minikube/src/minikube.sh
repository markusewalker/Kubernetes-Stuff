#!/bin/bash

# Authored by   : Markus Walker
# Date Modified : 1/30/23

# Description   : To setup kubectl minikube on a local macOS system.

if [[ $(id -u) == 0 ]]; 
then
	echo "ERROR. Please be sure that you are NOT running as root or with sudo privileges!" 2>&1
	exit 1
fi

installKubectl() {
	echo -e "\nChecking to see if kubectl is already installed..."

	[[ -n $(kubectl version --client) ]] && echo -e "\nkubectl is already installed." 
	[[ -z $(kubectl version --client) ]] && echo -e "\nkubectl is not installed. Installing now..." && brew install kubectl
}

installMinikube() {
	echo -e "\nChecking to see if minikube is already installed..."

	[[ -n $(minikube status) ]] && echo -e "\nminikube is already installed."
	[[ -z $(minikube status) ]] && echo -e "\nminikube is not installed. Installing now..." && brew install minikube
		
		echo -e "\nChecking the status of minikube..."
		minikube status
}

startMinikube() {
	echo -e "\nStarting minikube..."
	minikube start
}

checkPods() {
	echo -e "\nChecking the K8s pods status..."
	kubectl get pods -A
}

usage() {
	cat << EOF

$(basename $0)

This script will install kubectl and minikube on your local macOS cluster. This script assumes Homebrew is installed.

Please ensure that you meet the system requirements at https://minikube.sigs.k8s.io/docs/start.

Examples of usage:

	$ ./$(basename $0)

EOF
}

while getopts ":h" opt; do
        case ${opt} in
                h)
                        usage
                        exit 0
                        ;;
                *)
			echo "Invalid option: $OPTARG. Valid option(s) are [-h]." 2>&1
                        exit 1
                        ;;
        esac
done

Main() {
	echo -e "\x1B[96m======================================="
	echo -e "\tInstall minikube on macOS"
	echo -e "=======================================\x1B[0m"
	echo -e "This script installs kubectl and minikube on a local macOS system."
	echo -e "--------------------------------------------------------------------"

	installKubectl
	installMinikube
	startMinikube
	checkPods
}

Main "$@"
