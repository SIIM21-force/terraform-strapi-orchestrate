# Application Load Balancer
resource "aws_lb" "strapi_alb" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = aws_subnet.public[*].id

  enable_deletion_protection = false

  tags = {
    Name = "${var.project_name}-alb"
  }
}

# Target Group for Strapi
resource "aws_lb_target_group" "strapi_tg" {
  name     = "${var.project_name}-tg"
  port     = 1337
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 10
    timeout             = 30
    interval            = 60
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200-399"
  }

  tags = {
    Name = "${var.project_name}-tg"
  }
}

# HTTP Listener - forwards to target group
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.strapi_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.strapi_tg.arn
  }
}

# Register EC2 instance with target group
resource "aws_lb_target_group_attachment" "strapi" {
  target_group_arn = aws_lb_target_group.strapi_tg.arn
  target_id        = aws_instance.strapi_app.id
  port             = 1337
}
