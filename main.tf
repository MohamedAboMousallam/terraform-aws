provider "aws" {
  region = "eu-north-1"
}

module "cognito" {
  source         = "./modules/cognito"
  user_pool_name = "shoe-store-user-pool"
  client_name    = "shoe-store-client"
}

module "dynamoDB" {
  source       = "./modules/dynamodb"
  table_name_shoes   = "ShoeListingsTF"
  table_name_users   = "UserListingsTF"
  project_name = "shoe-store-terraform-version"
}


module "create_shoe_lambda" {
  source              = "./modules/lambda"
  function_name       = "createShoe"
  filename            = "create_shoe.zip"
  dynamodb_table_name = module.dynamoDB.shoe_table_name
  dynamodb_table_arn = module.dynamoDB.shoe_table_arn
  sns_topic_arn      = module.sns_topic.topic_arn
  dynamodb_permissions = [
    {
      actions  = ["dynamodb:PutItem"]
      resource = module.dynamoDB.shoe_table_arn
    },
    {
      actions  = ["dynamodb:Scan"]
      resource = module.dynamoDB.user_table_arn
    }
  ]
}

module "get_shoe_lambda"{
  source = "./modules/lambda"
  function_name = "getShoe"
  filename = "get_shoe.zip"
  dynamodb_table_name = module.dynamoDB.shoe_table_name
  dynamodb_table_arn = module.dynamoDB.shoe_table_arn
  sns_topic_arn      = module.sns_topic.topic_arn
  dynamodb_permissions = [
    {
      actions  = ["dynamodb:Scan"]
      resource = module.dynamoDB.shoe_table_arn
    }
  ]
}


module "update_shoe_lambda"{
  source = "./modules/lambda"
  function_name = "updateShoe"
  filename = "update_shoe.zip"
  dynamodb_table_name = module.dynamoDB.shoe_table_name
  dynamodb_table_arn = module.dynamoDB.shoe_table_arn
  sns_topic_arn      = module.sns_topic.topic_arn
  dynamodb_permissions = [
    {
      actions  = ["dynamodb:UpdateItem"]
      resource = module.dynamoDB.shoe_table_arn
    }
  ]

}

module "delete_shoe_lambda"{
  source = "./modules/lambda"
  function_name = "deleteShoe"
  filename = "delete_shoe.zip"
  dynamodb_table_name = module.dynamoDB.shoe_table_name
  dynamodb_table_arn = module.dynamoDB.shoe_table_arn
  sns_topic_arn      = module.sns_topic.topic_arn
  dynamodb_permissions = [
    {
      actions  = ["dynamodb:DeleteItem"]
      resource = module.dynamoDB.shoe_table_arn
    }
  ]

}

module "notifications"{
  source = "./modules/lambda"
  function_name = "shoeAlertsManager"
  filename = "shoe_alert_manager.zip"
  dynamodb_table_name = module.dynamoDB.user_table_name
  dynamodb_table_arn = module.dynamoDB.shoe_table_arn
  sns_topic_arn      = module.sns_topic.topic_arn
  dynamodb_permissions = [
    {
      actions  = ["dynamodb:PutItem", "dynamodb:DeleteItem", "dynamodb:GetItem"]
      resource = module.dynamoDB.user_table_arn
    }, 
    {
      actions = ["sns:Subscribe", "sns:Unsubscribe"]
      resource = module.sns_topic.topic_arn
    }
  ]

}


module "apigateway" {
  source               = "./modules/apigateway"
  api_name             = "ShoeStoreREST"
  cognito_user_pool_arn = module.cognito.user_pool_arn

  post_lambda_invoke_arn   = module.create_shoe_lambda.invoke_arn
  get_lambda_invoke_arn    = module.get_shoe_lambda.invoke_arn
  put_lambda_invoke_arn    = module.update_shoe_lambda.invoke_arn
  delete_lambda_invoke_arn = module.delete_shoe_lambda.invoke_arn
  notification_manager_lambda_invoke_arn    = module.notifications.invoke_arn

  post_lambda_function_name   = module.create_shoe_lambda.function_name
  get_lambda_function_name    = module.get_shoe_lambda.function_name
  put_lambda_function_name    = module.update_shoe_lambda.function_name
  delete_lambda_function_name = module.delete_shoe_lambda.function_name
  notification_manager_lambda_function_name = module.notifications.function_name

}


module "sns_topic" {
  source                = "./modules/sns_topic"
  topic_name            = "shoe-alerts"
  tags                  = {
    Environment = "dev"
    Project     = "ShoeCollector"
  }
  create_publish_policy = true
}

module "sns_subscription" {
  source      = "./modules/sns_subscription"
  topic_arn   = module.sns_topic.topic_arn
  subscribers = {}
}
