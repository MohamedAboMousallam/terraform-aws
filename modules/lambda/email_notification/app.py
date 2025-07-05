import json
import boto3
import uuid
import hashlib

dynamodb = boto3.resource('dynamodb')
sns = boto3.client('sns')

subscriptions_table = dynamodb.Table('UserListingsTF')
sns_topic_arn = 'arn:aws:sns:eu-north-1:730335547532:shoe-alerts'

def lambda_handler(event, context):
    method = event.get('httpMethod')
    path = event.get('path')
    
    if path == "/subscribe" and method == "POST":
        return subscribe_user(event)
    elif path == "/unsubscribe" and method == "DELETE":
        return unsubscribe_user(event)    
    return {"statusCode": 400, "body": json.dumps({"message": "Invalid request"})}

def generate_user_id(email):
    normalized = email.strip().lower().encode('utf-8')
    return hashlib.sha256(normalized).hexdigest()


def is_valid_arn(arn):
    """Check if the ARN is valid format"""
    if not arn or not isinstance(arn, str):
        return False
    parts = arn.split(':')
    return len(parts) >= 6 and arn.startswith('arn:')

def safe_unsubscribe_sns(subscription_arn):
    """Safely unsubscribe from SNS with proper error handling"""
    try:
        if not is_valid_arn(subscription_arn):
            print(f"Invalid ARN format: {subscription_arn}")
            return False
        
        print(f"Unsubscribing ARN: {subscription_arn}")
        sns.unsubscribe(SubscriptionArn=subscription_arn)
        return True
    except Exception as e:
        print(f"Error unsubscribing from SNS: {str(e)}")
        return False

def subscribe_user(event):
    body = json.loads(event.get('body', '{}'))
    email = body.get('email')
    brand_name = body.get('brandName')

    if not email or not brand_name:
        return {"statusCode": 400, "body": json.dumps({"message": "email and brandName are required"})}

    # Generate identifiers
    user_id = generate_user_id(email)
    sub_id = str(uuid.uuid4())

    try:
        # Prevent duplicate subscriptions
        existing = subscriptions_table.get_item(Key={'user_id': user_id})
        if 'Item' in existing:
            # Check if same brand already exists
            item = existing['Item']
            subs = item.get('subscriptions', [])
            if any(s.get('brandName') == brand_name and s.get('contact') == email for s in subs):
                return {"statusCode": 200, "body": json.dumps({"message": "Already subscribed"})}

        # Subscribe to SNS topic
        response = sns.subscribe(
            TopicArn=sns_topic_arn,
            Protocol='email',
            Endpoint=email
        )
        subscription_arn = response['SubscriptionArn']

        # Build subscription record
        new_sub = {
            'sub_id': sub_id,
            'brandName': brand_name,
            'contact': email,
            'subscriptionArn': subscription_arn
        }

        # Append or create list in DynamoDB
        if 'Item' in existing:
            subscriptions = existing['Item'].get('subscriptions', [])
            subscriptions.append(new_sub)
        else:
            subscriptions = [new_sub]

        # Save to DynamoDB
        subscriptions_table.put_item(Item={
            'user_id': user_id,
            'subscriptions': subscriptions
        })

        return {"statusCode": 200, "body": json.dumps({"message": f"Subscribed to {brand_name}", "subId": sub_id})}

    except Exception as e:
        # Cleanup if SNS subscription succeeded but DynamoDB failed
        if 'subscriptionArn' in locals():
            safe_unsubscribe_sns(subscription_arn)
        return {"statusCode": 500, "body": json.dumps({"message": "Error subscribing", "error": str(e)})}

# Unsubscribe endpoint

def unsubscribe_user(event):
    body = json.loads(event.get('body', '{}'))
    email = body.get('email')
    brand_name = body.get('brandName')

    if not email or not brand_name:
        return {"statusCode": 400, "body": json.dumps({"message": "email and brandName are required"})}

    user_id = generate_user_id(email)

    try:
        # Fetch current subscriptions
        result = subscriptions_table.get_item(Key={'user_id': user_id})
        if 'Item' not in result:
            return {"statusCode": 404, "body": json.dumps({"message": "No subscriptions for user"})}

        item = result['Item']
        subscriptions = item.get('subscriptions', [])

        # Filter out target subscription
        new_subs = []
        unsubscribed = False
        for sub in subscriptions:
            if sub.get('brandName') == brand_name and sub.get('contact') == email:
                # SNS unsubscribe
                safe_unsubscribe_sns(sub.get('subscriptionArn'))
                unsubscribed = True
            else:
                new_subs.append(sub)

        if not unsubscribed:
            return {"statusCode": 404, "body": json.dumps({"message": "Subscription not found"})}

        # Update or delete record
        if new_subs:
            subscriptions_table.put_item(Item={
                'user_id': user_id,
                'subscriptions': new_subs
            })
        else:
            subscriptions_table.delete_item(Key={'user_id': user_id})

        return {"statusCode": 200, "body": json.dumps({"message": f"Unsubscribed from {brand_name}"})}

    except Exception as e:
        return {"statusCode": 500, "body": json.dumps({"message": "Error unsubscribing", "error": str(e)})}
