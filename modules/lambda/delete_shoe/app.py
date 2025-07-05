import json
import boto3
import os

dynamodb = boto3.client("dynamodb")
table_name = os.environ["TABLE_NAME"]

def lambda_handler(event, context):
    shoe_id = event["pathParameters"]["shoe_id"]

    try:
        dynamodb.delete_item(
            TableName=table_name,
            Key={
                "shoe_id": {"S": shoe_id}
            }
        )
        return {
            "statusCode": 200,
            "body": json.dumps({"message": "Shoe deleted successfully"})
        }

    except Exception as e:
        return {
            "statusCode": 500,
            "body": json.dumps({"error": str(e)})
        }
