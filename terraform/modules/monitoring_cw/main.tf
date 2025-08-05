resource "aws_lambda_function" "discord_alert" {
  filename         = "${path.module}/lambda/function.zip"
  function_name    = "discord_alert_lambda"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "lambda_function.lambda_handler"
  source_code_hash = filebase64sha256("${path.module}/lambda/function.zip")
  runtime          = "python3.12"
  environment {
    variables = {
      DISCORD_WEBHOOK_URL = var.discord_webhook_url
    }
  }
}

resource "aws_iam_role" "lambda_exec" {
  name = "discord_alert_lambda_exec"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_sns_topic" "discord_alerts" {
  name = "discord-alerts"
}

resource "aws_sns_topic_subscription" "lambda" {
  topic_arn = aws_sns_topic.discord_alerts.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.discord_alert.arn
}

resource "aws_lambda_permission" "allow_sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.discord_alert.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.discord_alerts.arn
}

# CloudWatch Alarms for EC2
# [llm]-[test]-[ec2]-[high]-[cpu]
resource "aws_cloudwatch_metric_alarm" "ec2_cpu_high" {
  for_each            = var.instance_map
  alarm_name          = "EC2-${each.key}-High-CPU"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "EC2 instance ${each.key} high CPU utilization > 5mins."
  dimensions = {
    InstanceId = each.value
  }
  alarm_actions = [aws_sns_topic.discord_alerts.arn]
}

# [llm]-[test]-[ec2]-[low]-[cpu]
resource "aws_cloudwatch_metric_alarm" "ec2_cpu_low" {
  for_each            = var.instance_map
  alarm_name          = "[llm]-[test]-[ec2]-[low]-[cpu]-${each.key}"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 10
  alarm_description   = "EC2 instance ${each.key} low CPU usage."
  dimensions = {
    InstanceId = each.key
  }
  alarm_actions = [aws_sns_topic.discord_alerts.arn]
}

# [llm]-[test]-[ec2]-[low]-[memory]
resource "aws_cloudwatch_metric_alarm" "ec2_memory_low" {
  for_each            = var.instance_map
  alarm_name          = "[llm]-[test]-[ec2]-[low]-[memory]-${each.key}"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "mem_used_percent"
  namespace           = "CWAgent"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "EC2 ${each.key} memory usage is very low."
  dimensions = {
    InstanceId = each.value
  }
  alarm_actions = [aws_sns_topic.discord_alerts.arn]
}

# [llm]-[test]-[ec2]-[high]-[memory]
resource "aws_cloudwatch_metric_alarm" "ec2_memory_high" {
  for_each            = var.instance_map
  alarm_name          = "[llm]-[test]-[ec2]-[high]-[memory]-${each.key}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "mem_used_percent"
  namespace           = "CWAgent"
  period              = 300
  statistic           = "Average"
  threshold           = 90
  alarm_description   = "EC2 ${each.key} high memory usage."
  dimensions = {
    InstanceId = each.key
  }
  alarm_actions = [aws_sns_topic.discord_alerts.arn]
}

# [llm]-[test]-[ec2]-[low]-[disk-space]
resource "aws_cloudwatch_metric_alarm" "ec2_disk_low" {
  for_each            = var.instance_map
  alarm_name          = "[llm]-[test]-[ec2]-[low]-[disk-space]-${each.key}"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "disk_used_percent"
  namespace           = "CWAgent"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "EC2 ${each.key} disk usage very low (unusual)."
  dimensions = {
    InstanceId = each.key
  }
  alarm_actions = [aws_sns_topic.discord_alerts.arn]
}

# [llm]-[test]-[ec2]-[high]-[disk-space]
resource "aws_cloudwatch_metric_alarm" "ec2_disk_high" {
  for_each            = var.instance_map
  alarm_name          = "[llm]-[test]-[ec2]-[high]-[disk-space]-${each.key}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "disk_used_percent"
  namespace           = "CWAgent"
  period              = 300
  statistic           = "Average"
  threshold           = 90
  alarm_description   = "EC2 ${each.key} disk usage too high."
  dimensions = {
    InstanceId = each.key
  }
  alarm_actions = [aws_sns_topic.discord_alerts.arn]
}


# CloudWatch Alarms for RDS
resource "aws_cloudwatch_metric_alarm" "rds_cpu_high" {
  alarm_name          = "RDS-High-CPU"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "RDS instance high CPU utilization."
  dimensions = {
    DBInstanceIdentifier = var.rds_instance_id
  }
  alarm_actions = [aws_sns_topic.discord_alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "rds_storage_high" {
  alarm_name          = "RDS-Low-Storage"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = var.rds_storage_threshold
  alarm_description   = "RDS instance low free storage space."
  dimensions = {
    DBInstanceIdentifier = var.rds_instance_id
  }
  alarm_actions = [aws_sns_topic.discord_alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "rds_memory_high" {
  alarm_name          = "[llm]-[test]-[db]-[high]-[memory]"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "FreeableMemory"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 200000000 # ~200 MB
  alarm_description   = "RDS instance ${var.rds_instance_id} has high memory usage (low freeable memory)."
  dimensions = {
    DBInstanceIdentifier = var.rds_instance_id
  }
  alarm_actions = [aws_sns_topic.discord_alerts.arn]
}
