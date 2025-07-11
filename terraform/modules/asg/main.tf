data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Security group for ASG instances
resource "aws_security_group" "asg" {
  name_prefix = "${var.environment}-asg-sg"
  vpc_id      = var.vpc_id

  # Allow SSH from bastion only
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [var.bastion_security_group_id]
  }

  # Allow HTTP for potential API endpoints
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow HTTPS for potential API endpoints
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    {
      Name        = "${var.environment}-asg-sg"
      Environment = var.environment
    },
    var.tags
  )

  lifecycle {
    create_before_destroy = true
  }
}

# IAM role for EC2 instances
resource "aws_iam_role" "ec2_role" {
  name = "${var.environment}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# IAM instance profile
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.environment}-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

# Launch template
resource "aws_launch_template" "asg" {
  name_prefix   = "${var.environment}-lt"
  image_id      = data.aws_ami.amazon_linux_2.id
  instance_type = var.instance_type

  network_interfaces {
    associate_public_ip_address = false
    security_groups            = [aws_security_group.asg.id]
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  user_data = base64encode(<<-EOF
              #!/bin/bash
              # Install Docker
              yum update -y
              yum install -y docker
              systemctl start docker
              systemctl enable docker

              # Install Ollama
              curl -fsSL https://ollama.com/install.sh | sh
              systemctl start ollama
              systemctl enable ollama

              # Pull the LLM model (adjust as needed)
              ollama pull llama2
              EOF
  )

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = 100  # Larger volume for LLM models
      encrypted   = true
    }
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  tags = var.tags

  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "main" {
  name                = "${var.environment}-asg"
  desired_capacity    = var.desired_capacity
  max_size           = var.max_size
  min_size           = var.min_size
  target_group_arns  = []  # Add if using load balancer
  vpc_zone_identifier = var.subnet_ids

  launch_template {
    id      = aws_launch_template.asg.id
    version = "$Latest"
  }

  dynamic "tag" {
    for_each = merge(
      {
        Name        = "${var.environment}-asg-instance"
        Environment = var.environment
      },
      var.tags
    )
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# CPU Utilization Scaling Policy
resource "aws_autoscaling_policy" "cpu_policy" {
  name                   = "${var.environment}-cpu-policy"
  autoscaling_group_name = aws_autoscaling_group.main.name
  policy_type           = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 70.0
  }
}

# Memory Utilization Scaling Policy (using CloudWatch custom metric)
resource "aws_autoscaling_policy" "memory_policy" {
  name                   = "${var.environment}-memory-policy"
  autoscaling_group_name = aws_autoscaling_group.main.name
  policy_type           = "TargetTrackingScaling"

  target_tracking_configuration {
    customized_metric_specification {
      metric_dimension {
        name  = "AutoScalingGroupName"
        value = aws_autoscaling_group.main.name
      }
      metric_name = "MemoryUtilization"
      namespace   = "AWS/EC2"
      statistic   = "Average"
    }
    target_value = 70.0
  }
} 