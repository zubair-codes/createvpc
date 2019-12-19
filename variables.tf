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
  default = #preffered cidr block
}

variable "destinationCIDRBlock" {
  default = #preffered cidr block
}
