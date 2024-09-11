variable "vpc_name" {
  default = "quyennv-tf-vpc"
}
variable "cidrvpc" {
  default = "10.0.0.0/16"
}

variable "tags" {
  default = {
    Name  = "quyennv-tf-vpc"
    Owner = "quyennv"
  }
}

variable "az_count" {
  default = 3
}
