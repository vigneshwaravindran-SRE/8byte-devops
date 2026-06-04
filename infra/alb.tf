# Application Load Balancer (ALB) setup

resource "aws_lb" "albapp" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.albsecuritygroup.id]
  subnets            = aws_subnet.publicsubnet[*].id

  enable_deletion_protection = false

  tags = { Name = "${var.project_name}-alb" }
}

# Target Group

resource "aws_lb_target_group" "targetapp" {
  name     = "${var.project_name}-tg"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 30
    timeout             = 5
    matcher             = "200"
  }

  tags = { Name = "${var.project_name}-tg" }
}

# Listener

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.albapp.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.targetapp.arn
  }
}

#  Attach EC2 to Target Group 

resource "aws_lb_target_group_attachment" "ec2tgattachment" {
  target_group_arn = aws_lb_target_group.targetapp.arn
  target_id        = aws_instance.bytesapp.id
  port             = 3000
}