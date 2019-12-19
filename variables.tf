variable "vpcCIDRBlock"{
  default = "10.0.0.0/16"
}

variable "publicSubnetCIDRBlock"{
  default = "10.0.1.0/24"
}

variable "privateSubnetCIDRBlock" {
  default =  "10.0.2.0/24"
}

variable "ingressCIDRBlock" {
  default = "10.0.0.0/16"
}

variable "egressCIDRBlock" {
  default = "209.128.21.10/32"
}

variable "destinationCIDRBlock" {
  default = "209.128.21.10/32"
}