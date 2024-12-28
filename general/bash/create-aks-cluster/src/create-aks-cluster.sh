#!/usr/bin/bash

# Authored By   : Markus Walker
# Description   : To create an AKS cluster using the az CLI.

OS=`uname -s`
RESOURCE_GROUP=""
CLUSTER_NAME=""
NODE_COUNT=""
NODE_SIZE=""
APP_ID=""
CLIENT_SECRET=""
TENANT_ID=""

debianInstall() {
    echo -e "\nInstalling Azure CLI..."
    curl -sL https://aka.ms/InstallAzureCLIDeb | bash
}

fedoraInstall() {
    echo -e "\nImporting Microsoft repository key..."
    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc

    if [[ "${VERSION_ID}" == 8.* ]]; then
        echo -e "\nAdding packages-microsoft-com-prod repository..."
        sudo dnf install -y https://packages.microsoft.com/config/rhel/8/packages-microsoft-prod.rpm
    elif [[ "${VERSION_ID}" == 7.* ]]; then
        echo -e "\nAdding azure-cli repository..."
        echo -e "[azure-cli]
        name=Azure CLI
        baseurl=https://packages.microsoft.com/yumrepos/azure-cli
        enabled=1
        gpgcheck=1
        gpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/yum.repos.d/azure-cli.repo
    fi

    echo -e "\nInstalling Azure CLI..."
    sudo dnf install azure-cli -y
}

suseInstall() {
    echo -e "\nInstalling curl..."
    sudo zypper install -y curl

    echo -e "\nImporting Microsoft repository key..."
    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc

    echo -e "\nInstalling Azure CLI..."
    sudo zypper install -y azure-cli
}

macInstall() {
    echo -e "\nInstalling Azure CLI..."
    brew update && brew install azure-cli
}

createAKSCluster() {
    echo -e "\nLogging into Azure..."
    az login --service-principal --username "${APP_ID}" --password "${CLIENT_SECRET}" --tenant "${TENANT_ID}"

    echo -e "\nCreating AKS cluster..."
    az aks create --resource-group "${RESOURCE_GROUP}" --name "${CLUSTER_NAME}" --node-count "${NODE_COUNT}" --node-vm-size "${NODE_SIZE}" --enable-addons monitoring --generate-ssh-keys

    echo -e "\nConnecting to the AKS cluster..."
    az aks get-credentials --resource-group "${RESOURCE_GROUP}" --name "${CLUSTER_NAME}"

    echo -e "\nVerifying the AKS cluster was created..."
    kubectl get nodes
}

usage() {
	cat << EOF

========================================
         Create AKS Cluster
========================================

This script will create an Azure AKS cluster using the az tool. In addition, it performs the following setup tasks:

    * Install the az tool
    * Creates the AKS cluster

This script assumes that the tool kubectl is already installed on the client machine.

USAGE: % ./$(basename "$0") [options]

OPTIONS:
	-h	-> Usage

EXAMPLES OF USAGE:

* Run script interactively
	
	$ ./$(basename "$0")

EOF
}

while getopts "h" opt; do
	case ${opt} in
		h)
			usage
			exit 0;;
        *)
            echo "Invalid option: $OPTARG. Valid option(s) are [-h]." 2>&1
            exit 1;;
    esac
done

Main() {
    if [[ "${OS}" == "Linux" ]]; then
        . /etc/os-release

        [[ "${ID}" == "ubuntu" || "${ID}" == "debian" ]] && debianInstall
        [[ "${ID}" == "rhel" || "${ID}" == "fedora"  ]] && fedoraInstall
        [[ "${ID}" == "opensuse-leap" || "${ID}" == "sles" ]] && suseInstall
        
    elif [[ "${OS}" == "Darwin" ]]; then
        macInstall
    fi

    createAKSCluster
}

Main "$@"
