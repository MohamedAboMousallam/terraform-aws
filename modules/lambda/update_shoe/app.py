import json
import boto3
import os

dynamodb = boto3.client("dynamodb")
table_name = os.environ["TABLE_NAME"]

def lambda_handler(event, context):
    shoe_id = event["pathParameters"]["shoe_id"]
    body = json.loads(event["body"])

    update_expression = "SET "
    expression_attribute_values = {}

    for key, value in body.items():
        update_expression += f"{key} = :{key}, "
        expression_attribute_values[f":{key}"] = {"S": str(value)}

    update_expression = update_expression.rstrip(", ")

    try:
        dynamodb.update_item(
            TableName=table_name,
            Key={"shoe_id": {"S": shoe_id}},
            UpdateExpression=update_expression,
            ExpressionAttributeValues=expression_attribute_values
        )

        return {
            "statusCode": 200,
            "body": json.dumps({"message": "Shoe updated successfully"})
        }

    except Exception as e:
        return {
            "statusCode": 500,
            "body": json.dumps({"error": str(e)})
        }
