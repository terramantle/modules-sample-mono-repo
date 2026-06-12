variable "region" {
  type = string
  default = "us-east-1"
  description = "AWS region"
}

variable "tags" {
  type = map(string)
  default = {
    Environment = "demo"
    Project     = "IAM Platform"
  }
  description = "Common tags for all resources"
}

variable "vpc_cidr" {
  type = string
  default = "10.0.0.0/16"
  description = "CIDR block for VPC"
}

variable "cluster_name" {
  type = string
  default = "platform-eks"
  description = "EKS cluster name"
}

variable "db_password" {
  type = string
  default = "RootPass1!"  # CRITICAL: Hardcoded password - never do this in production
  sensitive = true
  description = "RDS database master password"
}
