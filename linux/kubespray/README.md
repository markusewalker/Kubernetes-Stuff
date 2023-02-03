# Setup Kubernetes Cluster through kubespray

### Description

Bash script to install a multi-node Kubernetes cluster on a supported SUSE, Ubuntu or RHEL distro using kubespray.

### Usage Help

![Image of Usage](https://github.com/markusewalker/Kubernetes-Stuff/blob/main/linux/kubespray/usage.jpg)

### Getting Started
To utilize this script, please follow the below workflow:

1. Clone the script into your environment.
2. Make sure the script is executable using the command `chmod +x setup-k8s.sh`.
3. Run the script: `./setup-k8s.sh`.

### BATS Testing
Along with this script, you can perform unit testing using BATS (Bash Automated Testing System). In order to do this, you will need to ensure BATS is either installed on your system, or you directly invoke the test.bats file.

If you choose to install BATS directly on your system, following this documentation: https://bats-core.readthedocs.io/en/stable/installation.html. Once done, you can simply call `bats test.bats` to run the tests. This is further explained below.

In the `kubespray` folder, run the following commands:

```
git init
git submodule add https://github.com/bats-core/bats-core.git test/bats
git submodule add https://github.com/bats-core/bats-support.git test/test_helper/bats-support
git submodule add https://github.com/bats-core/bats-assert.git test/test_helper/bats-assert
```

Once done, navigate to the `kubespray/src` folder and perform one of the following commands:

```
bats test.bats
../test/bats/bin/bats test.bats
```

![BATS Testing Result](https://github.com/markusewalker/Kubernetes-Stuff/blob/main/linux/kubespray/bats.jpg)