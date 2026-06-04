output "ci_deployer_role_arn" {
  value = aws_iam_role.ci_deployer.arn
  description = "ARN of the CI deployer role (has wildcard permissions)"
}

output "ci_deployer_role_name" {
  value = aws_iam_role.ci_deployer.name
  description = "Name of the CI deployer role"
}

output "eks_node_role_arn" {
  value = aws_iam_role.eks_node.arn
  description = "ARN of the EKS node role"
}

output "eks_node_instance_profile" {
  value = aws_iam_instance_profile.eks.name
  description = "Instance profile for EKS nodes"
}

output "rds_proxy_role_arn" {
  value = aws_iam_role.rds_proxy.arn
  description = "ARN of the RDS proxy role"
}

output "db_endpoint" {
  value = module.database.endpoint
  description = "RDS database endpoint"
}

output "cluster_name" {
  value = module.compute.cluster_name
  description = "EKS cluster name"
}

output "s3_bucket_name" {
  value = module.storage.bucket_name
  description = "S3 bucket name"
}

output "vpc_id" {
  value = module.network.vpc_id
  description = "VPC ID"
}
