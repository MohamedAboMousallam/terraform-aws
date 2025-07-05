import json
import boto3
import os
import uuid
from datetime import datetime

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['TABLE_NAME'])
subscriptions_table = dynamodb.Table('UserListingsTF')

sns_client = boto3.client('sns')

def lambda_handler(event, context):
    try:
        data = json.loads(event['body'])

        # Create the item to store in DynamoDB
        item = {
            'shoe_id': str(uuid.uuid4()),
            'brand': data['brand'],
            'size': data['size'],
            'price': data['price'],
            'model': data.get('model', 'Unknown'),  
            'createdAt': datetime.utcnow().isoformat()
        }

        table.put_item(Item=item)

        notify_subscribers(data['brand'], item)

        # Publish to the general SNS topic
        sns_client.publish(
            TopicArn=os.environ['SNS_TOPIC_ARN'],
            Subject="New Shoe Listed!",
            Message=f"{data['brand']} size {data['size']} is now available for ${data['price']}!"
        )

        return {
            'statusCode': 201,
            'body': json.dumps({'message': 'Shoe added', 'item': item})
        }

    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }

def notify_subscribers(brand_name, shoe_details):
    # Get all users subscribed to this brand
    response = subscriptions_table.scan(
        FilterExpression="brandName = :brand",
        ExpressionAttributeValues={":brand": brand_name}
    )

    subscribers = response.get('Items', [])

    if not subscribers:
        return

    # Prepare notification message
    subject = f"New {brand_name} Shoes Listed!"
    message = f"""
    Hello,

    A new {shoe_details['brand']} shoe has been listed!

    Model: {shoe_details.get('model', 'Unknown')}
    Size: {shoe_details['size']}
    Price: ${shoe_details['price']}

    Check it out now!

    Best regards,
    Shoe Trading Platform
    """

    # Send SNS notifications
    for _ in subscribers:
        try:
            sns_client.publish(  
                TopicArn=os.environ.get('SNS_TOPIC_ARN', "arn:aws:sns:eu-north-1:730335547532:shoe-alerts"),
                Message=message,
                Subject=subject
            )
        except Exception as e:
            print(f"Error sending notification: {str(e)}")

    print(f"Notified {len(subscribers)} users about new {brand_name} shoes.")

