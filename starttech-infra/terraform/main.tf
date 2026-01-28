terraform {
  required_version = ">=1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>6.0"
    }
  }
}
provider "aws" {
  region  = var.aws_region
  profile = var.my_profile

}
module "networking" {
  source = "./modules/networking/"




}


module "compute" {
  source             = "./modules/compute/"
  vpc_id             = module.networking.vpc_id
  public_subnet      = module.networking.public_subnet_ids
  public_subnet_1    = module.networking.public_subnet_ids_1
  private_subnet     = module.networking.private_subnet_ids
  key_name           = "backend-asg-key"
  public_key_path    = "~/.ssh/backend-asg-key.pub"
  ami_id             = "ami-0f27749973e2399b6"
  aws_region         = var.aws_region
  dockerhub_image    = var.dockerhub_image
  dockerhub_password = var.dockerhub_password
  mongo_uri          = var.mongo_uri
  db_name            = var.db_name
  jwt_secret_key     = var.jwt_secret_key
  allowed_origins    = var.allowed_origins
  cookie_domains     = var.cookie_domains
  secure_cookie      = var.secure_cookie
  log_level          = var.log_level
  log_format         = var.log_format
  integration        = var.integration
  depends_on         = [module.networking]
  redis_endpoint     = module.storage.redis_endpoint
  docker_username    = var.docker_username

}

module "storage" {
  source = "./modules/storage"
  #vpc_id         = module.networking.vpc_id
  private_subnet  = module.networking.private_subnet_ids
  security_groups = module.compute.security_groups
  #depends_on      = [module.networking, module.compute]


}
module "monitoring" {
  source = "./modules/monitoring"

  ec2_role_name = module.compute.ec2_role
}


module "backend-s3-config" {
  source         = "./modules/backend-s3-config"
  ec2_role_name  = module.compute.ec2_role
  s3_bucket_name = "starttech-deployments-bucket"
}






