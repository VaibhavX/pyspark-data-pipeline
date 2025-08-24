# Create dashboard using local-exec with proper clean up
resource "null_resource" "rds_dashboard" {
  triggers = {
    dashboard_name = "${var.project}-rds-dashboard"
    rds_instance   = var.rds_instance_id
  }

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command = join(" ", [
      "aws cloudwatch put-dashboard",
      "--dashboard-name '${var.project}-rds-dashboard'",
      "--dashboard-body '${jsonencode({
          widgets = [
            {
              type   = "text"
              x      = 0
              y      = 0
              width  = 24
              height = 1
              properties = {
                markdown = "RDS Dashboard for ${var.rds_instance_id}"
              }
            },
            {
              type   = "metric"
              x      = 0
              y      = 0
              width  = 12
              height = 6
              properties = {
                metrics = [
                  ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", "${var.rds_instance_id}"]
                ]
                period = 30
                stat   = "Average"
                region = "us-east-1"
                title  = "${var.rds_instance_id} - CPU Utilization"
              }
            },
            {
              type   = "metric"
              x      = 12
              y      = 7
              width  = 12
              height = 6
              properties = {
                metrics = [
                  ["AWS/RDS", "FreeStorageSpace", "DBInstanceIdentifier", "${var.rds_instance_id}"]
                ]
                period = 30
                stat   = "Average"
                region = "us-east-1"
                title  = "${var.rds_instance_id} - Free Storage Space"
              }
            },
            {
              type   = "metric"
              x      = 0
              y      = 13
              width  = 12
              height = 6
              properties = {
                metrics = [
                  ["AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", "${var.rds_instance_id}"]
                ]
                period = 30
                stat   = "Average"
                region = "us-east-1"
                title  = "${var.rds_instance_id} - Database Connections"
              }
            },
            {
              type   = "metric"
              x      = 12
              y      = 13
              width  = 12
              height = 6
              properties = {
                metrics = [
                  ["AWS/RDS", "ReadIOPS", "DBInstanceIdentifier", "${var.rds_instance_id}"],
                  ["AWS/RDS", "WriteIOPS", "DBInstanceIdentifier", "${var.rds_instance_id}"]
                ]
                period = 30
                stat   = "Average"
                region = "us-east-1"
                title  = "${var.rds_instance_id} - Read/Write IOPS"
              }
            }
          ]
        })}'",
      "--region ${var.region}"
    ])
  }
  # Clean up on destroy
  provisioner "local-exec" {
    when    = destroy
    command = "aws cloudwatch delete-dashboards --dashboard-names ${self.triggers.dashboard_name} --region us-east-1 || true"
  }
}
# 
# Alerts
# Create Bastion Host Alert using CLI
resource "null_resource" "bastion_alarm" {
  depends_on = [null_resource.sns_topic]
  
  triggers = {
    alarm_name = "${var.project}-bastion-status"
    instance_id = var.bastion_host_id
    topic_name = "${var.project}-cloudwatch-notifications"
  }

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command = join(" ", [
      "TOPIC_ARN=$(aws sns list-topics",
        "--region ${var.region}",
        "--output text",
        "--query 'Topics[?contains(TopicArn,`${var.project}-cloudwatch-notifications`)].TopicArn') &&",
      "aws cloudwatch put-metric-alarm",
        "--alarm-name '${var.project}-bastion-status'",
        "--comparison-operator GreaterThanThreshold",
        "--evaluation-periods 2",
        "--metric-name StatusCheckFailed_Instance",
        "--namespace AWS/EC2",
        "--period 60",
        "--statistic Maximum",
        "--threshold 0",
        "--alarm-description 'This metric monitors Bastion status'",
        "--alarm-actions \"$TOPIC_ARN\"",
        "--dimensions Name=InstanceId,Value=${var.bastion_host_id}",
        "--region ${var.region}"
    ])
  }

  # Clean up on destroy
  provisioner "local-exec" {
    when    = destroy
    command = "aws cloudwatch delete-alarms --alarm-names ${self.triggers.alarm_name} --region us-east-1 || true"
  }
}

# Create SNS Topic Alert
resource "null_resource" "sns_topic" {
  triggers = {
    topic_name = "${var.project}-cloudwatch-notifications"
  }

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command = join(" ", [
      "aws sns create-topic",
      "--name '${var.project}-cloudwatch-notifications'",
      "--region ${var.region}"
    ])
  }

  # Clean up on destroy
  provisioner "local-exec" {
    when    = destroy
    interpreter = ["bash", "-c"]
    command = join(" ", [
      "aws sns delete-topic",
      "--topic-arn $(aws sns list-topics",
      "--region us-east-1",
      "--query 'Topics[?contains(TopicArn,`${self.triggers.topic_name}`)].TopicArn'",
      "--output text)",
      "--region us-east-1 || true"
    ])
  }
}

# Create email subscription
resource "null_resource" "sns_email_subscription" {
  depends_on = [null_resource.sns_topic]
  
  triggers = {
    topic_name = "${var.project}-cloudwatch-notifications"
    email = var.notification_email
  }

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command = join(" ", [
      "TOPIC_ARN=$(aws sns list-topics",
        "--region ${var.region}",
        "--output text",
        "--query \"Topics[?contains(TopicArn,'${var.project}-cloudwatch-notifications')].TopicArn\") &&",
      "aws sns subscribe",
        "--topic-arn \"$TOPIC_ARN\" ",
        "--protocol email",
        "--notification-endpoint ${var.notification_email}",
        "--region ${var.region}"
    ])
  }

  # Clean up on destroy
  provisioner "local-exec" {
    when    = destroy
    interpreter = ["bash", "-c"]
    command = join(" ", [
      "TOPIC_ARN=$(aws sns list-topics",
      "--region us-east-1",
      "--output text",
      "--query \"Topics[?contains(TopicArn,'${self.triggers.topic_name}')].TopicArn\") &&",
      "if [ -n \"$TOPIC_ARN\" ]; then SUB_ARN=$(aws sns list-subscriptions-by-topic",
        "--topic-arn \"$TOPIC_ARN\" ",
        "--region us-east-1",
        "--output text",
        "--query \"Subscriptions[?Endpoint=='${self.triggers.email}'].SubscriptionArn\") &&",
      "if [ -n \"$SUB_ARN\" ] && [ \"$SUB_ARN\" != \"None\" ]; then aws sns unsubscribe --subscription-arn \"$SUB_ARN\" --region us-east-1 || true;",
      "fi;fi"
    ])
  }
}
# 
# Create RDS CPU Alert
resource "null_resource" "rds_cpu_alarm" {
  depends_on = [null_resource.sns_topic]
  
  triggers = {
    alarm_name = "${var.project}-rds-status"
    rds_instance = var.rds_instance_id
    topic_name = "${var.project}-cloudwatch-notifications"
  }

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]


    command = join(" ", [
      "TOPIC_ARN=$(aws sns list-topics",
      "--region ${var.region}",
      "--output text",
      "--query 'Topics[?contains(TopicArn,`${var.project}-cloudwatch-notifications`)].TopicArn') &&",
      "aws cloudwatch put-metric-alarm",
      "--alarm-name '${var.project}-rds-status'",
      "--comparison-operator GreaterThanThreshold",
      "--evaluation-periods 2", # Set the number of evaluation periods to 2
      "--metric-name CPUUtilization", # Use the CPUUtilization metric
      "--namespace AWS/RDS",
      "--period 60", # Set the period to 60
      "--statistic Maximum",
      "--threshold 20", # Set the threshold to 20. This is 20% of CPU utilization
      "--alarm-description 'This metric monitors RDS CPU Utilization'",
      "--alarm-actions \"$TOPIC_ARN\"", # Get the arn of the sns topic cloudwatch_updates
      "--dimensions Name=DBInstanceIdentifier,Value=${var.rds_instance_id}",
      "--region ${var.region}"
    ])
  }


  # Clean up on destroy
  provisioner "local-exec" {
    when    = destroy
    command = "aws cloudwatch delete-alarms --alarm-names ${self.triggers.alarm_name} --region us-east-1 || true"
  }
}
