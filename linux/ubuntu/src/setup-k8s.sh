#!/bin/bash

# Authored by    : Markus Walker
# Date Modified  : 1/30/23

# Description    : To install/configure a K8s cluster on a single Ubuntu node.

removeDocker() {
	echo -e "\nRemoving any lingering Docker installations..."
    	sudo apt remove docker docker-engine docker.io containerd runc -y
    	sudo rm -rf /var/lib/docker
}

installDocker() {
    	echo -e "\nSetting up docker repo..."
    	sudo apt-get install ca-certificates curl gnupg lsb-release -y

		sudo mkdir -p /etc/apt/keyrings
		curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  
    	echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  				$(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    	sudo apt update

    	echo -e "\nInstalling Docker..."
    	sudo apt install docker-ce docker-ce-cli containerd.io docker-compose-plugin
}

setupDockerUser() {
        echo -e "\nAdding Docker as a non-root user to docker group..."
        groupadd docker
        usermod -aG docker ${USER}

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
	sudo apt remove -y kubelet kubeadm kubectl

	sudo rm -rf /etc/kubernetes /var/lib/etcd /var/lib/kubelet ${HOME}/.kube /home/${USER}/.kube
}

installKubernetes() {
    	echo -e "\nSetting up Kubernetes repo to install kubelet, kubeadm and kubectl..."
		sudo apt update
		sudo apt install -y apt-transport-https ca-certificates curl

		sudo curl -fsSLo /etc/apt/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
    	echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

    	sudo apt update

    	echo -e "\nInstalling kubelet, kubeadm and kubectl..."
    	sudo apt install -y kubelet kubeadm kubectl
    	sudo apt-mark hold kubelet kubeadm kubectl
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

This script will install a K8s cluster on a single Ubuntu node through kubeadm.

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
	echo -e "\t\tSetup Kubernetes on Ubuntu"
	echo -e "================================================================"
	echo -e "This script will setup kubeadm, kubectl, kubelet and initialize a control plane."
	echo -e "---------------------------------------------------------------------------------\e[0m"

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
