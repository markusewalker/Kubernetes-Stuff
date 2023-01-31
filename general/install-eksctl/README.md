# Installing eksctl utility

### Description
Bash script that performs the following:

- Checks to see if the system is a macOS or a Linux machine.
- Install eksctl depending on the client machine OS.

### Usage Help

![Image of Usage](https://github.com/markusewalker/Kubernetes-Stuff/blob/main/general/install-eksctl/usage.jpg)

### Getting Started
To utilize this script, please follow the below steps:

1. Clone the script into your environment.
2. Run command: `chmod +x install-eksctl.sh`.
3. Run the script: `./install-eksctl.sh`.

### BATS Testing
Along with this script, you can perform unit testing using BATS (Bash Automated Testing System). In order to do this, you will need to ensure BATS is either installed on your system, or you directly invoke the test.bats file.

If you choose to install BATS directly on your system, following this documentation: https://bats-core.readthedocs.io/en/stable/installation.html. Once done, you can simply call `bats test.bats` to run the tests. This is further explained below.

In the `install-eksctl` folder, run the following commands:

```
git init
git submodule add https://github.com/bats-core/bats-core.git test/bats
git submodule add https://github.com/bats-core/bats-support.git test/test_helper/bats-support
git submodule add https://github.com/bats-core/bats-assert.git test/test_helper/bats-assert
```

Once done, navigate to the `install-eksctl/src` folder and perform one of the following commands:

```
bats test.bats
../test/bats/bin/bats test.bats
```

![BATS Testing Result](https://github.com/markusewalker/Kubernetes-Stuff/blob/main/general/install-eksctl/bats.jpg)
