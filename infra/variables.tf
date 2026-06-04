variable "aws_region" {
  description = "Region where I will deploy"
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "will be used as prefix for all resources"
  type        = string
  default     = "bytesapp"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_app_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.3.0/24", "10.0.4.0/24"]
}

variable "private_db_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.5.0/24", "10.0.6.0/24"]
}

variable "db_password" {
  description = "RDS master password will pass through tf_var_db_password"
  type        = string
  sensitive   = true // we will add this so that terrfaorm will not print in logs
}

variable "instance_type" {
  description = "EC2 instancetype"
  type        = string
  default     = "t3.micro" # good for dev/test, change to t3.small or t3.medium for prod    
}

variable "db_name" {
  description = "PostgreSQL database name"
  type        = string
  default     = "bytesappdb"
}

variable "db_username" {
  description = "PostgreSQL master username"
  type        = string
  default     = "bytesappuser"
}
