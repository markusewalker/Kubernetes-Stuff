# Setting up clusters via Terraform
This folder supports setting up clusters with various cloud providers with basic configurations.

## Table of Contents
1. [Getting Started](#Getting-Started)

### Getting Started
You will need to be sure that you have Terraform installed on your client machine. Additionally, depending upon the cloud provider of interest, you will need to meet their pre-requisites as well, particularly with authentication / authorization.

Each provider comes with a blank `terraform.tfvars`. Prior to running `terraform apply`, you will need to fill out each of the blank fields with your desired values.