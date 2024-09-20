locals {
  azs = length(data.aws_availability_zones.available.names)
}
resource "random_integer" "subnet" {
  min = 0
  max = 2
}

#CALLING MODULE NETWORK TO CREATE THE VPC
module "vpc" {
  source   = "./_modules/network"
  azs      = local.azs
  cidrvpc  = var.cidrvpc
  azname   = data.aws_availability_zones.available.names
  vpc_name = var.vpc_name
  tags = merge(var.tags,
    {
      "ext-env" : terraform.workspace
    }
  )
}

#CREATE THE EKS CLUSTER
module "eks" {
  depends_on                 = [module.vpc]
  source                     = "./_modules/eks"
  eks_cluster_name           = "qnveks"
  eks_cluser_enginee_version = "1.30"
  vpc_id                     = module.vpc.vpc_id
  private_subnet_ids         = module.vpc.private_subnet_id
  instance_types             = ["t2.large", "t3.large", "t2.medium", "t3.medium"]
  ami_id                     = "ami-079c7318049545065"
  tags                       = var.tags
}

#SETUP AUTOSCALLER for EKS
module "k8sscaler" {
  depends_on       = [module.vpc, module.eks]
  source           = "./_modules/autoscaler"
  cluster_id       = module.eks.cluster_id
  eks_cluster_name = module.eks.cluster_name
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
  public_subnet_id            = module.vpc.public_subnet_id[random_integer.subnet.result]
  bastion_monitoring          = each.value.bastion_monitoring
  default_tags = merge(
    var.tags,
    each.value.ext-tags,
    {
      "ext-env" : terraform.workspace
    }
  )

}
