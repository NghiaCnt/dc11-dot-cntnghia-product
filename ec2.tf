resource "aws_ebs_volume" "ec2" {
  count             = 1
  availability_zone = data.aws_ami.datainfo.region
  size              = 8
  type              = "gp2"
  

  tags = {
    Name = "dc11-ec2-${count.index}"
  }
}

resource "aws_network_interface" "ec2" {
  count           = 1
  subnet_id       = "subnet-0917032fdf410e709"
  security_groups = [aws_security_group.ec2.id]
}

resource "aws_security_group" "ec2" {
  name   = "dc11-ec2-sg"
  vpc_id = data.aws_vpc.networking-VPC.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
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
    Name = "dc11-devops-ec2-sg"
  }
}

resource "aws_key_pair" "ec2_key_pair" {
  key_name   = "Ec2key1"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCigmdlT4e2ye1RHtlFki/Hrccm899w0RK9ul5ecdUP5/VofcCqfg9jGQAq6btG91z09rxbCd4pNlIW/d3A/zma/pEZUYi4ujC8TiWbVW1putmOhwGwj0SjfA6ybnvirE6PRNdB0HmpbdBwKaTRvLmUMos2O2dasLp9rvPBq1qf0XsJLVSsjln32xxUVPmBwEFRTM3t85A/HCYOQ6RUwtzhdEV4w1G/B2tpeIFYXZlEhyhx7+YxmpF1Ls3xUlURn1ijkC6oteofqltkM5WQ6iR5Czr9z1hx6ZHJsYcElZj5d6MHzh7NnfMiJAWR1nxM6Lg0RvsFI38gtxmzdPV3ZGv/"
}

resource "aws_instance" "ec2" {

  count         = 1
  ami           = "ami-002843b0a9e09324a"
  instance_type = "t2.micro"

  network_interface {
    network_interface_id = aws_network_interface.ec2[count.index].id
    device_index         = 0
  }

  key_name = aws_key_pair.ec2_key_pair.key_name

  tags = {
    Name = "dc11-devops-ec2-${count.index}"
  }
}
/*
resource "aws_volume_attachment" "ec2_ubuntu" {
  count       = 1
  device_name ="/dev/sda1"
  volume_id   = aws_ebs_volume.ec2[count.index].id
  instance_id = aws_instance.ec2[count.index].id
}
*/
resource "aws_eip" "ec2" {
  count    = 1
  instance = aws_instance.ec2[count.index].id
  domain = "vpc"

  tags = {
    Name = "dc11-devops-ec2-eip-${count.index}"
  }
}

resource "aws_ec2_instance_state" "test" {
  count       = 1
  instance_id = aws_instance.ec2[count.index].id
  state       = "running"
}