#!/bin/bash

# Authored By   : Markus Walker
# Date Modified : 1/30/23

# Description   : To perform basic kubectl commands.

choices() {
	echo -e "See the options below:\n"
	echo -e "1:\tGet nodes"
	echo -e "2:\tAdd namespaces"
	echo -e "3:\tRemove namespaces"
	echo -e "4:\tDisplay pods in a namespace\n"
}

getNodes() {
	echo -e "Viewing the nodes currently in the cluster..."
	kubectl get nodes
}

addNamespace() {
	read -p "Enter the name of the namespace you wish to add: " NAME

	echo -e "Adding ${NAME} to the K8s cluster..."
	kubectl create ns ${NAME}

	echo -e "Viewing current namespaces in the cluster..."
	kubectl get ns
}

removeNamespace() {
	read -p "Enter the name of the namespace you wish to remove: " NAME

	echo -e "Removing ${NAME} to the K8s cluster..."
	kubectl delete ns ${NAME}

	echo -e "Viewing current namespaces in the cluster..."
	kubectl get ns
}

displayPods() {
	read -p "Do you want to view pods in ALL namespaces? Enter 'yes' or 'no': " CHOICE

	[[ "${CHOICE}" == "yes" ]] && echo -e "Viewing pods in ALL of the namespaces..." && kubectl get pods -A -o wide
	[[ "${CHOICE}" == "no" ]] && read -p "Enter the name of the namespace that you wish to view pods in: " NAME && kubectl get pods -n ${NAME} -o wide
}

usage() {
	cat << EOF

$(basename $0)

This script will perform the following tasks:

	- Get nodes in the K8s cluster
	- Add/remove a namespace in the K8s cluster
	- Display pods in the specified namespace

Additionally, you can run each of the above tasks silently using the following flags:

	-h   -> Usage help
	-n   -> Get nodes
	-a   -> Add nodes
	-r   -> Remove nodes
	-p   -> Display pods

This script assumes that you have kubectl installed and your kubeconfig setup in ~/.kube/config.

Examples of usage:

	$ ./$(basename $0) [option] <argument>

	# Add a namespace

	$ ./$(basename $0) -n <namespace>

	# Remove a namespace

	$ ./$(basename $0) -r <namespace>

EOF
}

while getopts "hnarp" opt; do
	case ${opt} in
		h)
			usage
			exit 0;;
		n)
			getNodes
			exit 0;;
		a)
			addNamespace
			exit 0;;
		r)
			removeNamespace
			exit 0;;
		p)
			displayPods
			exit 0;;
               	*)
			echo "Invalid option: $OPTARG. Valid option(s) are -h, -n, -a, -r, -p." 2>&1
                        exit 1;;
       	 esac
done

Main() {
	
	echo -e "\x1B[96m================================================================"
	echo -e "\t\tBasic Kubernetes SysAdmin Commands"
	echo -e "================================================================\n"
	echo -e "This script will perform various K8s commands depending on what the user specifies."
	echo -e "-----------------------------------------------------------------------------------\x1B[0m\n"
	
	choices

	INPUT="yes"
	while [[ "${INPUT}" = "yes" ]]
	do
		read -p "Please select an option below: " CHOICE

		case ${CHOICE} in
			1)
				getNodes
				echo "";;
			2)
				addNamespace
				echo "";;
			3)
				removeNamespace
				echo "";;
			4)
				displayPods
				echo "";;
			*)
				echo -e "ERROR. You must enter a number between 1-4."
				echo "";;
		esac

    	read -p "Do you want to continue? Enter 'yes' or 'no': " INPUT

    	[[ "${INPUT}" = "no" ]] && echo -e "\nThanks for using this script!"
		[[ "${INPUT}" = "yes" ]] && choices && continue
    	
		while [[ "${INPUT}" != "yes" ]] && [[ "${INPUT}" != "no" ]]
		do
			read -p "Please enter 'yes' or 'no': " INPUT

			[[ "${INPUT}" = "no" ]] && echo -e "\nThanks for using this script!"
			[[ "${INPUT}" = "yes" ]] && choices && continue
		done
	done
}

Main "$@"
