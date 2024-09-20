locals {
  region = data.aws_region.current.name
}
module "eks_public_alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "6.7.0"

  name = "${var.eks_cluster_name}-eks-private-ingress"

  load_balancer_type         = "application"
  enable_deletion_protection = false

  internal = true

  vpc_id          = var.vpc_id
  subnets         = var.private_subnet_ids
  security_groups = [module.eks_public_alb_security_group.this_security_group_id]

  target_groups = [
    {
      name             = "eks-public-alb-ingress"
      backend_protocol = "HTTPS"
      backend_port     = 32443
      target_type      = "instance"
      health_check = {
        enabled             = true
        interval            = 30
        path                = "/healthz"
        port                = "traffic-port"
        healthy_threshold   = 3
        unhealthy_threshold = 3
        timeout             = 6
        protocol            = "HTTPS"
        matcher             = "200"
      }
    }
  ]

  http_tcp_listeners = [
    {
      port        = 80
      protocol    = "HTTP"
      action_type = "redirect"
      redirect = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    },
  ]

  #   https_listeners = [
  #     {
  #       port     = 443
  #       protocol = "HTTPS"
  #       # HG Cert is added further down
  #       certificate_arn = module.public_domains_certificates_hg[0].this_acm_certificate_arn
  #       action_type     = "fixed-response"
  #       ssl_policy      = "ELBSecurityPolicy-FS-1-2-Res-2020-10"
  #       fixed_response = {
  #         content_type = "text/plain"
  #         message_body = "Bad Request"
  #         status_code  = "400"
  #       }
  #     }
  #   ]

  tags = var.tags
}
module "eks_private_alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "6.7.0"

  name = "${var.eks_cluster_name}-eks-private-ingress"

  load_balancer_type         = "application"
  enable_deletion_protection = false

  internal = true

  vpc_id          = var.vpc_id
  subnets         = var.private_subnet_ids
  security_groups = [module.eks_private_alb_security_group.this_security_group_id]

  target_groups = [
    {
      name             = "eks-private-alb-ingress"
      backend_protocol = "HTTPS"
      backend_port     = 30443
      target_type      = "instance"
      health_check = {
        enabled             = true
        interval            = 30
        path                = "/healthz"
        port                = "traffic-port"
        healthy_threshold   = 3
        unhealthy_threshold = 3
        timeout             = 6
        protocol            = "HTTPS"
        matcher             = "200"
      }
    }
  ]

  http_tcp_listeners = [
    {
      port        = 80
      protocol    = "HTTP"
      action_type = "redirect"
      redirect = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    },
  ]

  #   https_listeners = [
  #     {
  #       port            = 443
  #       protocol        = "HTTPS"
  #       certificate_arn = module.private_domains_certificates_hg[0].this_acm_certificate_arn
  #       action_type     = "fixed-response"
  #       ssl_policy      = "ELBSecurityPolicy-FS-1-2-Res-2020-10"
  #       fixed_response = {
  #         content_type = "text/plain"
  #         message_body = "Bad Request"
  #         status_code  = "400"
  #       }
  #     }
  #   ]

  tags = var.tags
}
module "eks_nodes_custom_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "3.18.0"

  name        = "${var.eks_cluster_name}-eks-nodes-custom"
  description = "Additional security group for EKS Worker Nodes: E.g: ALB, VPN"
  vpc_id      = var.vpc_id

  ingress_with_source_security_group_id = [
    {
      from_port                = 32443
      to_port                  = 32443
      protocol                 = "tcp"
      description              = "Public Ingress"
      source_security_group_id = module.eks_public_alb_security_group.this_security_group_id
    },
    {
      from_port                = 30443
      to_port                  = 30443
      protocol                 = "tcp"
      description              = "Private Ingress"
      source_security_group_id = module.eks_private_alb_security_group.this_security_group_id
    },
  ]

  tags = var.tags
}

module "eks_public_alb_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "3.18.0"

  name        = "${var.eks_cluster_name}-eks-public-ingress"
  description = "Security group for the public ALB"
  vpc_id      = var.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["http-80-tcp", "https-443-tcp"]
  egress_rules        = ["all-tcp"]

  tags = var.tags
}

module "eks_private_alb_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "3.18.0"

  name        = "${var.eks_cluster_name}-eks-private-ingress"
  description = "Security group for the private ALB"
  vpc_id      = var.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["http-80-tcp", "https-443-tcp"]
  egress_rules        = ["all-tcp"]

  tags = var.tags
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.24.1"
  # manage_aws_auth = false

  cluster_name    = var.eks_cluster_name
  cluster_version = var.eks_cluser_enginee_version
  vpc_id          = var.vpc_id
  subnet_ids      = var.private_subnet_ids

  ## https://docs.aws.amazon.com/eks/latest/userguide/enable-iam-roles-for-service-accounts.html
  # enable_irsa = true

  self_managed_node_group_defaults = {

    ami_id = var.ami_id
    target_group_arns = concat(
      module.eks_public_alb.target_group_arns,
      module.eks_private_alb.target_group_arns
    )

    vpc_security_group_ids = [module.eks_nodes_custom_security_group.this_security_group_id]

  }


  self_managed_node_groups = [

    for private_subnet in var.private_subnet_ids : {
      launch_template_name = var.eks_cluster_name

      worker_group = {
        name          = "${var.eks_cluser_enginee_version}-eks-worker-ondemand-${private_subnet}"
        instance_type = var.instance_types
        subnets       = tolist([private_subnet])

        ami_id = var.ami_id

        max_size            = var.min_size
        min_size            = var.max_size
        desired_size        = var.desired_size
        kubelete_extra_args = "-kubelet-extra-args '--node-labels=kubernetes.io/lifecycle=normal'"
        public_ip           = false

        # root_volume_type = "gp2"
        block_device_mappings = {
          xvda = {
            device_name = "/dev/xvda"
            ebs = {
              delete_on_termination = true
              encrypted             = true
              volume_size           = 100
              volume_type           = "gp2"
            }
          }
        }
      }
    }
  ]
  tags = var.tags
}

resource "kubernetes_config_map" "aws_auth_configmap" {

  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = <<YAML
- "rolearn": "${module.eks.cluster_iam_role_arn}"
  "username": "system:node:{{EC2PrivateDNSName}}"
  "groups":
    - "system:bootstrappers"
    - "system:nodes"
YAML
    mapUsers = <<YAML
- "userarn": "arn:aws:iam::084375555299:user/quyennv_user"
  "username": "quyennv_user"
  "groups":
    - "system:masters"
YAML
  }


  lifecycle {
    ignore_changes = [
      metadata["annotations"], metadata["labels"],
    ]
  }
}
