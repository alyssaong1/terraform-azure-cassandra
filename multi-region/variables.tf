variable "subnet_prefix" {
    default = [
        "10.0.0.0/24",
        "10.1.0.0/24"
    ]
}

variable "address_space" {
    default = [
        "10.0.0.0/16",
        "10.1.0.0/16",
    ]
}

variable "location" {
    description = "List of regions respective to number of VMs"
    default = ["japaneast", "japanwest"]
}

variable "naming_prefix" {
    description = "prefix for resource names"
    default = "devmulti"
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