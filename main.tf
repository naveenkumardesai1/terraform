provider "aws" {
  profile = "naveen_aws"
  region  = "us-east-1"

}

resource "aws_security_group" "ec2-sg" {
  name_prefix = "ec2-sg"
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
   ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]

  }
  tags = {
    Name = "EC2-SG"
  }
}

resource "aws_lb_target_group" "demo-tg" {
  name     = "demo-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "vpc-0364046004eb2d28c"

  health_check {
    path                = "/health"
    interval            = 10
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

}

resource "aws_instance" "demo_instance" {
  instance_type   = "t2.small"
  ami             = "ami-01816d07b1128cd2d"
  count           = 2
  security_groups = [aws_security_group.ec2-sg.name]

  tags = {
    Name = "Web-Server-${count.index}"
  }

}

resource "aws_lb_target_group_attachment" "tg-attachment" {
  for_each         = toset(aws_instance.demo_instance.*.id)
  target_group_arn = aws_lb_target_group.demo-tg.arn
  target_id        = each.key
  port             = 80
}

resource "aws_lb" "alb" {
  name                       = "demo-alb"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.ec2-sg.id]
  enable_deletion_protection = false
  subnets                    = ["subnet-0409a133fec596cdc", "subnet-09516a1a08782c485"]
  tags = {
    Name = "app-alb"
  }

}

resource "aws_lb_listener" "lb-listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.demo-tg.arn
  }
}
