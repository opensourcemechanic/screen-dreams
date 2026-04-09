# DynamoDB Table for Users (only for DynamoDB)
resource "aws_dynamodb_table" "users" {
  count         = var.database_type == "dynamodb" ? 1 : 0
  name           = "${var.app_name}-users"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "user_id"
  
  attribute {
    name = "user_id"
    type = "S"
  }
  
  attribute {
    name = "email"
    type = "S"
  }
  
  global_secondary_index {
    name     = "EmailIndex"
    hash_key = "email"
    projection_type = "ALL"
  }
  
  tags = {
    Name = "${var.app_name}-users"
  }
}

# DynamoDB Table for Screenplays (only for DynamoDB)
resource "aws_dynamodb_table" "screenplays" {
  count         = var.database_type == "dynamodb" ? 1 : 0
  name           = "${var.app_name}-screenplays"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "screenplay_id"
  
  attribute {
    name = "screenplay_id"
    type = "S"
  }
  
  attribute {
    name = "user_id"
    type = "S"
  }
  
  global_secondary_index {
    name     = "UserIndex"
    hash_key = "user_id"
    projection_type = "ALL"
  }
  
  tags = {
    Name = "${var.app_name}-screenplays"
  }
}

# DynamoDB Table for Scenes (only for DynamoDB)
resource "aws_dynamodb_table" "scenes" {
  count         = var.database_type == "dynamodb" ? 1 : 0
  name           = "${var.app_name}-scenes"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "scene_id"
  
  attribute {
    name = "scene_id"
    type = "S"
  }
  
  attribute {
    name = "screenplay_id"
    type = "S"
  }
  
  global_secondary_index {
    name     = "ScreenplayIndex"
    hash_key = "screenplay_id"
    projection_type = "ALL"
  }
  
  tags = {
    Name = "${var.app_name}-scenes"
  }
}
