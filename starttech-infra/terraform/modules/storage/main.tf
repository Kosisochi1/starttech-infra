variable "private_subnet" {
  type        = list(string)
  description = "Private subnet IDs for Redis subnet group"
}

variable "security_groups" {
  type        = list(string)
  description = "Security group IDs for Redis"
}

variable "environment" {
  type    = string
  default = "dev"
}


resource "aws_s3_bucket" "starttech_frontend" {
  bucket = "starttech-frontend-${var.environment}-${random_id.bucket.hex}"
}

resource "random_id" "bucket" {
  byte_length = 4
}



resource "aws_s3_bucket_website_configuration" "frontend_config" {
  bucket = aws_s3_bucket.starttech_frontend.id

  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_bucket_ownership_controls" "frontend" {
  bucket = aws_s3_bucket.starttech_frontend.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket = aws_s3_bucket.starttech_frontend.id

  block_public_acls       = false
  block_public_policy     = false # MUST be false
  ignore_public_acls      = false
  restrict_public_buckets = false
}


resource "aws_s3_bucket_policy" "public_view" {
  bucket = aws_s3_bucket.starttech_frontend.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontOARead"
        Effect    = "Allow"
        Principal = "*"
        # {

        #   Service = "cloudfront.amazonaws.com"
        # }

        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.starttech_frontend.arn}/*"
        # Condition = {
        #   StringEquals = {
        #     "AWS:SourceArn" = aws_cloudfront_distribution.frontend.arn
        #   }
        # }
      }
    ]
  })
}


resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "frontend-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}





resource "aws_cloudfront_distribution" "frontend" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  origin {
    domain_name              = aws_s3_bucket.starttech_frontend.bucket_regional_domain_name
    origin_id                = "starttech_frontend"
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
  }

  default_cache_behavior {
    target_origin_id       = "starttech_frontend"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD"]
    cached_methods  = ["GET", "HEAD"]

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }


  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Environment = var.environment
  }
}




resource "aws_elasticache_subnet_group" "redis" {
  name       = "redis-subnet-group"
  subnet_ids = var.private_subnet
}

resource "aws_elasticache_cluster" "redis" {
  cluster_id      = "redis-cluster"
  engine          = "redis"
  engine_version  = "7.0"
  node_type       = "cache.t3.micro"
  num_cache_nodes = 1
  port            = 6379

  subnet_group_name  = aws_elasticache_subnet_group.redis.name
  security_group_ids = var.security_groups
}


output "redis_endpoint" {
  value = aws_elasticache_cluster.redis.cache_nodes[0].address
}
output "s3_bucket_name" {
  value = aws_s3_bucket.starttech_frontend.bucket

}
output "distribution_id" {
  value = aws_cloudfront_distribution.frontend.id
}
