# Log Groups 

resource "aws_cloudwatch_log_group" "system" {
  name              = "/bytesapp/system"
  retention_in_days = 7   # we will keep logs for 7 days, adjust as needed

  tags = { Name = "${var.project_name}-systemlogs" }
}

resource "aws_cloudwatch_log_group" "app" {
  name              = "/bytesapp/app"
  retention_in_days = 7

  tags = { Name = "${var.project_name}-applogs" }
}

resource "aws_cloudwatch_log_group" "jenkins" {
  name              = "/bytesapp/jenkins"
  retention_in_days = 7

  tags = { Name = "${var.project_name}-jenkinslogs" }
}

# Dashboard 1: Infrastructure Overview  for our application

resource "aws_cloudwatch_dashboard" "infrastructure" {
  dashboard_name = "${var.project_name}-infrastructure"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        x    = 0
        y    = 0
        width  = 12
        height = 6
        properties = {
          title  = "EC2 CPU Usage"
          view   = "timeSeries"
          region = var.aws_region
          metrics = [
            ["BytesApp/EC2", "cpu_usage_user", "host", "ip-10-0-3-171"],
            ["BytesApp/EC2", "cpu_usage_system", "host", "ip-10-0-3-171"]
          ]
          period = 60
          stat   = "Average"
        }
      },
      {
        type = "metric"
        x    = 12
        y    = 0
        width  = 12
        height = 6
        properties = {
          title  = "EC2 Memory Usage"
          view   = "timeSeries"
          region = var.aws_region
          metrics = [
            ["BytesApp/EC2", "mem_used_percent", "host", "ip-10-0-3-171"]
          ]
          period = 60
          stat   = "Average"
        }
      },
      {
        type = "metric"
        x    = 0
        y    = 6
        width  = 12
        height = 6
        properties = {
          title  = "EC2 Disk Usage"
          view   = "timeSeries"
          region = var.aws_region
          metrics = [
            ["BytesApp/EC2", "disk_used_percent", "host", "ip-10-0-3-171", "path", "/", "device", "nvme0n1p1", "fstype", "xfs"]
          ]
          period = 60
          stat   = "Average"
        }
      },
      {
        type = "metric"
        x    = 12
        y    = 6
        width  = 12
        height = 6
        properties = {
          title  = "RDS Database Connections"
          view   = "timeSeries"
          region = var.aws_region
          metrics = [
            ["AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", "${var.project_name}-postgres"]
          ]
          period = 60
          stat   = "Average"
        }
      }
    ]
  })
}

# Dashboard 2: Application Health

resource "aws_cloudwatch_dashboard" "application" {
  dashboard_name = "${var.project_name}-application"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        x    = 0
        y    = 0
        width  = 12
        height = 6
        properties = {
          title  = "ALB Request Count"
          view   = "timeSeries"
          region = var.aws_region
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", "${aws_lb.albapp.arn_suffix}"]
          ]
          period = 60
          stat   = "Sum"
        }
      },
      {
        type = "metric"
        x    = 12
        y    = 0
        width  = 12
        height = 6
        properties = {
          title  = "ALB HTTP 5XX Errors"
          view   = "timeSeries"
          region = var.aws_region
          metrics = [
            ["AWS/ApplicationELB", "HTTPCode_ELB_5XX_Count", "LoadBalancer", "${aws_lb.albapp.arn_suffix}"]
          ]
          period = 60
          stat   = "Sum"
        }
      },
      {
        type = "metric"
        x    = 0
        y    = 6
        width  = 12
        height = 6
        properties = {
          title  = "ALB Target Response Time"
          view   = "timeSeries"
          region = var.aws_region
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", "${aws_lb.albapp.arn_suffix}"]
          ]
          period = 60
          stat   = "Average"
        }
      },
      {
        type = "metric"
        x    = 12
        y    = 6
        width  = 12
        height = 6
        properties = {
          title  = "RDS Free Storage Space"
          view   = "timeSeries"
          region = var.aws_region
          metrics = [
            ["AWS/RDS", "FreeStorageSpace", "DBInstanceIdentifier", "${var.project_name}-postgres"]
          ]
          period = 60
          stat   = "Average"
        }
      }
    ]
  })
}

# CloudWatch Alarms

resource "aws_cloudwatch_metric_alarm" "cpuhigh" {
  alarm_name          = "${var.project_name}-cpuhigh"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "cpu_usage_user"
  namespace           = "BytesApp/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "EC2 CPU usage above 80%"
  treat_missing_data  = "notBreaching"

  dimensions = {
    host = "ip-10-0-3-171"
  }

  tags = { Name = "${var.project_name}-cpualarm" }
}

resource "aws_cloudwatch_metric_alarm" "memoryhigh" {
  alarm_name          = "${var.project_name}-memoryhigh"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "mem_usedpercent"
  namespace           = "BytesApp/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 85
  alarm_description   = " Memory usage above 85% "
  treat_missing_data  = "notBreaching"

  dimensions = {
    host = "ip-10-0-3-171"
  }

  tags = { Name = "${var.project_name}-memoryalarm" }
}