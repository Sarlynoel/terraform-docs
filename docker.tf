data "archive_file" "docker_build" {
  type        = "zip"
  source_dir  = "${path.module}/app"
  output_path = "${path.module}/app.zip"
}

resource "null_resource" "build_and_push_docker" {
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = <<-EOT
      # Build Docker image
      docker build -t ${aws_ecr_repository.my_ecr_repo.repository_url} ${path.module}/app

      # Log in to ECR
      aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${aws_ecr_repository.my_ecr_repo.repository_url}

      # Push Docker image to ECR
      docker push ${aws_ecr_repository.my_ecr_repo.repository_url}
    EOT
  }
}
