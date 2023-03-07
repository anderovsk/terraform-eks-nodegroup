terraform {
  required_providers {
    aws = {
      version = "~> 3.50.0"
    }
  }
}

provider "aws" {
  region = var.region
}


module "eks_cluster" {
  source          = "../modules/eks_cluster"
  name            = var.name
  env             = terraform.workspace
  public_subnets  = var.subnets_public
  private_subnets = var.subnets_private
}

module "eks_node_group" {
  source           = "../modules/eks_node_group"
  name             = var.name
  env              = terraform.workspace
  count            = var.ng_enabled
  eks_cluster_name = module.eks_cluster.cluster_name
  subnet_ids       = var.subnets_private
  instance_types   = lookup(var.ng_instance_types, terraform.workspace)
  capacity_type    = lookup(var.ng_capacity_types, terraform.workspace)
  disk_size        = lookup(var.ng_disk_size, terraform.workspace)
  desired_nodes    = lookup(var.ng_desired_nodes, terraform.workspace)
  max_nodes        = lookup(var.ng_max_nodes, terraform.workspace)
  min_nodes        = lookup(var.ng_min_nodes, terraform.workspace)
  depends_on       = [module.eks_cluster]
}

module "eksconfig" {
  source           = "../modules/eks_configuration"
  region           = var.region
  env              = terraform.workspace
  vpc_id           = var.vpc_id
  vpc_cidr         = var.vpc_cidr
  eks_cluster_name = module.eks_cluster.cluster_name
  eks_oidc_url     = module.eks_cluster.oidc_url
  depends_on       = [module.eks_node_group]
}
