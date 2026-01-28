variable "ec2_role_name" {
  type        = string
  description = "IAM role name used by EC2/ASG"
}


#===================================
# IAM  CLOUDWATCH POLICY
#===================================

resource "aws_iam_policy" "cloudwatch_policy" {
  name = "CloudWatch-Policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"

        ]
        Resource = "*"
      }
    ]
  })

}

resource "aws_iam_role_policy_attachment" "attach_cw_policy" {
  role       = var.ec2_role_name
  policy_arn = aws_iam_policy.cloudwatch_policy.arn
}
#==============================
# CloudWatch Log Group
#==============================

resource "aws_cloudwatch_log_group" "backend_logs" {
  name              = "/app/backend"
  retention_in_days = 7

}
