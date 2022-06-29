#!/usr/bin/bash

# Authored By   : Markus Walker
# Date Modified : 6/28/22

# Description   : To create an AKS cluster using the az CLI.

# Function to install az on Debian systems.
debianInstall() {
    echo -e "\nInstalling Azure CLI..."
    curl -sL https://aka.ms/InstallAzureCLIDeb | bash
}

# Function to install az on Fedora, RHEL systems.
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

# Function to install az on openSUSE, SLES systems.
suseInstall() {
    echo -e "\nInstalling curl..."
    sudo zypper install -y curl

    echo -e "\nImporting Microsoft repository key..."
    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc

    echo -e "\nInstalling Azure CLI..."
    sudo zypper install -y azure-cli
}

# Function to install az on macOS systems.
macInstall() {
    echo -e "\nInstalling Azure CLI..."
    brew update && brew install azure-cli
}

# Create an AKS cluster.
createAKSCluster() {
    # There isn't a good way to login silently while preserving the username....so this has to be a bit interactive to avoid permission denial error.
    echo -e "\nLogging into Azure..."
    az login

    echo -e "\nCreating AKS cluster..."
    az aks create --resource-group "${RESOURCE_GROUP}" --name "${CLUSTER_NAME}" --node-count "${NODE_COUNT}" --node-vm-size "${NODE_SIZE}" --enable-addons monitoring --generate-ssh-keys

    echo -e "\nConnecting to the AKS cluster..."
    az aks get-credentials --resource-group "${RESOURCE_GROUP}" --name "${CLUSTER_NAME}"

    echo -e "\nVerifying the AKS cluster was created..."
    kubectl get nodes
}

usage() {
	cat << EOF

$(basename "$0")

This script will create an Azure AKS cluster using the az tool. In addition, it performs the following setup tasks:

    - Install the az tool
    - Creates the AKS cluster

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
    echo -e "\x1B[96m========================================"
    echo -e "\tCreate AKS Cluster"
    echo -e "========================================"
    echo -e "This script will create an Azure AKS cluster."
    echo -e "-----------------------------------------------\x1B[0m"

    OS=`uname -s`

    if [[ "${OS}" == "Linux" ]]; then
        echo -e "\nSourcing the OS and version of the Linux distro..."
        . /etc/os-release

        if [[ "${ID}" == "ubuntu" || "${ID}" == "debian" ]]; then
            debianInstall
        elif [[ "${ID}" == "rhel" || "${ID}" == "fedora"  ]]; then
            fedoraInstall
        elif [[ "${ID}" == "opensuse-leap" ]]; then
            suseInstall
        fi
    elif [[ "${OS}" == "Darwin" ]]; then
        macInstall
    fi

    # Export variables to be used in the createAKSCluster() function. You will need to fill these in appropriately.
    export RESOURCE_GROUP=""
    export CLUSTER_NAME=""
    export NODE_COUNT=
    export NODE_SIZE=""

    createAKSCluster
}

Main "$@"
