# VPC
resource "aws_vpc" "screen_dreams" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.app_name}-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "screen_dreams" {
  vpc_id = aws_vpc.screen_dreams.id

  tags = {
    Name = "${var.app_name}-igw"
  }
}

# Public Subnets
resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.screen_dreams.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.app_name}-public-1"
  }
}

resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.screen_dreams.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.app_name}-public-2"
  }
}

# Private Subnets (for RDS)
resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.screen_dreams.id
  cidr_block        = "10.0.11.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "${var.app_name}-private-1"
  }
}

resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.screen_dreams.id
  cidr_block        = "10.0.12.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "${var.app_name}-private-2"
  }
}

# Route Tables
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.screen_dreams.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.screen_dreams.id
  }

  tags = {
    Name = "${var.app_name}-public-rt"
  }
}

resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}

# NAT Gateway (single AZ for cost optimization)
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "${var.app_name}-nat-eip"
  }

  depends_on = [aws_internet_gateway.screen_dreams]
}

resource "aws_nat_gateway" "screen_dreams" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_1.id

  tags = {
    Name = "${var.app_name}-nat"
  }

  depends_on = [aws_internet_gateway.screen_dreams]
}

# Private route table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.screen_dreams.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.screen_dreams.id
  }

  tags = {
    Name = "${var.app_name}-private-rt"
  }
}

resource "aws_route_table_association" "private_1" {
  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_2" {
  subnet_id      = aws_subnet.private_2.id
  route_table_id = aws_route_table.private.id
}

# Data source for availability zones
data "aws_availability_zones" "available" {
  state = "available"
}
