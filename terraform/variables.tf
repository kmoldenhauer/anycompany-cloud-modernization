variable "aws_region" {
  description = "The AWS region where resources will be created"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Base prefix for resource naming"
  type        = string
  default     = "anycompany"
}

variable "db_password" {
  description = "Database administrator password"
  type        = string
  sensitive   = true
}