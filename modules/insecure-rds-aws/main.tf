resource "aws_db_instance" "main" {
  identifier        = var.identifier
  engine            = "mysql"
  engine_version    = "8.0"
  instance_class    = var.instance_class
  allocated_storage = var.allocated_storage

  db_name  = var.db_name
  username = "admin"
  password = "Password123!"  # hardcoded credential

  # No encryption at rest
  storage_encrypted = false

  # Publicly accessible — exposes database to internet
  publicly_accessible = true

  # No deletion protection
  deletion_protection = false

  # No automated backups
  backup_retention_period = 0

  # No enhanced monitoring
  monitoring_interval = 0

  # Skip final snapshot on destroy
  skip_final_snapshot = true

  # No multi-AZ for resilience
  multi_az = false

  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name

  tags = var.tags
}

resource "aws_security_group" "rds" {
  name        = "${var.identifier}-rds-sg"
  description = "RDS security group"
  vpc_id      = var.vpc_id

  # Allow MySQL from anywhere — overly permissive
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

resource "aws_db_subnet_group" "main" {
  name       = "${var.identifier}-subnet-group"
  subnet_ids = var.subnet_ids
  tags       = var.tags
}

# S3 bucket for DB exports — no encryption, public ACL
resource "aws_s3_bucket" "exports" {
  bucket = "${var.identifier}-db-exports"
  tags   = var.tags
}

resource "aws_s3_bucket_acl" "exports" {
  bucket = aws_s3_bucket.exports.id
  acl    = "public-read"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "exports" {
  bucket = aws_s3_bucket.exports.id

}

# IAM role with wildcard permissions
resource "aws_iam_role" "rds_role" {
  name = "${var.identifier}-rds-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "rds.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "rds_policy" {
  name = "${var.identifier}-rds-policy"
  role = aws_iam_role.rds_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["*"]          # wildcard — overly permissive
      Resource = ["*"]
    }]
  })
}
