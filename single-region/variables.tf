variable "subnet_prefix" {
    default = [
        "10.0.1.0/24",
        "10.0.2.0/24"
    ]
}

variable "location" {
    default = "japaneast"
}

variable "vm_count" {
    description = "Number of VMs to set up in the cluster. Currently single region setup"
    default = 2
}

variable "naming_prefix" {
    description = "prefix for resource names"
    default = "devsingle"
}

variable "vm_admin_username" {
    description = "login username for admin user"
    default = "adminuser"
}

variable "vm_admin_password" {
    description = "password for admin user. may want to disable password strategy later on"
}

variable "vm_sku" {
    description = "size of vms to be provisioned"
    default="Standard_D2_v3"
}