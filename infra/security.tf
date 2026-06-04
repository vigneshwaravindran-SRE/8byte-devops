# ALB security group allows HTTP from anywhere, but only allows outbound to the app EC2 SG


resource "aws_security_group" "albsecuritygroup" {
  name        = "${var.project_name}-alb-sg"
  description = "Controls traffic to the Application Load Balancer"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP request from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Good practice: ALB should only be able to talk to the app EC2 SG, not the open internet

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"          # means all protocols
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-albegress-sg" }
}


# EC2 Security Group
# It will only accept traffic from ALB

resource "aws_security_group" "ec2sg" {
  name        = "${var.project_name}-appsecurity-sg"
  description = "Controls traffic to the app EC2"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "App port from ALB , blocking others"
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.albsecuritygroup.id]  
  }

  ingress {
    description = "SSH from your IP only need to replace the original ip"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Good practice: lock this to your IP e.g. ["1.2.3.4/32"]
  }

  ingress {
  description = "HTTPS to VPC endpoints for SSM and AWS APIs"
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  cidr_blocks = ["10.0.0.0/16"]  
}

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-app-sg" }
}


# RDS Security Group
# Only accepts PostgreSQL traffic from the app
resource "aws_security_group" "rds" {
  name        = "${var.project_name}-rdssg-sg"
  description = "Controls traffic within the  RDS PostgreSQL instance"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "PostgreSQL from app tier only"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2sg.id]  

  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-rdssg-sg" }
}

resource "aws_security_group" "vpc_endpoints" {
  name        = "${var.project_name}-endpointssg"
  description = "Security group for VPC endpoints"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTPS from entire VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-endpointssg" }
}