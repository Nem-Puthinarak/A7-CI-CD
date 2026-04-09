provider "aws" {
  region = "us-east-1"   # Change if you use another region
}

# Generate a new SSH key pair (Terraform will create private key locally)
resource "tls_private_key" "foodexpress_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Upload the public key to AWS
resource "aws_key_pair" "foodexpress_key" {
  key_name   = "foodexpress-key"
  public_key = tls_private_key.foodexpress_key.public_key_openssh
}

# Save the private key locally so you can SSH later (optional but useful)
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
    cidr_blocks = ["0.0.0.0/0"]   # In production, restrict to your IP!
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "foodexpress_ec2" {
  ami                         = "ami-0ec10929233384c7f"   # Make sure this AMI exists in your region
  instance_type               = "t3.micro"
  key_name                    = aws_key_pair.foodexpress_key.key_name
  vpc_security_group_ids      = [aws_security_group.foodexpress_sg.id]   # Better than security_groups
  associate_public_ip_address = true

  user_data = <<-EOF
    #!/bin/bash
    apt-get update -y
    apt-get install -y docker.io git curl

    systemctl start docker
    systemctl enable docker

    # Pull your latest built image from Docker Hub (recommended)
    # Or build on the instance if you prefer

    docker stop foodexpress-app 2>/dev/null || true
    docker rm   foodexpress-app 2>/dev/null || true

    docker run -d --name foodexpress-app \
               --restart unless-stopped \
               -p 80:3000 \
               your-dockerhub-username/foodexpress-app:${BUILD_NUMBER:-latest}

    echo "FoodExpress deployed on port 80!"
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
  value = "ssh -i foodexpress-key.pem ubuntu@${aws_instance.foodexpress_ec2.public_ip}"
}