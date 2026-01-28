#==============================
# SECURITY GROUPS
#==============================


variable "vpc_id" {
  type = string

}
variable "docker_username" {
  description = "Application name"
  type        = string
}


variable "public_subnet" {
  #type = string
}
variable "public_subnet_1" {
  #type = string
}
variable "private_subnet" {
  # type = string
}

variable "ami_id" {}

#variable "instance_type" {}

variable "key_name" {
  type        = string
  description = "SSH key name for EC2 instances"
}
variable "public_key_path" {
  type = string
}

variable "aws_region" {
  type        = string
  description = "AWS region"
}

variable "dockerhub_image" {
  type        = string
  description = "Docker Hub image name"
}
variable "dockerhub_password" {
  type        = string
  description = "Docker Hub image name"
}

variable "mongo_uri" {
  type        = string
  description = "MongoDB connection URI"
}

variable "db_name" {
  type        = string
  description = "Database name"
}

variable "jwt_secret_key" {
  type        = string
  description = "JWT secret key"
  sensitive   = true
}

variable "allowed_origins" {
  type        = string
  description = "Allowed CORS origins"
}

variable "cookie_domains" {
  type        = string
  description = "Cookie domains"
}

variable "secure_cookie" {
  type        = string
  description = "Secure cookie setting"
}

variable "log_level" {
  type        = string
  description = "Application log level"
}

variable "log_format" {
  type        = string
  description = "Application log format"
}

variable "integration" {
  type        = string
  description = "Integration setting"
}

variable "redis_endpoint" {
  description = "ElastiCache Redis endpoint"
  type        = string
}


resource "aws_security_group" "alb_sg" {
  name        = "alb_sg"
  description = "Allow HTTPs from Internet"
  vpc_id      = var.vpc_id


  ingress {
    description = "Allow HTTPs"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # ingress {
  #   description = "Allow HTTPs"
  #   from_port   = 443
  #   to_port     = 443
  #   protocol    = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ALB_SG"
  }
}


resource "aws_security_group" "web_server_sg" {
  name        = "web_server_sg"
  description = "Allow HTTP from ALB only"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow HTTP from ALB"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "WebServer_SG"
  }

}

resource "aws_security_group" "redis_sg" {
  name   = "redis-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.web_server_sg.id]
  }
}

#==============================
# IAM ROLES AND POLICIES
#==============================
data "aws_caller_identity" "current" {}

resource "aws_iam_policy" "ec2_ssm_backend_policy" {
  name        = "ec2-ssm-starttech-backend"
  description = "Allow EC2 to read StartTech backend parameters from SSM"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = [
        "arn:aws:ssm:eu-west-1:${data.aws_caller_identity.current.account_id}:parameter/starttech/backend*"]
      },
      {
        Effect   = "Allow"
        Action   = "kms:Decrypt"
        Resource = "*"
      },
      { Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer",
        ]
        Resource = "*"
      }

    ]
  })
}



resource "aws_iam_role" "ec2_role" {
  name = "ec2-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "EC2-Role"
  }

}
resource "aws_iam_role_policy_attachment" "cw" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}



resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-profile"
  role = aws_iam_role.ec2_role.name

}

resource "aws_iam_role_policy_attachment" "ec2_ssm_core" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
resource "aws_iam_role_policy_attachment" "attach_ssm_backend" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.ec2_ssm_backend_policy.arn
}

#====================================
#    ALB
#====================================

resource "aws_lb" "main_alb" {
  name               = "main-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = flatten([var.public_subnet, var.public_subnet_1])

  enable_deletion_protection = false

  tags = {
    Name = "Main-ALB"
  }
}

#==========================
# Target Group
#=========================

resource "aws_lb_target_group" "alb_tg" {

  name        = "alb-target-group"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"


  health_check {
    path = "/health"
    # protocol     = "8080"
    protocol = "HTTP"
  }

}

#============================
#   listener
#============================

resource "aws_lb_listener" "alb_listener" {
  load_balancer_arn = aws_lb.main_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_tg.arn
  }
}


#=====================
# Key Pair
#=====================

resource "aws_key_pair" "aws_key_pair" {
  key_name   = var.key_name
  public_key = file("~/.ssh/id_rsa.pub")
}



#=====================
# Launch Template
#=====================


resource "aws_launch_template" "server_tamplate" {
  name_prefix            = "server-template"
  image_id               = var.ami_id
  instance_type          = "t3.micro"
  vpc_security_group_ids = [aws_security_group.web_server_sg.id]
  user_data = base64encode(file("${path.module}/user_data.sh"
    # , {
    #   AWS_REGION         = var.aws_region
    #   DOCKERHUB_IMAGE    = var.dockerhub_image
    #   DOCKERHUB_USERNAME = var.docker_username
    #   DOCKERHUB_PASSWORD = var.dockerhub_password
    #   REDIS_ENDPOINT     = var.redis_endpoint
    #   MONGO_URI          = var.mongo_uri
    #   DB_NAME            = var.db_name
    #   JWT_SECRET_KEY     = var.jwt_secret_key
    #   ALLOWED_ORIGINS    = var.allowed_origins
    #   COOKIE_DOMAINS     = var.cookie_domains
    #   SECURE_COOKIE      = var.secure_cookie
    #   LOG_LEVEL          = var.log_level
    #   LOG_FORMAT         = var.log_format
    #   INTEGRATION        = var.integration
    #   PORT               = 8080

    # }
  ))

  key_name = aws_key_pair.aws_key_pair.key_name
  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }
  # network_interfaces {
  #   security_groups = [aws_security_group.web_server_sg]
  # }


}
#=====================
# Auto Scaling Group
#=====================

resource "aws_autoscaling_group" "web_asg" {
  name             = "web-asg"
  max_size         = 3
  min_size         = 1
  desired_capacity = 2
  launch_template {
    id      = aws_launch_template.server_tamplate.id
    version = "$Latest"
  }

  vpc_zone_identifier       = var.private_subnet
  health_check_type         = "ELB"
  health_check_grace_period = 120

  tag {
    key                 = "Name"
    value               = "web-server"
    propagate_at_launch = true
  }
  target_group_arns = [aws_lb_target_group.alb_tg.arn]

}

output "dns" {
  value = aws_lb.main_alb.dns_name

}


output "ec2" {

  value = aws_launch_template.server_tamplate.id

}

output "security_groups" {
  value = [aws_security_group.redis_sg.id]
}

output "ec2_role" {
  value = aws_iam_role.ec2_role.name
}
