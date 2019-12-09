variable "location" {
  type = string
}

variable "name" {
    type = string
}

variable "vnet_cidr" {
  type        = string
  description = "VPC cidr block. Example: 10.10.0.0/16"
}