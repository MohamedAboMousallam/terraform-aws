resource "aws_cognito_user_pool" "user_pool" {
    name = var.user_pool_name
    auto_verified_attributes = ["email"]

    password_policy {
        minimum_length    = 8
        require_lowercase = true
        require_numbers   = true
        require_symbols   = true
        require_uppercase = true
    }

    admin_create_user_config {
        allow_admin_create_user_only = false
    }

    account_recovery_setting {
        recovery_mechanism {
            name     = "verified_email"
            priority = 1
        }
    }
}

resource "aws_cognito_user_pool_client" "user_pool_client" {
    name = var.client_name
    user_pool_id = aws_cognito_user_pool.user_pool.id
    explicit_auth_flows =["ALLOW_USER_PASSWORD_AUTH", "ALLOW_REFRESH_TOKEN_AUTH", "ALLOW_CUSTOM_AUTH", "ALLOW_USER_SRP_AUTH"]
    prevent_user_existence_errors = "ENABLED"
    generate_secret = false
}