#!/bin/bash

# Authored By   : Markus Walker
# Date Modified : 1/30/23

# Description   : To remove a worker node from the K8s cluster.

displayNodes() {
	echo -e "\nDisplaying nodes in the K8s cluster..."
	kubectl get nodes
}

removeNode() {
	echo -e "\nRemoving worker node ${NODE}..."

	kubectl drain ${NODE} --ignore-daemonsets --delete-emptydir-data
	kubectl uncordon ${NODE}
	kubectl delete node ${NODE}

	echo -e "\nDisplaying K8s cluster..."
	kubectl get nodes
}

usage() {
	cat << EOF

$(basename $0)

This is an interactive script that will remove a worker node from your K8s cluster. It performs the following tasks:

	* Displays the current nodes in the K8s cluster
	* Prompts which worker node to remove
	* Drains, uncordon and deletes the worker node

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
			echo "Invalid option: $OPTARG. Valid options are [-h]." 2>&1
			exit 1
			;;
	esac
done

Main() {
	echo -e "\x1B[96m===================================================================="
	echo -e "\t\tRemove Worker Node From Cluster"
	echo -e "===================================================================="
	echo -e "This script will remove a worker node from your Kubernetes cluster."
	echo -e "-------------------------------------------------------------------\x1B[0m\n"

	displayNodes

	read -p "Please enter the node you wish to remove: " NODE
        echo -e "You selected to remove worker node: ${NODE}"

	removeNode
}

Main "$@"
