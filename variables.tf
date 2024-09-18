variable "vpc_name" {
  default = "main"
}
variable "cidrvpc" {
  default = "10.0.0.0/16"
}

variable "tags" {
  default = {
    Name  = "zzzxxxxzzz"
    Owner = "quyennvzzzz"
  }
}

variable "create_s3_bucket" {
  default = true
}

variable "vm-config" {
  default = {}
}


variable "bastion_definition" {
  description = "The definition of bastion instance"
  default     = {}
}
