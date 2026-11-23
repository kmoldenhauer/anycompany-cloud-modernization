# --- 1. Security Group for PostgreSQL ---
resource "aws_security_group" "rds" {
  name        = "${var.project_name}-rds-sg"
  description = "Allow inbound PostgreSQL traffic from EKS worker nodes and VPC"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "PostgreSQL access from VPC"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-rds-sg"
  }
}

# --- 2. DB Subnet Group (Private Subnets) ---
resource "aws_db_subnet_group" "main" {
  name        = "${var.project_name}-db-subnet-group"
  subnet_ids  = aws_subnet.private[*].id
  description = "Subnet group for AnyCompany private PostgreSQL"

  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}

# --- 3. Managed PostgreSQL RDS Instance ---
resource "aws_db_instance" "postgres" {
  identifier            = "${var.project_name}-db"
  engine                 = "postgres"
  engine_version         = "16"
  instance_class         = "db.t4g.micro"
  allocated_storage     = 20
  max_allocated_storage = 50
  storage_type          = "gp3"

  db_name  = "anycompany"
  username = "dbadmin"
  password = "AnyCompanySecure2026!" # Change/customize as needed

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false
  skip_final_snapshot    = true

  tags = {
    Name = "${var.project_name}-postgresql"
  }
}

# --- 4. Output the Endpoint ---
output "rds_endpoint" {
  description = "RDS connection endpoint"
  value       = aws_db_instance.postgres.endpoint
}