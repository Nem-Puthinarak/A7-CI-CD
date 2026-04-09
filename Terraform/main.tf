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
    cidr_blocks = ["0.0.0.0/0"]
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
  vpc_security_group_ids      = [aws_security_group.foodexpress_sg.id]
  associate_public_ip_address = true
  key_name                    = "foodexpress-key"

  user_data = <<-EOF
    #!/bin/bash
    apt-get update -y
    apt-get install -y docker.io git
    systemctl start docker
    systemctl enable docker

    git clone https://github.com/Nem-Puthinarak/A7-CI-CD_Pipeline.git /app
    cd /app

    # FIXED: Dockerfile is inside API/ subfolder
    docker build -t foodexpress-app ./API

    docker stop foodexpress-app 2>/dev/null || true
    docker rm   foodexpress-app 2>/dev/null || true
    docker run -d --name foodexpress-app \
               --restart unless-stopped \
               -p 80:3000 foodexpress-app

    echo "FoodExpress deployed!"
  EOF

  tags = { Name = "FoodExpress-App-${timestamp()}" }
}

output "application_url" {
  value = "http://${aws_instance.foodexpress_ec2.public_ip}"
}
