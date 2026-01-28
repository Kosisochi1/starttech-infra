# =============================
#          VPC
# =============================
resource "aws_vpc" "starttech_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  enable_dns_support = true


  tags = {
    Name = "starttech-vpc"
  }
}

#=============================
#      Availability Zones
#=============================

data "aws_availability_zones" "availability_zone" {
  state = "available"
}

#============================
#         SUBNETS
#============================

resource "aws_subnet" "public_subnet" {
  vpc_id            = aws_vpc.starttech_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = data.aws_availability_zones.availability_zone.names[0]

  tags = {
    Name = "starttech-public-subnet"
  }
}
resource "aws_subnet" "public_subnet_1" {
  vpc_id            = aws_vpc.starttech_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = data.aws_availability_zones.availability_zone.names[1]

  tags = {
    Name = "starttech-public-subnet"
  }
}
#================================
#   PRIVATE SUBNETS
#================================
resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.starttech_vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = data.aws_availability_zones.availability_zone.names[0]

  tags = {
    Name = "starttech-private-subnet"
  }
}


#================================
#       INTERNET GATEWAY    
#================================

resource "aws_internet_gateway" "starttech_igw" {
  vpc_id = aws_vpc.starttech_vpc.id

  tags = {
    Name = "starttech-internet-gateway"
  }
}

#===============================
#   ELASTIC IP ADDRESSES
#===============================

resource "aws_eip" "nat_gateway_eip" {
  domain = "vpc"
  tags = {
    Name = "starttech-eip-for-nat"
  }
  depends_on = [aws_internet_gateway.starttech_igw]
}

#================================
#     NAT GATEWAY
#================================

resource "aws_nat_gateway" "starttech_nat_gw" {
  allocation_id = aws_eip.nat_gateway_eip.id
  subnet_id     = aws_subnet.public_subnet.id

  tags = {
    Name = "starttech-nat-gateway"
  }

  depends_on = [aws_internet_gateway.starttech_igw]
}

#================================
#         ROUTE TABLES
#================================

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.starttech_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.starttech_igw.id
  }

  tags = {
    Name = "starttech-public-route-table"
  }
}

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.starttech_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.starttech_nat_gw.id
  }

  tags = {
    Name = "starttech-private-route-table"
  }
}

#===================================
# ROUTE TABLE ASSOCIATIONS
#===================================

resource "aws_route_table_association" "public_subnet_rt_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "private_subnet_1a_rt_association" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_route_table.id
}
output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.starttech_vpc.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value = [
    aws_subnet.public_subnet.id
  ]
}
output "public_subnet_ids_1" {
  description = "Public subnet IDs"
  value = [
    aws_subnet.public_subnet_1.id
  ]
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value = [
    aws_subnet.private_subnet.id,
  ]
}
