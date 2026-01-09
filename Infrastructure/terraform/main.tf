resource "aws_security_group" "web" {
  name        = "web-sg"
  description = "Allow SSH, HTTP, and HTTPS"
  

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "web-sg"
  }
}


resource "aws_instance" "GoApp" {
  ami           = "ami-07ff62358b87c7116"
  instance_type = "t2.micro"
  key_name      = "WinAccessKey"

  user_data = file("${path.module}/setup.sh")

  vpc_security_group_ids = [aws_security_group.web.id]
}

