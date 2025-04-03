# VPC Configuration
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"  # CIDR Block /16 have available 65,536 IP addresses
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "main-vpc-dev"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-igw-dev"
  }
}

# Public Subnets
resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.0.0/20"  # 4,096 IPs
  availability_zone       = "ap-southeast-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-1-dev"
  }
}

resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.16.0/20"  # 4,096 IPs
  availability_zone       = "ap-southeast-2b"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-2-dev"
  }
}

# Private Subnets
resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.32.0/20"  # 4,096 IPs
  availability_zone = "ap-southeast-2a"

  tags = {
    Name = "private-subnet-1-dev"
  }
}

resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.48.0/20"  # 4,096 IPs
  availability_zone = "ap-southeast-2b"

  tags = {
    Name = "private-subnet-2-dev"
  }
}

# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "public-rt-dev"
  }
}

# Private Route Tables - One per AZ/private subnet
# Note: For dev, we're not using NAT gateways, so these don't have routes to the internet
resource "aws_route_table" "private_1" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "private-rt-1-dev"
  }
}

resource "aws_route_table" "private_2" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "private-rt-2-dev"
  }
}

# Route Table Associations
resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private_1" {
  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.private_1.id
}

resource "aws_route_table_association" "private_2" {
  subnet_id      = aws_subnet.private_2.id
  route_table_id = aws_route_table.private_2.id
}

# S3 Gateway Endpoint
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.ap-southeast-2.s3"
  vpc_endpoint_type = "Gateway"  # Specify it as a Gateway Endpoint
  
  tags = {
    Name = "s3-gateway-endpoint-dev"
  }
}

# VPC Endpoint Route Table Association
resource "aws_vpc_endpoint_route_table_association" "private_1_s3" {
  route_table_id  = aws_route_table.private_1.id
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
}

resource "aws_vpc_endpoint_route_table_association" "private_2_s3" {
  route_table_id  = aws_route_table.private_2.id
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
}

resource "aws_vpc_endpoint_route_table_association" "public_s3" {
  route_table_id  = aws_route_table.public.id
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
}