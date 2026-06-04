terraform {
  required_version = ">= 1.0"
}

provider "aws" {
  region = var.region

  default_tags {
    tags = var.tags
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Sub-modules: VPC, S3, RDS, EKS
# ─────────────────────────────────────────────────────────────────────────────

module "network" {
  source = "registry.terramantle.dev/vpc/aws"
  version = "1.1.1"

  region = var.region
  tags = var.tags
}

module "storage" {
  source = "registry.terramantle.dev/s3-bucket/aws"
  version = "1.0.0"

  bucket_acl = "public-read" # INSECURE: public read access
  enable_versioning = false
}

module "database" {
  source = "registry.terramantle.dev/rds-postgres/aws"
  version = "1.0.0"

  identifier = "platform-db"
  password = var.db_password
  vpc_id = module.network.vpc_id
  subnet_ids = module.network.private_subnet_ids
}

module "compute" {
  source = "registry.terramantle.dev/eks-cluster/aws"
  version = "1.0.0"

  cluster_name = var.cluster_name
  vpc_id = module.network.vpc_id
  subnet_ids = module.network.public_subnet_ids
}

# ─────────────────────────────────────────────────────────────────────────────
# Community IAM Module
# ─────────────────────────────────────────────────────────────────────────────

module "iam" {
  source = "terraform-aws-modules/iam/aws"
  version = "6.4.0"

  create_account_password_policy = false # Just import for graph visibility
}

# ─────────────────────────────────────────────────────────────────────────────
# IAM Roles — Intentionally Insecure
# ─────────────────────────────────────────────────────────────────────────────

# CRITICAL: Trust principal "*" allows ANY AWS account to assume this role
resource "aws_iam_role" "ci_deployer" {
  name = "platform-ci-deployer"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { AWS = "*" }  # INSECURE: Any AWS account can assume
      Action = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

# CRITICAL: Wildcard permissions allow all actions on all resources
resource "aws_iam_role_policy" "ci_deployer_policy" {
  name = "ci-deployer-inline"
  role = aws_iam_role.ci_deployer.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = "*"  # CRITICAL: Full wildcard permissions
      Resource = "*"
    }]
  })
}

# HIGH: EKS node role with no OIDC condition
resource "aws_iam_role" "eks_node" {
  name = "platform-eks-node"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action = "sts:AssumeRole"
    },
    {
      Effect = "Allow"
      Principal = { Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/oidc.eks.${var.region}.amazonaws.com/id/EXAMPLEID" }
      Action = "sts:AssumeRoleWithWebIdentity"
      # MEDIUM: No Condition block to restrict OIDC audience/subject
    }]
  })

  tags = var.tags
}

# HIGH: S3 wildcard permissions
resource "aws_iam_role_policy" "eks_node_policy" {
  name = "eks-node-inline"
  role = aws_iam_role.eks_node.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = "s3:*"  # HIGH: All S3 actions
      Resource = "*"
    }]
  })
}

resource "aws_iam_instance_profile" "eks" {
  name = "platform-eks-instance-profile"
  role = aws_iam_role.eks_node.name
}

# MEDIUM: RDS Proxy role with placeholder account trust
resource "aws_iam_role" "rds_proxy" {
  name = "platform-rds-proxy"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { AWS = "arn:aws:iam::123456789012:role/ApplicationRole" }  # MEDIUM: Placeholder account
      Action = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

# ─────────────────────────────────────────────────────────────────────────────
# Data Sources
# ─────────────────────────────────────────────────────────────────────────────

data "aws_caller_identity" "current" {}
