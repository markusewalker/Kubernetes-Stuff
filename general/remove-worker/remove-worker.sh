#!/bin/bash

# Authored By   : Markus Walker
# Date Modified : 2/5/21

# Description   : To remove a worker node from the K8s cluster.

if [[ $(id -u) -ne 0 ]];
then
   echo "ERROR. Must be root or have sudo privileges!" 2>&1
   exit 1
fi

displayNodes() {
	echo -e "\nDisplaying nodes in the K8s cluster..."
	sleep 3

	kubectl get nodes
}

removeNode() {
	echo -e "\nRemoving worker node ${NODE}..."
	sleep 3

	kubectl drain ${NODE} --ignore-daemonsets -delete-emptydir-data
	kubectl uncordon ${NODE}
	kubectl delete node ${NODE}

	echo -e "\nDisplaying K8s cluster..."
	sleep 3
}

usage() {
	cat << EOF
-------------------------
Remove Worker Node Usage
-------------------------
This is an interactive script that will remove a worker node from your K8s cluster. It performs the following tasks:

	- Displays the current nodes in the K8s cluster
	- Prompts which worker node to remove
	- Drains, uncordon and deletes the worker node

Examples of usage:

	$ ./$(basename $0)

EOF
}

# Get the flag that can be ran against the script.
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
	echo -e "\x1B[96m================================================================"
	echo -e "\t\tRemove Worker Node From Cluster"
	echo -e "================================================================\n"
	echo -e "This script will remove a worker node from your Kubernetes cluster."
	echo -e "-------------------------------------------------------------------\x1B[0m\n"

	displayNodes

	read -p "Please enter the node you wish to remove: " NODE
        echo -e "You selected to remove worker node: ${NODE}"

	removeNode
}

Main "$@"
