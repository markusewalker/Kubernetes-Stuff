#!/bin/bash

# Authored by    : Markus Walker
# Date Modified  : 2/3/23

# Description    : To install/configure a multi-node K8s cluster using kubespray.

. /etc/os-release

prereqs() {
    echo -e "\nInstalling needed packages..."
    if [[ "${ID}" == "debian" || "${ID}" == "ubuntu" ]]; then
        sudo apt update
        sudo apt install python3-pip python3-virtualenv git -y
    
    elif [[ "${ID}" == "rhel" || "${ID}" == "fedora" ]]; then
        sudo yum install python3 python3-pip git -y
    
    elif [[ "${ID}" == "opensuse-leap" || "${ID}" == "sles" ]]; then
        sudo zypper install -y python3-pip python3-virtualenv git
    fi

    echo -e "\nInstalling kubectl..."
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    mkdir -p ~/.kube
    rm kubectl

    echo -e "\nPulling Kubespray repo..."
    git clone https://github.com/kubernetes-sigs/kubespray.git

    echo -e "\nInstalling Ansible and setting up a virtual environment..."
    VENVDIR=kubespray-venv
    KUBESPRAYDIR=kubespray
    ANSIBLE_VERSION=2.12

    if [[ "${ID}" == "rhel" || "${ID}" == "fedora" ]]; then
        python -m venv ${VENVDIR}
    
    else
        virtualenv  --python=$(which python3) ${VENVDIR}
    fi

    source ${VENVDIR}/bin/activate
    cd ${KUBESPRAYDIR}
    
    pip install -U -r requirements-${ANSIBLE_VERSION}.txt
    test -f requirements-${ANSIBLE_VERSION}.yml && ansible-galaxy role install -r requirements-${ANSIBLE_VERSION}.yml && ansible-galaxy collection -r requirements-${ANSIBLE_VERSION}.yml
}

deploy() {
    echo -e "\nSetting up the inventory..."
    cp -rfp inventory/sample inventory/mycluster
    declare -a IPS=(${NODE1_PRIVATE_IP} ${NODE2_PRIVATE_IP} ${NODE3_PRIVATE_IP})
    CONFIG_FILE=inventory/mycluster/hosts.yaml python3 contrib/inventory_builder/inventory.py ${IPS[@]}

    echo -e "\nModify the hosts.yaml file..."
    cat /dev/null > inventory/mycluster/hosts.yaml
    cat << EOF >> inventory/mycluster/hosts.yaml
all:
    hosts:
        node1:
            ansible_host: ${NODE1_PRIVATE_IP}
            ip: ${NODE1_PRIVATE_IP}
            access_ip: ${NODE1_PUBLIC_IP}
        node2:
            ansible_host: ${NODE2_PRIVATE_IP}
            ip: ${NODE2_PRIVATE_IP}
            access_ip: ${NODE2_PUBLIC_IP}
        node3:
            ansible_host: ${NODE3_PRIVATE_IP}
            ip: ${NODE3_PRIVATE_IP}
            access_ip: ${NODE3_PUBLIC_IP}
    children:
        kube_control_plane:
            hosts:
                node1:
        kube_node:
            hosts:
                node1:
                node2:
                node3:
        etcd:
            hosts:
                node1:
                node2:
                node3:
        k8s_cluster:
            children:
                kube-control_plane:
                kube_node:
        calico_rr:
            hosts: {}
EOF
    
    echo -e "\nUpdating etcd_access_address and etcd_events_access_address..."
    sed -i 's+etcd_access_address: "{{ access_ip | default(etcd_address) }}"+etcd_access_address: "{{ ip | default(etcd_address) }}"+g' roles/kubespray-defaults/defaults/main.yaml
    sed -i 's+etcd_events_access_address: "{{ access_ip | default(etcd_events_address) }}"+etcd_events_access_address: "{{ ip | default(etcd_events_address) }}"+g' roles/kubespray-defaults/defaults/main.yaml
    
    echo -e "\nRunning the Ansible playbook..."
    ansible-playbook -i inventory/mycluster/hosts.yaml --private-key="$SSH_KEY" --become --become-user=root cluster.yml
}

checkStatus() {
    echo -e "\nCopying kubeconfig into $HOME/.kube directory..."
    mkdir -p $HOME/.kube

    sudo ssh -i "${SSH_KEY}" "${USER}"@"${NODE1_PUBLIC_IP}" "sudo chown ${USER}:${GROUP} /etc/kubernetes/admin.conf"
    sudo ssh -i "${SSH_KEY}" "${USER}"@"${NODE1_PUBLIC_IP}" "cat /etc/kubernetes/admin.conf" > $HOME/.kube/config
    sudo chown ${USER}:${GROUP} $HOME/.kube/config
    sed -i "s+server: https://.*:6443+server: https://${NODE1_PUBLIC_IP}:6443+g" $HOME/.kube/config
    
    echo -e "\nChecking the status of the cluster..."
    kubectl get nodes | grep "<none>" | awk '{print $1}' | xargs -I {} kubectl label node {} node-role.kubernetes.io/worker=worker
    kubectl get nodes
}

usage() {
	cat << EOF

$(basename $0)

This script will install a multi-node K8s cluster on an SUSE, Ubuntu or RHEL node through kubespray. This

script assumes the following:

    * Separate client machine not part of the cluster is used to run this script
    * The client machine has Ansible installed
    * The client machine has Python 3.8+ installed

Examples of usage:

	$ ./$(basename $0)

EOF
}

while getopts ":h" opt; do
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
    
    echo -e "\e[96m================================================================"
    echo -e "\t\tSetup multi-node K8s cluster"
    echo -e "================================================================"
    echo -e "This script will setup a Kubernetes cluster using kubespray."
    echo -e "--------------------------------------------------------------\e[0m"
    
    export NODE1_PRIVATE_IP=""
    export NODE1_PUBLIC_IP=""
    export NODE2_PRIVATE_IP=""
    export NODE2_PUBLIC_IP=""
    export NODE3_PRIVATE_IP=""
    export NODE3_PUBLIC_IP=""
    export SSH_KEY=""
    export USER=""
    export GROUP=""
    
    prereqs
    deploy
    checkStatus
}

Main "$@"