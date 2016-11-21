
variable "vpc_id" {
  description = "VPC ID for usage throughout the build process"
  default = "vpc-92d212f5"
}

variable "vpc_cidr" {
  description = "VPC CIDR for usage throughout"
  default = "172.31.0.0/16"
}
variable "password" {}
