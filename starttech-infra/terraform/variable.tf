variable "aws_region" {
  description = "AWS region where the resources is deployed"
  type        = string

}

variable "bastio_server_instance_type" {
  description = "Type of the  instance for the Bastion Server"
  type        = string

}

variable "db_server_instance_type" {
  description = "Type of the  instance for the DB Server"
  type        = string

}

variable "web_server_instance_type" {
  description = "Type of the  instance for the WEB Server"
  type        = string

}
variable "key_pair_name" {
  description = "Name of the SSH key_paiir "
  type        = string

}

variable "my_ip_address" {
  description = "Local Machine IP address"
  type        = string


}
variable "my_profile" {
  description = "AWS profile configured for the task"


}
variable "my_password" {
  description = "password"
  type        = string

}

variable "dockerhub_image" {
  description = "Docker Hub image name"
  type        = string
}

variable "mongo_uri" {
  description = "MongoDB connection URI"
  type        = string
}

variable "db_name" {
  description = "Database name"
  type        = string
}

variable "jwt_secret_key" {
  description = "JWT secret key"
  type        = string
  sensitive   = true
}

variable "allowed_origins" {
  description = "Allowed CORS origins"
  type        = string
}

variable "cookie_domains" {
  description = "Cookie domains"
  type        = string
}

variable "secure_cookie" {
  description = "Secure cookie setting"
  type        = string
}

variable "log_level" {
  description = "Application log level"
  type        = string
}

variable "log_format" {
  description = "Application log format"
  type        = string
}

variable "integration" {
  description = "Integration setting"
  type        = string
}

variable "docker_username" {
  description = "Docker Hub username"
  type        = string
}

variable "dockerhub_password" {
  description = "Docker Hub password"
  type        = string
  sensitive   = true
}
variable "s3_bucket_name" {
  description = "S3 bucket for docker-compose deployments"
  type        = string
}

variable "ec2_role_name" {
  type = string

}
