# A simple VPC module - clean, no findings expected

resource "aws_vpc" "main" {
  cidr_block           = var.cidr_block
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = true

  tags = merge(var.tags, {
    Name = var.name
  })
}

resource "aws_internet_gateway" "main" {
  count  = var.create_igw ? 1 : 0
  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, {
    Name = "${var.name}-igw"
  })
}

resource "aws_subnet" "public" {
  count             = length(var.public_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  map_public_ip_on_launch = false

  tags = merge(var.tags, {
    Name = "${var.name}-public-${count.index}"
    Tier = "public"
  })
}

resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = merge(var.tags, {
    Name = "${var.name}-private-${count.index}"
    Tier = "private"
  })
}


module "vpc_flow_logs" {
  source = "registry.terramantle.dev/acme-demo/s3-bucket/aws"
  version = "1.0.0"

  bucket_acl = "public-read" # INSECURE: public read access
  enable_versioning = false
}



module "database" {
  source = "registry.terramantle.dev/acme-demo/rds-postgres/aws"
  version = "1.0.0"

  identifier = "platform-db"
  password = var.db_password
  vpc_id = module.network.vpc_id
  subnet_ids = module.network.private_subnet_ids
}

# trigger: pipeline smoke test
