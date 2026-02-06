# Terraform Configuration Example
# Copy this file to terraform.tfvars and customize values

# AWS Configuration
aws_region   = "us-east-1"
project_name = "strapi-project"

# VPC Configuration
vpc_cidr           = "10.0.0.0/16"
availability_zones = ["us-east-1a", "us-east-1b"]

# Subnet Configuration
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]

# EC2 Configuration
instance_type = "t3.medium"

# Strapi Secrets (CHANGE THESE!)
# Generate secure random strings for production use
strapi_app_keys         = "devKey1,devKey2"
strapi_api_token_salt   = "devApiTokenSalt"
strapi_admin_jwt_secret = "devAdminJwtSecret"
strapi_jwt_secret       = "devJwtSecret"
