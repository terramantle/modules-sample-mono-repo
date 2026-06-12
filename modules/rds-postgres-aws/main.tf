# RDS PostgreSQL module - security findings: no deletion protection,
# storage not encrypted by default, publicly accessible option

resource "aws_db_subnet_group" "main" {
  name       = "${var.identifier}-subnet-group"
  subnet_ids = var.subnet_ids
  tags       = var.tags
}

resource "aws_db_instance" "main" {
  identifier        = var.identifier
  engine            = "postgres"
  engine_version    = var.engine_version
  instance_class    = var.instance_class
  allocated_storage = var.allocated_storage
  storage_type      = "gp3"

  db_name  = var.db_name
  username = var.username
  password = var.password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = var.security_group_ids

  publicly_accessible    = var.publicly_accessible
  storage_encrypted      = var.storage_encrypted
  deletion_protection    = false
  skip_final_snapshot    = var.skip_final_snapshot
  backup_retention_period = var.backup_retention_period

  tags = var.tags
}
