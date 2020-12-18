#!/bin/bash

# Authored by   : Markus Walker
# Date Modified : 12/17/20

# Description   : To setup kubectl minikube on a local macOS system. This script assumes
#                 that your system meets the required system requirements. Please verify 
#                 at https://minikube.sigs.k8s.io/docs/start/. 

if [[ $(id -u) == 0 ]]; 
then
	echo "ERROR. Please be sure that you are NOT running as root or with sudo privileges!" 2>&1
	exit 1
fi

# Function to install kubectl, if not already installed on the machine.
installKubectl() {
	echo -e "\nChecking to see if kubectl is already installed..."
	sleep 2

	if [[ -n $(kubectl version --client) ]]; 
	then
		echo -e "\nkubectl is already installed."
	else
		echo -e "\nkubectl is not installed. Installing now..."
		sleep 2
		brew install kubectl
	fi
}

# Function to install minikube, if not already installed on the machine.
installMinikube() {
	echo -e "\nChecking to see if minikube is already installed..."
	sleep 2

	if [[ -n $(minikube status) ]];
	then
		echo -e "\nminikube is already installed."
	else
		echo -e "\nminikube is not installed. Installing now..."
		sleep 2
		brew install minikube
		
		echo -e "\nChecking the status of minikube..."
		minikube status
	fi
}

# Function to start up minikube, after a successful installation...
startMinikube() {
	echo -e "\nStarting minikube..."
	minikube start
}

# Function to check the status of the pods.
checkPods() {
	echo -e "\nChecking the K8s pods status..."
	sleep 2
	kubectl get po -A
}

usage() {
	cat << EOF
-----------------------------------
Install Kubectl and minikube Script
-----------------------------------
This script will install kubectl and minikube on your local macOS cluster. The script will verify first
if the tools are already installed on your system. If they're not installed, it will utilize brew to install
them.

Please ensure that you meet the system requirements at https://minikube.sigs.k8s.io/docs/start/ before
attempting to use the script.
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
	echo "This script installs kubectl and minikube on a local macOS system."
	echo -e "------------------------------------------------------------------"

	# Update Homebrew, if needed.
	echo -e "Updating Homebrew..."
	brew update

	installKubectl
	installMinikube
	startMinikube
	checkPods
}

Main "$@"
