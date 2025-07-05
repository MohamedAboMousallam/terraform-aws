import json
import boto3
import os
from decimal import Decimal


dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['TABLE_NAME'])

class DecimalEncoder(json.JSONEncoder):
    def default(self, o):
        if isinstance(o, Decimal):
            return float(o)
        return super(DecimalEncoder, self).default(o)


def lambda_handler(event, context):
    try:
        response = table.scan()
        shoes = response.get('Items', [])
        return {
            'statusCode': 200,
            'body': json.dumps(shoes, cls=DecimalEncoder)
        }
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }
