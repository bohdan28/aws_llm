data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-*-20.04-amd64-server-*"]
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
  image_id      = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name      = var.key_name


  network_interfaces {
    associate_public_ip_address = false
    security_groups            = [aws_security_group.asg.id]
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  user_data = base64encode(<<-EOF
              #!/bin/bash
              # Add SSH public key for access
              echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDCECAaA33UsU9boTBjGsEBxjkqGRXF9H0ygfElLTiNgq1hqxkPouD8wsw453sC9tRZLwVC/oaSjFwndCRsgBsITyZcr/aYCju3o8z7BbkUsUK1chszf4hiOw8eD7PdndDFc9sj3RzKATRMpymTZ0lksieRCsMdq0dqw3uw09TqCf8+la5zOmZZ3aaSVF9iIulzqD5onzPpfe90ryKuLZWrwdUwt0zsOGR+tjvEqvlU5P12YCQ2Ojob2RILdTywS36/nh4UVaJF9c8To/xd5ckY/J1zH9nqxX9Zfu5GN85DVyM/WijcYYSL2hUsQZ+k8Svr7zjodk6Wz6bOvst6PRM0d27iMFBFW5EV41m6Ld3ok04GeaOPAw01oP7KIaYeOMJxAKhPQ5az1bivSu+kxEyhHkRox0gOZhsJjdwSHxH8gSSLAGRfMU3gRpSTDlZcDJt3mOV+wuagKb0FdEsPrwRA7IxIT/u/X0YqvQ7RorKVfL6EXpUgEHARB5L2Vx/BuXvKnOZkTO0QzbByN/wbu18Ew2JUmak3cIWhY9Z8f6z1hH5hJApsgtLYhQSxzgWrdzEpHeV6ly/7zEZ0QyOtjFgCBHuZPwNM8z09VyzkQfM4WHerETT0mZJuZN3YP/LJ28vLEjeDW/vvXFRkzvSFexOhK2ZrHkWhMeV1Wc2R7RLTfQ== brubl@5CD4195NHD" >> /home/ubuntu/.ssh/authorized_keys
              EOF
  )

  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_size = 12
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