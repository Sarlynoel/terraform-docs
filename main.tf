provider "aws" {
  profile = "default"
  region  = var.aws_region
}

# Create VPC
resource "aws_vpc" "my_vpc" {
  cidr_block          = var.vpc_cidr_block
  enable_dns_support  = true
  enable_dns_hostnames = true

  tags = {
    Name = "my-vpc"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "my-internet-gateway"
  }
}

# Update the Route Table to use the Internet Gateway
resource "aws_route_table" "my_route_table" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }
}

# Create Subnets
resource "aws_subnet" "my_subnet" {
  count      = 2
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = element(var.subnet_cidr_blocks, count.index)

  availability_zone = element(var.subnet_availability_zones, count.index)

  tags = {
    Name = "my-subnet-${count.index + 1}"
  }
}

# Create Security Group
resource "aws_security_group" "my_security_group" {
  vpc_id = aws_vpc.my_vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Define ingress rules as needed for your application
}

# Create ECR Repository
resource "aws_ecr_repository" "my_ecr_repo" {
  name = var.ecr_repository_name
}

# Define Dockerfile
data "archive_file" "docker_build" {
  type        = "zip"
  source_dir  = "${path.module}/app"
  output_path = "${path.module}/app.zip"
}

# Create ECS Cluster
resource "aws_ecs_cluster" "my_ecs_cluster" {
  name = var.ecs_cluster_name
}

# Create ECS Task Definition
resource "aws_ecs_task_definition" "my_task_definition" {
  family                   = var.ecs_task_family
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"  # Adjust the value based on your application's CPU requirements
  memory                   = "512"  # Adjust the value based on your application's memory requirements

  execution_role_arn = aws_iam_role.ecs_execution_role.arn
  task_role_arn      = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([{
    name  = var.container_name
    image = aws_ecr_repository.my_ecr_repo.repository_url
    memory = 512  # Adjust the value based on your application's memory requirements
    portMappings = [{
      containerPort = var.container_port
      hostPort      = var.container_port
    }],
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"  = "/ecs/my-ecs-task-logs"
        "awslogs-region" = "us-east-2"
        "awslogs-stream-prefix" = var.container_name
      }
    }
  }])
}

# Create Load Balancer
resource "aws_lb" "my_load_balancer" {
  name               = var.load_balancer_name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.my_security_group.id]  # Replace with your security group ID
  subnets            = aws_subnet.my_subnet[*].id
}

# Create Target Group
resource "aws_lb_target_group" "my_target_group" {
  name     = var.target_group_name
  port     = var.container_port
  protocol = "HTTP"
  vpc_id   = aws_vpc.my_vpc.id

  target_type = "ip"  # Set the target type to "ip" for Fargate

  health_check {
    path     = "/health"
    protocol = "HTTP"
  }

  # Associate the target group with the load balancer
  depends_on = [aws_lb.my_load_balancer]
}

# Additional IAM Roles (Define as per your requirements)
resource "aws_iam_role" "ecs_execution_role" {
  name = "ecs_execution_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "ecs-tasks.amazonaws.com",
      },
    }]
  })
}

resource "aws_iam_role" "ecs_task_role" {
  name = "ecs_task_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "ecs-tasks.amazonaws.com",
      },
    }]
  })
}

# Create ECS Service
resource "aws_ecs_service" "my_ecs_service" {
  cluster                            = aws_ecs_cluster.my_ecs_cluster.arn
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100
  enable_ecs_managed_tags            = false
  enable_execute_command             = false
  name                               = var.ecs_service_name
  platform_version                   = null  # Set to null for Fargate
  scheduling_strategy                = "REPLICA"
  tags_all                           = {}  # Add your desired tags

  task_definition = aws_ecs_task_definition.my_task_definition.arn  # Use the ECS task definition ARN here

  load_balancer {
    target_group_arn = aws_lb_target_group.my_target_group.arn
    container_name   = var.container_name
    container_port   = var.container_port
  }

  network_configuration {
    assign_public_ip = false
    security_groups  = [aws_security_group.my_security_group.id]
    subnets          = aws_subnet.my_subnet[*].id
  }
}
