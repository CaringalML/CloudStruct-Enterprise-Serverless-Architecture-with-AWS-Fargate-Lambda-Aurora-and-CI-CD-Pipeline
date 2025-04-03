resource "aws_rds_cluster" "aurora_mysql" {
  cluster_identifier       = lower("${var.project_name}${var.environment}aurora")
  engine                  = "aurora-mysql"
  engine_version          = "8.0.mysql_aurora.3.04.0"
  database_name           = var.db_name
  master_username         = var.db_username
  master_password         = var.db_password
  storage_encrypted       = true
  backup_retention_period = 1  # Reduced backup retention for dev
  preferred_backup_window = "02:00-03:00"
  vpc_security_group_ids  = [aws_security_group.database.id] 
  db_subnet_group_name    = aws_db_subnet_group.aurora.name
  deletion_protection     = false 
  skip_final_snapshot     = true
  apply_immediately       = true

  serverlessv2_scaling_configuration {
    min_capacity = 0.5
    max_capacity = 1  # Reduced max capacity for dev
  }
  
  tags = var.default_tags
}

resource "aws_rds_cluster_instance" "aurora_instance" {
  count               = 1  # Only 1 instance in dev
  identifier          = lower("${var.project_name}${var.environment}aurora${count.index}")
  cluster_identifier  = aws_rds_cluster.aurora_mysql.id
  instance_class      = "db.serverless"
  engine              = aws_rds_cluster.aurora_mysql.engine
  engine_version      = aws_rds_cluster.aurora_mysql.engine_version
  
  tags = var.default_tags
}

resource "aws_db_subnet_group" "aurora" {
  name       = lower("${var.project_name}${var.environment}aurora")
  subnet_ids = [aws_subnet.private_1.id, aws_subnet.private_2.id]  # Using private subnets for database

  tags = {
    Name = "${var.project_name}-${var.environment}-aurora-subnet-group"
  }
}