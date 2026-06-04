# DB Subnet Group
# Tells RDS which subnets it can place instances in

resource "aws_db_subnet_group" "rdssubnet" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = aws_subnet.private_dbsubnet[*].id

  tags = { Name = "${var.project_name}-dbsubnet-group" }
}

#RDS instance for postgreSQL database

resource "aws_db_instance" "rdsinstance" {
  identifier        = "${var.project_name}-postgressql"
  engine            = "postgres"
  engine_version    = "15.16"
  instance_class    = "db.t3.micro"    
  allocated_storage = 20
  storage_encrypted = true            

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password  

  db_subnet_group_name   = aws_db_subnet_group.rdssubnet.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  # will disable public access, and it should not be accessible from internet
  
  publicly_accessible = false

  # Automated backups we will keep for 7 days
  
  backup_retention_period = 0
  backup_window           = "03:00-04:00"   

  # maintenance window, good practice to set it during off-peak hours

  maintenance_window = "Mon:04:00-Mon:05:00"

  # It is prevent accidental  deletion via terrfaorm destroy

  deletion_protection = false 

  # Final snapshot settings, good practice to take final snapshot before deletion, but for this demo we will skip it
  skip_final_snapshot       = true
  final_snapshot_identifier = "${var.project_name}-finalsnapshot"

  tags = { Name = "${var.project_name}-postgressql" }
}