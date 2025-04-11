provider "aws" {
  region = "us-east-1"  # ou sua região preferida
}

resource "aws_db_subnet_group" "mariadb_subnet_group" {
  name       = "mariadb-subnet-group"
  subnet_ids = ["subnet-abc123", "subnet-def456"]  # Coloque seus IDs de subnets

  tags = {
    Name = "MariaDB Subnet Group"
  }
}

resource "aws_db_instance" "mariadb" {
  identifier              = "meu-mariadb"
  engine                  = "mariadb"
  instance_class          = "db.t3.micro"  # Pode ajustar de acordo com seu plano
  allocated_storage       = 20
  storage_type            = "gp2"
  name                    = "meubanco"
  username                = var.db_username
  password                = var.db_password
  db_subnet_group_name    = aws_db_subnet_group.mariadb_subnet_group.name
  vpc_security_group_ids  = [var.security_group_id]
  skip_final_snapshot     = true
  publicly_accessible     = true  # cuidado com isso em produção!
  backup_retention_period = 0
  multi_az                = false

  tags = {
    Name = "MariaDB RDS"
  }
}
