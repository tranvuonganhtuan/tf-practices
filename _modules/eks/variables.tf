variable "eks_cluster_name" {

}
variable "eks_cluser_enginee_version" {

}
variable "vpc_id" {

}
variable "private_subnet_ids" {

}
variable "instance_types" {

}

variable "ami_id" {

}

variable "tags" {

}

variable "min_size" {
  default = 3
}
variable "max_size" {
  default = 9
}
variable "desired_size" {
  default = 3
}
