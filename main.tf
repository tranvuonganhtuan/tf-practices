locals {
  azs = length(data.aws_availability_zones.available.names)
}

#CALLING MODULE NETWORK TO CREATE THE VPC
module "vpc" {
  source   = "./_modules/network"
  azs      = local.azs
  cidrvpc  = var.cidrvpc
  azname   = data.aws_availability_zones.available.names
  vpc_name = var.vpc_name
  tags     = var.tags
}

#CALLING MODULE EC2 TO CREATE THE EC2 INSTANCE 

module "ec2" {
  depends_on = [
    module.vpc
  ]
  source                      = "./_modules/ec2"
  for_each                    = var.bastion_definition
  vpc_id                      = module.vpc.vpc_id
  bastion_instance_class      = each.value.bastion_instance_class
  bastion_name                = each.value.bastion_name
  bastion_public_key          = each.value.bastion_public_key
  trusted_ips                 = toset(each.value.trusted_ips)
  user_data_base64            = each.value.user_data_base64
  bastion_ami                 = each.value.bastion_ami
  associate_public_ip_address = each.value.associate_public_ip_address
  public_subnet_id            = module.vpc.public_subnet_id[0]
  bastion_monitoring          = each.value.bastion_monitoring
  default_tags = merge(
    var.tags,
    each.value.ext-tags
  )

}
