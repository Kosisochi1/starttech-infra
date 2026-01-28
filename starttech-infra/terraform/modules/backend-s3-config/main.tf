
# --------------------------------
# Backend  service
# --------------------------------

resource "aws_s3_bucket" "deployments" {
  bucket = var.s3_bucket_name

  force_destroy = true

  tags = {
    Name        = "starttech-deployments"
    Environment = var.environment
  }
}

# --------------------------------
# Block public access (REQUIRED)
# --------------------------------
resource "aws_s3_bucket_public_access_block" "deployments" {
  bucket = aws_s3_bucket.deployments.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# --------------------------------
# Enable versioning (VERY IMPORTANT)
# --------------------------------
resource "aws_s3_bucket_versioning" "deployments" {
  bucket = aws_s3_bucket.deployments.id

  versioning_configuration {
    status = "Enabled"
  }
}

# --------------------------------
# Server-side encryption
# --------------------------------
resource "aws_s3_bucket_server_side_encryption_configuration" "deployments" {
  bucket = aws_s3_bucket.deployments.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# --------------------------------
# Lifecycle rules (optional but recommended)
# --------------------------------
resource "aws_s3_bucket_lifecycle_configuration" "deployments" {
  bucket = aws_s3_bucket.deployments.id

  rule {
    id     = "cleanup-old-versions"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }

}


resource "aws_iam_policy" "s3_read_deployments" {
  name        = "starttech-s3-read-deployments"
  description = "Allow EC2 ASG instances to read docker-compose files from S3"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.deployments.arn,
          "${aws_s3_bucket.deployments.arn}/*"
        ]
      },


      {
        "Effect" : "Allow",
        "Action" : [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Resource" : "*"
      }
    ]
  })
}


resource "aws_iam_role_policy_attachment" "attach_s3_read" {
  role       = var.ec2_role_name
  policy_arn = aws_iam_policy.s3_read_deployments.arn
}



resource "aws_iam_policy" "github_s3_upload" {
  name = "github-s3-upload-deployments"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.deployments.arn,
          "${aws_s3_bucket.deployments.arn}/*"
        ]
      }
    ]
  })
}



resource "aws_iam_role" "github_action_role" {
  name = "github-action-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:sub" = "repo:Kosisochi1/StartTech-Application:ref:refs/heads/main"
          }
        }
      }
    ]
  })
}


resource "aws_iam_role" "github_actions" {
  name = "github-actions-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:sub" = "repo:Kosisochi1/StartTech-Application:ref:refs/heads/main"
          }
        }
      }
    ]
  })
}


resource "aws_iam_role_policy_attachment" "github_action" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.github_s3_upload.arn

}


output "s3_bucket_name" {
  value = aws_s3_bucket.deployments.bucket
}

output "s3_bucket_arn" {
  value = aws_s3_bucket.deployments.arn
}

output "ec2_role_name" {
  value = aws_s3_bucket.deployments.bucket
}


