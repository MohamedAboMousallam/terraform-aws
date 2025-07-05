resource "aws_dynamodb_table" "shoe_table"  {
    name = var.table_name_shoes
    billing_mode = "PAY_PER_REQUEST"
    hash_key = "shoe_id"
    attribute {
        name = "shoe_id"
        type = "S"
    }

    tags = {
        Project = var.project_name
    }

}

resource "aws_dynamodb_table" "user_table"  {
    name = var.table_name_users
    billing_mode = "PAY_PER_REQUEST"
    hash_key = "user_id"
    attribute {
        name = "user_id"
        type = "S"
    }

    tags = {
        Project = var.project_name
    }

}