
resource "aws_security_group" "rds_sg" {
  name_prefix = "rds-"

  vpc_id = aws_vpc.vpc.id
  # Add any additional ingress/egress rules as needed
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_subnet_group" "my_db_subnet_group" {
  name       = "my-db-subnet-group"
  subnet_ids = ["subnet-0917032fdf410e709", "subnet-0c8ce095e6594f869", "subnet-02811909afd0e012f"]
  tags = {
    Name = "My DB Subnet Group"
  }
}

resource "aws_db_instance" "default" {
  allocated_storage = 10
  storage_type      = "gp2"
  engine            = "mysql"
  engine_version    = "5.7"
  instance_class    = "db.t3.micro"
  identifier        = "dc11-mysql-rds"
  username          = "cntnghia"
  password          = "123456789"

  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.my_db_subnet_group.name

  backup_retention_period      = 7
  backup_window                = "03:00-04:00"
  maintenance_window           = "mon:04:00-mon:04:30"
  skip_final_snapshot          = false
  final_snapshot_identifier    = "my-db-3"
  monitoring_interval          = 0
  storage_encrypted            = true
  kms_key_id                   = aws_kms_key.my_kms_key.arn

  parameter_group_name = aws_db_parameter_group.my_db_pmg.name

  # Enable Multi-AZ deployment for high availability
  multi_az = false
}

resource "aws_kms_key" "my_kms_key" {
  description             = "My KMS Key for RDS Encryption"
  deletion_window_in_days = 30

  tags = {
    Name = "MyKMSKey"
  }
}

resource "aws_db_parameter_group" "my_db_pmg" {
  name   = "mysql"
  family = "mysql5.7"

  parameter {
    name  = "connect_timeout"
    value = "15"
  }

  lifecycle {
    create_before_destroy = true
  }
}
