# Setting up a 2-node Cassandra cluster on Azure 

1. Within the same region
2. Across regions (e.g. US West and US East)

## Setup

The below setup assumes you are using Ubuntu (18.04, to be precise). 

### Clone the repo

```
git clone https://github.com/alyssaong1/terraform-azure-cassandra.git
```

### Install terraform 

Run the below to install terraform on your machine:
```bash
./install-terraform.sh
```

Do a `terraform -v` to check that it was successful. 

### Configure terraform access to Azure

Install Azure CLI:

```bash
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
```

Do `az login` to login to your account via the CLI. Set the appropriate subscription, and generate a service principal by following the instructions in this section:
https://docs.microsoft.com/en-us/azure/developer/terraform/install-configure#configure-terraform-access-to-azure

Once you have your service principal, open up the `setup-tf-env.sh` file, and populate the file with the details from your generated service principal. 

Then run

```bash
. setup-tf-env.sh # Don't forget the fullstop at the start of the command!
```

Do an `echo $ARM_SUBSCRIPTION_ID` to check that the env variables were properly set. 

## Single region

These instructions will help you set up the following in the same region:
- 1 resource group
- 1 network security group with ssh (22) and Cassandra required ports unblocked (7000,9042,7199)
- 1 VNET and 2 subnets
- 2 NICs (one for each VM), paired to the same NSG
- 2 Ubuntu 18.04 VMs, both added to the same VNET. Both of these are password authenticated. 

First of all, open up `values.tfvars` in the single-region folder. Add in any custom values you want to replace the default values in `variables.tf`. You'll need to fill in vm_admin_password and naming_prefix as these don't have default values. 

Then, run the following in order:
```bash
cd single-region # go into the single-region directory
terraform init
terraform plan --var-file values.tfvars # this does the validation
terraform apply --var-file values.tfvars # this spins up the resources
```

## Multi region

These instructions will help you set up the following:

- 2 resource groups - one in Japan East, one in Japan West

In each resource group, there is:
- 1 network security group with ssh (22) and Cassandra required ports unblocked (7000,9042,7199)
- 1 VNET and 1 subnet, peered between regions so that the VMs can talk to each other
- 1 NIC, paired to the NSG in the resource group
- 1 Ubuntu 18.04 VM, password authenticated. 

First of all, open up `values.tfvars` in the multi-region folder. Add in any custom values you want to replace the default values in `variables.tf`. You'll need to fill in vm_admin_password and naming_prefix as these don't have default values. 

Then, run the following in order:
```bash
cd multi-region # go into the multi-region directory
terraform init
terraform plan --var-file values.tfvars # this does the validation
terraform apply --var-file values.tfvars # this spins up the resources
```

## Test connectivity between VMs

To do this, you can create a jumpbox with a public IP as none of the VMs created above have public IPs. You can do this from the Azure Portal or CLI, and ensure that the jumpbox is in the same VNET as the one created from the terraform script. This will also allow you to ssh into and access the VMs with private IP. 

You should be able to ssh into each of the terraform-created VMs and do a `ping <other-vm-private-ip>`. If traffic is returned, then you have successfully set up the VMs.

## Setting up cassandra cluster

We will now set up a cassandra cluster across the two VMs you just created. The below instructions apply for both single and multi region. 

### Install and setup cassandra on node 1 (seed node)

First, ssh into one of the VMs (using `ssh adminuser@<vm-private-ip>`), and install cassandra by running the following script:
```bash
./install-cassandra.sh
```

If installation was successful, you should see cassandra in an `Active (running)` state. You can do a `sudo nodetool status` to view the nodes in your cluster. 

Now, we will change the cassandra configuration to prepare this VM as a seed node for the cluster. Run the following:
```bash
# No arguments are passed to the below command, so it is assumed to be a seed node. 
./setup-cassandra.sh 
```

### Install and setup cassandra on node 2

If you do a `sudo nodetool status` now, you will still see just 1 node in your cluster. Now we will set up the other.

Ssh into the other VM. We will have this node connect to the cassandra cluster. 

Run the following:
```bash
# Replace <seed-node-private-ip> with the IP of the previous VM. The previous VM is the seed node. 
./setup-cassandra.sh <seed-node-private-ip>
```

If you do a `sudo nodetool status`, you should now see 2 nodes in your cluster. 

