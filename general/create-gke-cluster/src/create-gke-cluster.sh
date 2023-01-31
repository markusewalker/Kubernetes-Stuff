#!/usr/bin/bash

# Authored By   : Markus Walker
# Date Modified : 1/30/22

# Description   : To create an GKE cluster using the gcloud CLI.

debianInstall() {
    echo -e "\nInstalling prerequisities..."
    sudo apt-get install apt-transport-https ca-certificates gnupg -y

    echo -e "\nAdding gcloud CLI distribution URI..."
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list

    echo -e "\nImporting GCP's public key..."
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -

    echo -e "\nInstall gcloud..."
    sudo apt-get update && sudo apt-get install google-cloud-cli

    echo -e "\nVerifying gcloud installation..."
    gcloud version
}

fedoraInstall() {
    echo -e "\nAdding gcloud CLI repository..."
    if [[ "${VERSION_ID}" == 8.* ]]; 
	then	
		sudo tee -a /etc/yum.repos.d/google-cloud-sdk.repo << EOM
        [google-cloud-cli]
        name=Google Cloud CLI
        baseurl=https://packages.cloud.google.com/yum/repos/cloud-sdk-el8-x86_64
        enabled=1
        gpgcheck=1
        repo_gpgcheck=0
        gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
            https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOM
	elif [[ "${VERSION_ID}" == 7.* ]]; 
	then
		sudo tee -a /etc/yum.repos.d/google-cloud-sdk.repo << EOM
        [google-cloud-cli]
        name=Google Cloud CLI
        baseurl=https://packages.cloud.google.com/yum/repos/cloud-sdk-el7-x86_64
        enabled=1
        gpgcheck=1
        repo_gpgcheck=0
        gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
            https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOM
	fi

    echo -e "\nInstalling prerequisities..."
    sudo dnf install libxcrypt-compat.x86_64 -y

    echo -e "\nInstalling gcloud..."
    sudo dnf install google-cloud-cli -y

    echo -e "\nVerifying gcloud installation..."
    gcloud version
}

suseInstall() {
    echo -e "\nAdding gcloud CLI repository..."
    sudo tee -a /etc/zypp/repos.d/google-cloud-sdk.repo << EOM
        [google-cloud-sdk]
        name=Google Cloud SDK
        baseurl=https://packages.cloud.google.com/yum/repos/cloud-sdk-el8-x86_64
        enabled=1
        gpgcheck=1
        repo_gpgcheck=1
        gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
            https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOM

    echo -e "\nRefreshing zypper..."
    zypper ref -f

    echo -e "\nInstall gcloud..."
    zypper install -y google-cloud-sdk

    echo -e "\nVerifying gcloud installation..."
    gcloud version
}

createGKECluster() {
    # This requires some interaction from the user. The alternative is using a serviceaccounttoken via a .PEM file, so I would rather do this...
    echo -e "\nLogging into GCP..."
    gcloud auth login --no-launch-browser

    echo -e "\nSetting project..."
    gcloud config set project "${PROJECT_ID}"

    echo -e "\nCreating GKE cluster..."
    gcloud container clusters create "${CLUSTER_NAME}" \
                                     --cluster-version "${VERSION}" \
                                     --zone "${ZONE}" \
                                     --num-nodes "${NUM_NODES}" \
                                     --machine-type "${MACHINE_TYPE}" \
                                     --shielded-secure-boot \
				     --shielded-integrity-monitoring

    echo -e "\nVerifying the GKE cluster was created..."
    kubectl get nodes
}

usage() {
	cat << EOF

$(basename "$0")

This script will create an Google GKE cluster using the gcloud tool. In addition, it performs the following setup tasks:

    * Install the gcloud tool
    * Creates the GKE cluster

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
    echo -e "\tCreate GKE Cluster"
    echo -e "========================================"
    echo -e "This script will create an Google GKE cluster."
    echo -e "-----------------------------------------------\x1B[0m"

    . /etc/os-release

    [[ "${ID}" == "ubuntu" || "${ID}" == "debian" ]] && debianInstall
    [[ "${ID}" == "rhel" || "${ID}" == "fedora"  ]] && fedoraInstall
    [[ "${ID}" == "opensuse-leap" || "${ID}" == "sles" ]] && suseInstall

    # Export variables to be used in the createGKECluster() function. You will need to fill these in appropriately.
    export PROJECT_ID=""
    export CLUSTER_NAME=""
    export VERSION=""
    export ZONE=""
    export NUM_NODES=
    export MACHINE_TYPE=""

    createGKECluster
}

Main "$@"
