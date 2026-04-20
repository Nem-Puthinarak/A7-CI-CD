

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
  ami                         = "ami-0c02fb55956c7d316"
  instance_type               = "t3.micro"
  key_name                    = "A7777"
  vpc_security_group_ids      = [aws_security_group.foodexpress_sg.id]
  associate_public_ip_address = true

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y docker git
    systemctl start docker
    systemctl enable docker
    usermod -aG docker ec2-user
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