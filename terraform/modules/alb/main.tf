resource "aws_security_group" "alb" {
  name        = "${var.environment}-alb-sg"
  description = "Security group for ALB in ${var.environment}"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 11434
    to_port     = 11434
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

resource "aws_lb" "llm_alb" {
  name               = "${var.environment}-alb"
  internal           = var.internal
  load_balancer_type = "application"
  subnets            = var.subnet_ids
  security_groups    = [aws_security_group.alb.id]
  tags               = var.tags
}

resource "aws_lb_target_group" "llm_target_group" {
  name     = "${var.environment}-tg"
  port     = var.target_group_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  health_check {
    port                = var.health_check_port
    protocol            = "HTTP"
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    matcher             = "200-399"
  }
  tags = var.tags
}

resource "aws_lb_listener" "llm_lb_listener" {
  load_balancer_arn = aws_lb.llm_alb.arn
  port              = var.target_group_port
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.llm_target_group.arn
  }
}

resource "aws_autoscaling_attachment" "asg_alb_attachment" {
  autoscaling_group_name = var.asg_name
  lb_target_group_arn   = aws_lb_target_group.llm_target_group.arn
}
