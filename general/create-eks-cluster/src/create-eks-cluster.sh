#!/usr/bin/bash

# Authored By   : Markus Walker
# Date Modified : 1/30/23

# Description   : To create an EKS cluster using eksctl.

macosEKS() {
	echo -e "\nVerifying that Homebrew is installed..."
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

macAWSCLI() {
    echo -e "\nDownloading the AWS CLI..."
    curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"

    echo -e "\nInstalling the AWS CLI..."
    sudo installer -pkg ./AWSCLIV2.pkg -target /

    echo -e "\nVerifying the AWS CLI was installed..."
    aws --version
}

linuxAWSCLI() {
    echo -e "\nDownloading the AWS CLI..."
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"

    echo -e "\nUnzipping the AWS CLI..."
    unzip awscliv2.zip

    echo -e "\nInstalling the AWS CLI..."
    sudo ./aws/install

    echo -e "\nVerifying the AWS CLI was installed..."
    aws --version
}

createEKSCluster() {
    echo -e "\nConfiguring AWS credentials..."
    aws configure set aws_access_key_id "${ACCESS_KEY_ID}"
    aws configure set aws_secret_access_key "${SECRET_ACCESS_KEY}"
    aws configure set default.region "${AWS_DEFAULT_REGION}"

    echo -e "\nCreating EKS cluster..."
    eksctl create cluster --name "${NAME}" \
                          --region "${AWS_DEFAULT_REGION}" \
                          --version "${VERSION}" \
                          --nodegroup-name "${NODE_GROUP}" \
                          --node-type "${NODE_TYPE}" \
                          --nodes "${NODES}" \
                          --nodes-min "${NODES_MIN}" \
                          --nodes-max "${NODES_MAX}" \
                          --vpc-public-subnets="${VPC_PUBLIC_SUBNETS}"
}

usage() {
	cat << EOF

$(basename "$0")

This script will create an Amazon EKS cluster using the eksctl tool. In addition it performs the following setup tasks:

    * Install the eksctl tool
    * Install the AWS CLI
    * Configures AWS credentials
    * Create an EKS cluster

This script assumes that the tools kubectl and unzip are already installed on the client machine.

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
    echo -e "\tCreate EKS Cluster"
    echo -e "========================================"
    echo -e "This script will create an Amazon EKS cluster."
    echo -e "-----------------------------------------------\x1B[0m"

    OS=`uname -s`

	if [[ "${OS}" = "Darwin" ]]; then
		macosEKS
        macAWSCLI
	elif [[ "${OS}" = "Linux" ]]; then
		linuxEKS
        linuxAWSCLI
	fi

    # Export variables to be used in the createEKSCluster() function. You will need to fill these values in appropriately.
    export ACCESS_KEY_ID=""
    export SECRET_ACCESS_KEY=""
    export AWS_DEFAULT_REGION=""
    export VERSION=""
    export NAME=""
    export NODE_GROUP=""
    export NODE_TYPE=""
    export NODES=
    export NODES_MIN=
    export NODES_MAX=
    export VPC_PUBLIC_SUBNETS=""

    createEKSCluster
}

Main "$@"
