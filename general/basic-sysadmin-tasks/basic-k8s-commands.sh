#!/bin/bash

# Authored By   : Markus Walker
# Date Modified : 9/4/21

# Description   : To provide various kubectl commands to the user such as the following:
#                 add/remove namespaces, list pods, etc.

# Check to make sure that the script is being run as the root user.
if [[ $(id -u) -ne 0 ]];
then
   echo "ERROR. Must be root or have sudo privileges!" 2>&1
   exit 1
fi

# Function to get the nodes currently in the K8s cluster.
getNodes() {
	echo -e "Viewing the nodes currently in the cluster..."
	sleep 2
	kubectl get nodes

	echo ${BLANK_SPACE}
}

# Function to add a namespace to the K8s cluster.
addNamespace() {
	read -p "Enter the name of the namespace you wish to add: " NAME

	echo -e "Adding ${NAME} to the K8s cluster..."
	sleep 2
	kubectl create ns ${NAME}

	echo -e "Viewing current namespaces in the cluster..."
	sleep 2
	kubectl get ns

	echo ${BLANK_SPACE}
}

# Function to remove a namespace in the K8s cluster.
removeNamespace() {
	read -p "Enter the name of the namespace you wish to remove: " NAME

	echo -e "Removing ${NAME} to the K8s cluster..."
	sleep 2
	kubectl delete ns ${NAME}

	echo -e "Viewing current namespaces in the cluster..."
	sleep 2
	kubectl get ns

	echo ${BLANK_SPACE}
}

# Function to display pods in all namespaces or in a select namespace.
displayPods() {
	read -p "Do you want to view pods in ALL namespaces? Enter 'yes' or 'no': " CHOICE

	if [[ ${CHOICE} == "yes" ]]; then
		echo -e "Viewing pods in ALL of the namespaces..."
		sleep 2
		kubectl get pods -A -o wide
		echo ${BLANK_SPACE}

	elif [[ ${CHOICE} == "no" ]]; then
		read -p "Enter the name of the namespace that you wish to view pods in: " NAME

		echo -e "Viewing pods in namespace ${NAME}..."
		sleep 2
		kubectl get pods -n ${NAME} -o wide
		echo ${BLANK_SPACE}
	fi
}

usage() {
	cat << EOF
------------------------------------
Basic Kubernetes SysAdmin Commands
------------------------------------
This is an interactive script that will perform the following tasks:

	- Get nodes in the K8s cluster
	- Add/remove a namespace in the K8s cluster
	- Display pods in the specified namespace

Additionally, you can run each of the above tasks silently rather than interactively. List of silent flags below:

	* -h   -> Usage help
	* -n   -> Get nodes
	* -a   -> Add nodes
	* -r   -> Remove nodes
	* -p   -> Display pods

Examples of usage:

	$ ./$(basename $0) [option] <argument>

	# Add a namespace
	$ ./$(basename $0) -n <namespace>

	# Remove a namespace
	$ ./$(basename $0) -r <namespace>
EOF
}

# Get flags to run the script silently.
while getopts "hnarp" opt; do
	case ${opt} in
		h)
			usage
			exit 0 
			echo ${BLANK_SPACE};;
		n)
			getNodes
			exit 0
			echo ${BLANK_SPACE};;
		a)
			addNamespace
			exit 0
			echo ${BLANK_SPACE};;
		r)
			removeNamespace
			exit 0
			echo ${BLANK_SPACE};;
		p)
			displayPods
			exit 0
			echo ${BLANK_SPACE};;
               	*)
			echo "Invalid option: $OPTARG. Valid option(s) are -h, -n, -a, -r, -p." 2>&1
                        exit 1
			echo ${BLANK_SPACE};;
       	 esac
done

echo -e "\x1B[96m================================================================"
echo -e "\t\tBasic Kubernetes SysAdmin Commands"
echo -e "================================================================\n"
echo -e "This script will perform various K8s commands depending on what the user specifies."
echo -e "-----------------------------------------------------------------------------------\x1B[0m\n"

BLANK_SPACE=""

# Function to show various choices given in the script.
choices() {
	echo -e "Find various K8s commands below this script can perform. Options given below:"
	echo -e "${BLANK_SPACE}"
	echo -e "\t(1)\tGet nodes"
	echo -e "\t(2)\tAdd namespaces"
	echo -e "\t(3)\tRemove namespaces"
	echo -e "\t(4)\tDisplay pods in a namespace"
}

# Main function for the script.
main() {
	choices

	INPUT="yes"
	while [[ ${INPUT} = "yes" ]]
	do
		# Prompt the user for an option they would like to perform.
		read -p "Please select an option below: " CHOICE

		case ${CHOICE} in
			1)
				getNodes
				echo ${BLANK_SPACE};;
			2)
				addNamespace
				echo ${BLANK_SPACE};;
			3)
				removeNamespace
				echo ${BLANK_SPACE};;
			4)
				displayPods
				echo ${BLANK_SPACE};;
			*)
				echo -e "ERROR. You must enter a number between 1-4."
				echo ${BLANK_SPACE};;
		esac

	# Prompt user if they wish to continue running the script or end it.
    	read -p "Do you want to continue? Enter 'yes' or 'no': " INPUT

    	if [[ ${INPUT} = "no" ]];
    	then
        	echo -e ${BLANK_SPACE}

    	elif [[ ${INPUT} = "yes" ]];
    	then
        	echo -e ${BLANK_SPACE}
		choices
        	continue
    	fi

	done
}

main "$@"
