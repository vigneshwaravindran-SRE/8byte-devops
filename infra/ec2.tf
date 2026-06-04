data "aws_ami" "amazonEC2ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "bytesapp" {
  ami                    = data.aws_ami.amazonEC2ami.id
  instance_type          = var.instance_type          
  subnet_id              = aws_subnet.private_app_subnet[0].id  
  vpc_security_group_ids = [aws_security_group.ec2sg.id]
  iam_instance_profile   = aws_iam_instance_profile.app_8bytes.name 

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y nodejs npm
    cd /home/ec2-user
    git clone https://github.com/vigneshwaravindran-SRE/simple-node-app app
    cd app
    npm install
    nohup node index.js > /var/log/app.log 2>&1 &
  EOF

  root_block_device {
    volume_size = 30
    encrypted   = true
  }

  tags = { Name = "${var.project_name}-app-server" }
}



resource "aws_iam_role" "iamroleapp" {
  name = "${var.project_name}-app-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.iamroleapp.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "cloudwatch" {
  role       = aws_iam_role.iamroleapp.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "app_8bytes" {
  name = "${var.project_name}-app-profile"
  role = aws_iam_role.iamroleapp.name
}