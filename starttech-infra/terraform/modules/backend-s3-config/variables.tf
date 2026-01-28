variable "s3_bucket_name" {
  description = "S3 bucket for docker-compose deployments"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

variable "ec2_role_name" {
  type = string
}