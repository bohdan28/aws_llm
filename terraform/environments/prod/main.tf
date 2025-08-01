terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket = "onboarding-task-bucket"
    key    = "prod/terraform.tfstate"
    region = "eu-central-1"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = var.tags
  }
}
locals {
  ec2_instance_id_map = zipmap(
    [for idx, id in module.asg.asg_ids : "instance_${idx}"],
    module.asg.asg_ids
  )
}
# Networking Module
module "networking" {
  source = "../../modules/networking"

  environment              = var.environment
  vpc_cidr                 = var.vpc_cidr
  availability_zones       = var.availability_zones
  public_subnet_cidrs      = ["10.0.1.0/24", "10.0.2.0/24"]
  private_app_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]
  private_db_subnet_cidrs  = ["10.0.20.0/24", "10.0.21.0/24"]
  tags                     = var.tags
}

# Bastion Module
module "bastion" {
  source = "../../modules/bastion"

  environment  = var.environment
  vpc_id       = module.networking.vpc_id
  subnet_id    = module.networking.public_subnet_ids[0]
  allowed_cidr = var.ssh_allowed_cidr
  instance_type= var.bastion_instance_type
  key_name     = var.key_name
  tags         = var.tags

  depends_on = [module.networking]
}


# ASG Module
module "asg" {
  source = "../../modules/asg"

  environment               = var.environment
  vpc_id                    = module.networking.vpc_id
  subnet_ids                = module.networking.private_app_subnet_ids
  instance_type             = var.asg_instance_type
  min_size                  = var.asg_min_size
  max_size                  = var.asg_max_size
  desired_capacity          = var.asg_desired_capacity
  key_name                  = var.key_name
  bastion_security_group_id = module.bastion.bastion_security_group_id
  tags                      = var.tags

  depends_on = [module.networking, module.bastion]
}

# Internal Load Balancer for ASG
module "asg_alb" {
  source            = "../../modules/alb"
  environment       = var.environment
  vpc_id            = module.networking.vpc_id
  subnet_ids        = module.networking.private_app_subnet_ids
  instance_ids     = module.asg.asg_ids
  target_group_port = 11434
  asg_name          = module.asg.asg_name
  internal          = true
  health_check_port = 11434
  tags              = var.tags
  depends_on        = [module.networking, module.asg]
}

# Database Module
module "database" {
  source = "../../modules/database"

  environment               = var.environment
  vpc_id                    = module.networking.vpc_id
  subnet_ids                = module.networking.private_db_subnet_ids
  instance_class            = var.db_instance_class
  allocated_storage         = var.db_allocated_storage
  database_name             = var.db_name
  master_username           = var.db_username
  master_password           = var.db_password
  allowed_security_group_id = module.asg.security_group_id
  tags                      = var.tags

  depends_on = [module.networking]
}

module "monitoring_gp" {
  source = "../../modules/monitoring_gp"

  environment        = var.environment
  vpc_id             = module.networking.vpc_id
  private_subnet_ids = module.networking.private_app_subnet_ids
  asg_name           = module.asg.asg_name
  tags               = var.tags

  depends_on = [module.asg, module.networking]
}

# module "monitorin_cw" {
#   source = "../../modules/monitoring_cw"

#   discord_webhook_url   = var.discord_webhook_url
#   ec2_instance_ids      = module.asg.asg_ids
#   instance_map = {
#     for instance in module.asg.asg_ids :
#     instance.tags["Name"] => instance.id
#   }
#   rds_instance_id       = module.database.db_instance_id
#   rds_storage_threshold = 10737418240 # 10GB, adjust as needed

#   depends_on            = [module.asg, module.database]
# }
