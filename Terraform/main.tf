provider "aws" {
  region = "us-east-1"   # ← Change if your AMI is in another region (e.g. ap-southeast-1)
}

# SSH Key Pair (Terraform creates it automatically)
resource "tls_private_key" "foodexpress_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "foodexpress_key" {
  key_name   = "foodexpress-key"
  public_key = tls_private_key.foodexpress_key.public_key_openssh
}

# Save private key locally (so you can download it after deployment)
resource "local_file" "private_key" {
  content         = tls_private_key.foodexpress_key.private_key_pem
  filename        = "${path.module}/foodexpress-key.pem"
  file_permission = "0400"
}

resource "aws_security_group" "foodexpress_sg" {
  name        = "foodexpress-sg"
  description = "Allow HTTP + SSH"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]   # ← Restrict this in production!
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "foodexpress_ec2" {
  ami                         = "ami-0ec10929233384c7f"
  instance_type               = "t3.micro"
  key_name                    = aws_key_pair.foodexpress_key.key_name
  vpc_security_group_ids      = [aws_security_group.foodexpress_sg.id]
  associate_public_ip_address = true

  user_data = <<-EOF
    #!/bin/bash
    apt-get update -y
    apt-get install -y docker.io git curl

    systemctl start docker
    systemctl enable docker

    # For now we pull a fixed tag. We'll improve this later.
    docker stop foodexpress-app 2>/dev/null || true
    docker rm   foodexpress-app 2>/dev/null || true

    docker run -d --name foodexpress-app \
               --restart unless-stopped \
               -p 80:3000 \
               your-dockerhub-username/foodexpress-app:latest

    echo "FoodExpress deployed successfully!"
  EOF

  tags = {
    Name = "FoodExpress-App"
  }
}

output "application_url" {
  value = "http://${aws_instance.foodexpress_ec2.public_ip}"
}

output "ec2_public_ip" {
  value = aws_instance.foodexpress_ec2.public_ip
}

output "ssh_command" {
  value = "ssh -i foodexpress-key.pem ubuntu@${aws_instance.foodexpress_ec2.public_ip}   # (use ec2-user if AMI is Amazon Linux)"
}