#!/bin/bash

# Authored by    : Markus Walker
# Date Modified  : 2/5/21

# Description    : To install K8s tools on an RHEL 7.x & 8.x system and to initialize a control plane.
#		   This script assumes that you meet the system requirements at 
#                  https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/

# Verify that the script is being ran as the root or has sudo privileges.
if [[ $(id -u) != 0 ]];
then
	echo "ERROR. You MUST run as the root user or have sudo privileges!" 2>&1
   	exit 1
fi

# Function to remove Docker CE. Doing this to ensure that we have a clean installation from start to finish...
removeDocker() {
	echo -e "\nRemoving any lingering Docker installations..."
	sleep 2
	yum remove -y docker docker-common docker-selinux docker-engine-selinux docker-engine docker-ce
    	rm -rf /var/lib/docker
}

# Function to install Docker CE on the system.
installDocker() {
    	echo -e "\nSetting up docker repo..."
	sleep 2
	yum install -y yum-utils device-mapper-persistent-data lvm2
        yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
        yum install -y https://download.docker.com/linux/centos/7/x86_64/stable/Packages/containerd.io-1.2.6-3.3.el7.x86_64.rpm
        yum install -y docker-ce

	systemctl start docker
	systemctl enable docker
}

# Function to setup a Docker group and add the specified user into that group.
setupDockerUser() {
        echo -e "\nAdding Docker as a non-root user to docker group..."
	sleep 2
        groupadd docker
        usermod -aG docker ${SUSER}
        #newgrp docker

	echo -e "\nChecking Docker status..."
	sleep 2
	systemctl status docker

	echo -e "Turning off swap..."
	sleep 2
	swapoff -a
}

# Function to let iptables see bridged traffic.
enableBridgedTraffic() {
    	echo -e "\nAllow iptables to see bridged traffic..."
    	cat <<EOF > /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
    	sysctl --system
}

# Function to remove any lingering Kubernetes on the system.
removeKubernetes() {
	echo -e "\nRemoving any lingering Kubernetes files..."
	sleep 2
	yum remove -y kubelet kubeadm kubectl

	rm -rf /etc/kubernetes /var/lib/etcd /var/lib/kubelet ${HOME}/.kube /home/${SUSER}/.kube
}

# Function install kubelet, kubeadm, kubectl
installKubernetes() {
	echo -e "\nSetting up Kubernetes repo to install kubelet, kubeadm and kubectl..."
    	sleep 2
    	cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-\$basearch
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kubelet kubeadm kubectl
EOF

    	echo -e "Successfully set up Kubernetes repo!"

    	echo -e "\nSetting SELinux to permissive status..."
    	sleep 2
    	setenforce 0
    	sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

    	echo -e "\nSuccessfully set SELinux to permissive status!"

    	echo -e "\nInstalling kubelet, kubeadm, kubectl..."
    	sleep 2
    	yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
    	systemctl enable --now kubelet
    	systemctl status kubelet
}

# Function to initialize the control plane that the master and worker nodes will be using.
initializeControlPlane() {
    	echo -e "\nResetting Kubernetes cluster..."
	sleep 2
    	kubeadm reset -f

    	echo -e "\nInitializing Control Plane..."
	sleep 2
 	kubeadm init --pod-network-cidr=10.244.0.0/16

	echo -e "\nCopying configuration for the root user..."
	sleep 2
	export KUBECONFIG=/etc/kubernetes/admin.conf
	cp -i ${KUBECONFIG} ${HOME}/.kube/config
    	
	echo -e "\nCopying configuration for the ${SUSER} user..."
	sleep 2

    	export RUN_AS_USER="sudo -u ${SUSER}"
    	${RUN_AS_USER} mkdir -p /home/${SUSER}/.kube
    	cp -i /etc/kubernetes/admin.conf /home/${SUSER}/.kube/config
    	chown ${SUSER}:${SUSER} -R /home/${SUSER}/.kube
}

# Function to apply the Flannel CNI to the newly created K8s cluster.
applyKubeFlannel() {
    	echo -e "\nApplying the Flannel CNI to the K8s cluster..."
	sleep 2
    	kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
}

# Function to taint the master node to prevent pods from coming to the master node that don't tolerate taints.
taintMasterNode() {
    	echo -e "\nUntainting the master node..."
	sleep 2
    	kubectl taint nodes --all node-role.kubernetes.io/master-
}

# Function to check pods
checkPods() {
	echo -e "\nChecking pod status..."
	sleep 2
	kubectl get pods -A
}

usage() {
	cat << EOF
--------------------------
Setup Kubernetes on RHEL
--------------------------
This script will install Kubernetes tools kubeadm, kubectl, kubelet on an RHEL 7.x or CentOS 7.x system. The script assumes that you
meet the system requirements found here: https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/.

Additionally, this script will initialize a control plane after the K8s tools have been properly installed.

You will be prompted at the beginning for a non-root user account that you would like to have Docker/Kubernetes access.
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
	echo -e "\e[96m================================================================"
	echo -e "\t\tSetup Kubernetes on RHEL/CentOS"
	echo -e "================================================================\n"
	echo -e "This script will setup kubeadm, kubectl, kubelet and initialize a control plane."
	echo -e "---------------------------------------------------------------------------------\e[0m\n"

	# Update the system, if needed.
	yum update -y
	export SYSTEMD_PAGER=""

	read -p "Enter in the non-user account that you would like to have Docker/Kubernetes access: " SUSER

	removeDocker
	installDocker
	setupDockerUser
	enableBridgedTraffic
	removeKubernetes
	installKubernetes
	initializeControlPlane
	applyKubeFlannel
	taintMasterNode
	checkPods
}

Main "$@"
