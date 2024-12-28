#!/bin/bash

# Authored by    : Markus Walker
# Description    : To install/configure a multi-node K8s cluster using kubeadm.

WORKER_NODE=false
SYSTEMD_PAGER=""
USER=""
GROUP=""
SSH_KEY=""
SERVER_NODE=""

. /etc/os-release

removeDocker() {
	echo -e "\nRemoving any lingering Docker installations..."

	if [[ "${ID}" == "debian" || "${ID}" == "ubuntu" ]]; then
		sudo apt remove -y docker docker-engine docker.io containerd runc
	elif [[ "${ID}" == "rhel" || "${ID}" == "fedora" ]]; then
		sudo yum remove -y docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine podman
	elif [[ "${ID}" == "opensuse-leap" || "${ID}" == "sles" ]]; then
		sudo zypper remove -y docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine runc
	fi
}

installDocker() {
	echo -e "\nSetting up docker repo..."
	if [[ "${ID}" == "debian" || "${ID}" == "ubuntu" ]]; then
		sudo apt install -y ca-certificates curl gnupg lsb-release
		
		sudo mkdir -p /etc/apt/keyrings
		curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
		
		echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
			$(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
		
		sudo apt update
	
		echo -e "\nInstalling Docker..."
		sudo apt -y install docker-ce docker-ce-cli containerd.io docker-compose-plugin

	elif [[ "${ID}" == "rhel" || "${ID}" == "fedora" ]]; then
		sudo yum install -y yum-utils
        sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
        sudo yum install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
	

	elif [[ "${ID}" == "opensuse-leap" || "${ID}" == "sles" ]]; then
		sudo update-ca-certificates
		sudo zypper ref -s
		
		[[ "${ID}" == "opensuse-leap" ]] && sudo zypper addrepo https://download.opensuse.org/repositories/Virtualization:containers/openSUSE_Leap_15.4/Virtualization:containers.repo
		[[ "${ID}" == "sles" ]] && sudo zypper addrepo https://download.opensuse.org/repositories/security:SELinux/15.4/security:SELinux.repo
		
		sudo zypper ref -s
		sudo zypper install -y docker conntrack-tools
	fi
	
	sudo systemctl start docker
	sudo systemctl enable docker
}

setupDockerUser() {
	echo -e "\nAdding Docker as a non-root user to docker group..."
	sudo groupadd docker
	sudo usermod -aG docker ${USER}
	
	echo -e "\nChecking Docker status..."
	systemctl status docker
	
	echo -e "Turning off swap..."
	sudo swapoff -a
}

enableBridgedTraffic() {
	echo -e "\nAllow iptables to see bridged traffic..."
	echo "net.bridge.bridge-nf-call-ip6tables = 1" | sudo tee -a /etc/sysctl.conf
	echo "net.bridge.bridge-nf-call-iptables = 1" | sudo tee -a /etc/sysctl.conf
	
	sudo sysctl --system
}

removeKubernetes() {
	echo -e "\nRemoving any lingering Kubernetes files..."
	if [[ "${ID}" == "debian" || "${ID}" == "ubuntu" ]]; then
		sudo apt remove -y kubelet kubeadm kubectl
	elif [[ "${ID}" == "rhel" || "${ID}" == "fedora" ]]; then
		sudo yum remove -y kubelet kubeadm kubectl
	fi

	sudo rm -rf /etc/kubernetes /var/lib/etcd /var/lib/kubelet $HOME/.kube /var/lib/docker /etc/containerd/config.toml
	sudo systemctl restart containerd
}

installKubernetes() {
	echo -e "\nSetting up Kubernetes repo to install kubelet, kubeadm and kubectl..."
	if [[ "${ID}" == "debian" || "${ID}" == "ubuntu" ]]; then
		sudo apt update
		sudo apt install -y apt-transport-https ca-certificates curl
		
		sudo curl -fsSLo /etc/apt/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
		echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
		
		sudo apt update
		echo -e "\nInstalling kubelet, kubeadm and kubectl..."
		sudo apt install -y kubelet kubeadm kubectl
		sudo apt-mark hold kubelet kubeadm kubectl

	elif [[ "${ID}" == "rhel" || "${ID}" == "fedora" ]]; then
    	cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-\$basearch
enabled=1
gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kubelet kubeadm kubectl
EOF

		echo -e "\nSetting SELinux to permissive status..."
		sudo setenforce 0
		sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
		
		echo -e "\nInstalling kubelet, kubeadm, kubectl..."
		sudo yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
		sudo systemctl enable kubelet
		sudo systemctl start kubelet

	else
		CNI_PLUGINS_VERSION="v1.1.1"
		ARCH="amd64"
		DEST="/opt/cni/bin"
		sudo mkdir -p ${DEST}
		curl -L "https://github.com/containernetworking/plugins/releases/download/${CNI_PLUGINS_VERSION}/cni-plugins-linux-${ARCH}-${CNI_PLUGINS_VERSION}.tgz" | sudo tar -C ${DEST} -xz
		
		DOWNLOAD_DIR="/usr/local/bin"
		sudo mkdir -p ${DOWNLOAD_DIR}
		
		CRICTL_VERSION="v1.26.0"
		curl -L "https://github.com/kubernetes-sigs/cri-tools/releases/download/${CRICTL_VERSION}/crictl-${CRICTL_VERSION}-linux-${ARCH}.tar.gz" | sudo tar -C ${DOWNLOAD_DIR} -xz
		
		RELEASE=$(curl -sSL https://dl.k8s.io/release/stable.txt)
		cd ${DOWNLOAD_DIR}
		sudo curl -L --remote-name-all https://dl.k8s.io/release/${RELEASE}/bin/linux/${ARCH}/{kubeadm,kubelet}
		sudo chmod +x {kubeadm,kubelet}
		
		RELEASE_VERSION="v0.4.0"
		curl -sSL "https://raw.githubusercontent.com/kubernetes/release/${RELEASE_VERSION}/cmd/kubepkg/templates/latest/deb/kubelet/lib/systemd/system/kubelet.service" | sed "s:/usr/bin:${DOWNLOAD_DIR}:g" | sudo tee /etc/systemd/system/kubelet.service
		sudo mkdir -p /etc/systemd/system/kubelet.service.d
		curl -sSL "https://raw.githubusercontent.com/kubernetes/release/${RELEASE_VERSION}/cmd/kubepkg/templates/latest/deb/kubeadm/10-kubeadm.conf" | sed "s:/usr/bin:${DOWNLOAD_DIR}:g" | sudo tee /etc/systemd/system/kubelet.service.d/10-kubeadm.conf

		cd $HOME
		sudo systemctl enable kubelet
		sudo systemctl start kubelet
	fi
}

initializeControlPlane() {
	echo -e "\nResetting Kubernetes cluster..."
	sudo kubeadm reset -f
	
	echo -e "\nInitializing Control Plane..."
 	sudo kubeadm init --pod-network-cidr=192.168.0.0/16
    	
	echo -e "\nCopying kubeconfig into $HOME/.kube directory..."
	mkdir -p $HOME/.kube
	sudo chown ${USER}:${GROUP} /etc/kubernetes/admin.conf
	cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
	chown ${USER}:${GROUP} $HOME/.kube/config
}

applyCNI() {
	echo -e "\nApplying the Calico CNI to the cluster..."
	kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/manifests/tigera-operator.yaml
	kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/manifests/custom-resources.yaml
}

taintMasterNode() {
	echo -e "\nUntainting the master node..."
	kubectl taint nodes --all node-role.kubernetes.io/control-plane-
}

checkStatus() {
	echo -e "\nChecking cluster status..."
	kubectl get nodes
}

joinWorkerNodes() {
	export TOKEN=$(sudo ssh -i ${SSH_KEY} ${USER}@${SERVER_NODE} "kubeadm token create --print-join-command")
	
	echo -e "\nJoining worker node to the cluster..."
	sudo ${TOKEN}
}

usage() {
	cat << EOF

========================================================
		Setup multi-node K8s cluster
========================================================

This script will install a multi-node K8s cluster on an SUSE, Ubuntu or RHEL node through kubeadm. You must meet the

follow prerequisites:

	* Sudo access for the user running this script
	* User must be the same on all nodes

For worker nodes, ensure that you specify the -w flag so that only the worker node setup is performed.

Examples of usage:

* To setup a control plane node:

	$ ./$(basename $0)

* To setup a worker node:

	$ ./$(basename $0) -w
	
EOF
}

while getopts ":hw" opt; do
	case ${opt} in
		h)
			usage
			exit 0;;
		w)
			WORKER_NODE=true
			removeDocker
			installDocker
			setupDockerUser
			enableBridgedTraffic
			removeKubernetes
			installKubernetes
			joinWorkerNodes
			exit 0;;
		*)
			echo "Invalid option: $OPTARG. Valid option(s) are [-h], [-w]." 2>&1
			exit 1;;
	esac
done

Main() {
	removeDocker
	installDocker
	setupDockerUser
	enableBridgedTraffic
	removeKubernetes
	installKubernetes
	initializeControlPlane
	applyCNI
	taintMasterNode
	checkStatus
}

Main "$@"
