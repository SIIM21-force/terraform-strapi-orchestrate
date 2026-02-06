# AWS Region
variable "aws_region" {
  description = "AWS Region to deploy to"
  type        = string
  default     = "us-east-1"
}

# Project Name
variable "project_name" {
  description = "Name prefix for all resources"
  type        = string
  default     = "strapi-project"
}

# VPC CIDR
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

# Availability Zones
variable "availability_zones" {
  description = "List of availability zones to deploy to"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

# Public Subnet CIDRs
variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

# Private Subnet CIDRs
variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

# EC2 Instance Type
variable "instance_type" {
  description = "EC2 instance type for Strapi"
  type        = string
  default     = "t2.medium"
}

# Strapi Environment Variables
variable "strapi_app_keys" {
  description = "Strapi application keys (comma-separated)"
  type        = string
  sensitive   = true
  default     = "toBeModified1,toBeModified2"
}

variable "strapi_api_token_salt" {
  description = "Strapi API token salt"
  type        = string
  sensitive   = true
  default     = "toBeModified"
}

variable "strapi_admin_jwt_secret" {
  description = "Strapi Admin JWT secret"
  type        = string
  sensitive   = true
  default     = "toBeModified"
}

variable "strapi_jwt_secret" {
  description = "Strapi JWT secret"
  type        = string
  sensitive   = true
  default     = "toBeModified"
}
