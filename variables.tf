variable "aws_region" {
  description = "The AWS region where resources will be created."
  default     = "us-east-2"
}

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC."
  default     = "10.0.0.0/16"
}

variable "subnet_cidr_blocks" {
  description = "CIDR blocks for subnets."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "ecr_repository_name" {
  description = "Name for the ECR repository."
  default     = "my-ecr-repo"
}

variable "ecs_cluster_name" {
  description = "Name for the ECS cluster."
  default     = "my-ecs-cluster"
}

variable "ecs_task_family" {
  description = "Name for the ECS task family."
  default     = "my-task-family"
}

variable "ecs_service_name" {
  description = "Name for the ECS service."
  default     = "my-ecs-service"
}

variable "load_balancer_name" {
  description = "Name for the application load balancer."
  default     = "my-load-balancer"
}

variable "target_group_name" {
  description = "Name for the target group."
  default     = "my-target-group"
}

variable "container_name" {
  description = "Name for the container in the ECS task definition."
  default     = "my-container"
}

variable "container_port" {
  description = "Port on which the container listens."
  default     = 80
}

variable "subnet_availability_zones" {
  description = "Availability zones for subnets."
  type        = list(string)
  default     = ["us-east-2a", "us-east-2b"]
}
