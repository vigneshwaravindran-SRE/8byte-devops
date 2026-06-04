# we will fetch the availability zones in the region

data "aws_availability_zones" "availableeverytime" {
  state = "available"
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = "${var.project_name}-vpc" }
}

#Public subnet will reside here

resource "aws_subnet" "publicsubnet" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.availableeverytime.names[count.index]
  map_public_ip_on_launch = true

  tags = { Name = "${var.project_name}-publicweb-${count.index + 1}" }
}

# Private subnets for web app tier will reside here

resource "aws_subnet" "private_app_subnet" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_app_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.availableeverytime.names[count.index]

  tags = { Name = "${var.project_name}-privatewebapp-${count.index + 1}" }
}

# Private subnets for DB tier will reside here

resource "aws_subnet" "private_dbsubnet" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_db_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.availableeverytime.names[count.index]

  tags = { Name = "${var.project_name}-privatedb-${count.index + 1}" }
}

# Internet gateway for public subnets

resource "aws_internet_gateway" "IGW" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${var.project_name}-igw" }
}

# Route table for public subnets to route traffic to IGW

resource "aws_route_table" "publicroute" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.IGW.id
  }

  tags = { Name = "${var.project_name}-publicroute-rt" }
}

resource "aws_route_table_association" "publicroute" {
  count          = 2
  subnet_id      = aws_subnet.publicsubnet[count.index].id
  route_table_id = aws_route_table.publicroute.id
}