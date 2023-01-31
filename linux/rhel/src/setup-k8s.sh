#!/bin/bash

# Authored by    : Markus Walker
# Date Modified  : 1/30/23

# Description    : To install/configure a K8s cluster on a single RHEL node.

removeDocker() {
	echo -e "\nRemoving any lingering Docker installations..."
	sudo yum remove -y docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine podman
    	sudo rm -rf /var/lib/docker
}

installDocker() {
    	echo -e "\nSetting up docker repo..."
	sudo yum install -y yum-utils
        sudo yum-config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo
        sudo yum install docker-ce docker-ce-cli containerd.io docker-compose-plugin

	systemctl start docker
	systemctl enable docker
}

setupDockerUser() {
        echo -e "\nAdding Docker as a non-root user to docker group..."
        groupadd docker
        usermod -aG docker ${USER}

	echo -e "\nChecking Docker status..."
	systemctl status docker

	echo -e "Turning off swap..."
	swapoff -a
}

enableBridgedTraffic() {
    	echo -e "\nAllow iptables to see bridged traffic..."
    	echo "net.bridge.bridge-nf-call-ip6tables = 1" | sudo tee -a /etc/sysctl.conf
		echo "net.bridge.bridge-nf-call-iptables = 1" | sudo tee -a /etc/sysctl.conf

    	sysctl --system
}

removeKubernetes() {
	echo -e "\nRemoving any lingering Kubernetes files..."
	yum remove -y kubelet kubeadm kubectl

	rm -rf /etc/kubernetes /var/lib/etcd /var/lib/kubelet ${HOME}/.kube /home/${USER}/.kube
}

installKubernetes() {
	echo -e "\nSetting up Kubernetes repo to install kubelet, kubeadm and kubectl..."
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
    	setenforce 0
    	sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

    	echo -e "\nInstalling kubelet, kubeadm, kubectl..."
    	sudo yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
		sudo systemctl enable --now kubelet
}

initializeControlPlane() {
	echo -e "\nResetting Kubernetes cluster..."
	sudo kubeadm reset -f
	
	echo -e "\nInitializing Control Plane..."
 	sudo kubeadm init --pod-network-cidr=10.244.0.0/16
    	
	echo -e "\nCopying kubeconfig into $HOME/.kube directory..."
	mkdir -p /home/${USER}/.kube
	sudo cp -i /etc/kubernetes/admin.conf /home/${USER}/.kube/config
	sudo chown $(id -u):$(id -g) -R /home/${USER}/.kube
}

applyKubeFlannel() {
	echo -e "\nApplying the Flannel CNI to the K8s cluster..."
	kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
}

taintMasterNode() {
	echo -e "\nUntainting the master node..."
	kubectl taint nodes --all node-role.kubernetes.io/control-plane-
}

checkPods() {
	echo -e "\nChecking pod status..."
	kubectl get pods -A
}

usage() {
	cat << EOF

$(basename $0)

This script will install a K8s cluster on a single RHEL node through kubeadm.

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
	echo -e "\e[96m================================================================"
	echo -e "\t\tSetup Kubernetes on RHEL/CentOS"
	echo -e "================================================================\n"
	echo -e "This script will setup kubeadm, kubectl, kubelet and initialize a control plane."
	echo -e "---------------------------------------------------------------------------------\e[0m\n"

	export SYSTEMD_PAGER=""
	export USER=""

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
