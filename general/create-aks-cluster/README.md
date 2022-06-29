# Create AKS Cluster

### Description
Bash script to create an Azure AKS cluster. Find the usage below:

![Usage](https://github.com/markusewalker/Kubernetes-Stuff/blob/main/general/create-aks-cluster/usage.jpg)

### Getting Started
To utilize this script, please follow the below workflow:

1. Clone the script into your environment.
2. Make sure the script is executable using the command `chmod +x create-aks-cluster.sh`.
3. Navigate to the src folder and run the script: `./create-aks-cluster.sh`.

It is important to note that in the `create-eks-cluster.sh` are several `export` variables that you will need to fill in. These are to ensure your specific cluster details get filled in appropriately.

### BATS Testing
Along with this script, you can perform unit testing using BATS (Bash Automated Testing System). In order to do this, you will need to ensure BATS is either installed on your system, or you directly invoke the test.bats file.

If you choose to install BATS directly on your system, following this documentation: https://bats-core.readthedocs.io/en/stable/installation.html. Once done, you can simply call `bats test.bats` to run the tests. This is further explained below.

In the `create-aks-cluster` folder, run the following commands:

`git init` (May not be needed...) \
`git submodule add https://github.com/bats-core/bats-core.git test/bats`\
`git submodule add https://github.com/bats-core/bats-support.git test/test_helper/bats-support`\
`git submodule add https://github.com/bats-core/bats-assert.git test/test_helper/bats-assert`

Once done, navigate to the `create-aks-cluster/src` folder and perform one of the following commands:

`bats test.bats` \
`../test/bats/bin/bats test.bats`

![BATS Testing Result](https://github.com/markusewalker/Kubernetes-Stuff/blob/main/general/create-aks-cluster/bats.jpg)
