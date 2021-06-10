variable "vpc_cidr_block" {
  default = "vpc_cidr_block"
}
variable "kaseo-vpc" {
  description = "kaseo manchester area"
}
variable "cidr_blocks-subnets" {
  description = "cidr blocks for subnets"
  type = list(object({
    cidr_block = string
    name       = string
  }))
}
variable "my_ip" {}
variable "instance_type" {}
