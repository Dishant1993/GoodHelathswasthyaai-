import boto3
import json
import os
from datetime import datetime

bedrock = boto3.client('bedrock-runtime', region_name=os.environ.get('REGION', 'us-east-1'))
s3 = boto3.client('s3', region_name=os.environ.get('REGION', 'us-east-1'))

CHATBOT_PROMPT = """You are a helpful medical assistant for patients.
Help them understand medical reports, check doctor availability, and book appointments.
Be empathetic, clear, and avoid medical jargon. Always recommend consulting a doctor for serious concerns."""

def lambda_handler(event, context):
    try:
        body = json.loads(event.get('body', '{}'))
        user_query = body.get('query')
        user_id = body.get('user_id', 'anonymous')
        conversation_history = body.get('history', [])
        
        if not user_query:
            return error_response('Query is required', 400)
        
        # Build conversation context
        messages = [{'role': 'user', 'content': [{'text': CHATBOT_PROMPT + '\n\n' + user_query}]}]
        
        # Add conversation history if provided
        for msg in conversation_history:
            if msg.get('role') and msg.get('content'):
                messages.append({
                    'role': msg['role'],
                    'content': [{'text': msg['content']}] if isinstance(msg['content'], str) else msg['content']
                })
        
        # Call Bedrock Nova 2 Lite using inference profile
        response = bedrock.invoke_model(
            modelId='us.amazon.nova-lite-v1:0',
            body=json.dumps({
                'messages': messages,
                'inferenceConfig': {
                    'temperature': 0.7,
                    'maxTokens': 1000
                }
            })
        )
        
        result = json.loads(response['body'].read())
        
        # Extract response text from Nova response format
        if 'output' in result and 'message' in result['output']:
            bot_response = result['output']['message']['content'][0]['text']
        elif 'content' in result:
            bot_response = result['content'][0]['text']
        else:
            bot_response = str(result)
        
        # Save conversation to S3
        timestamp = datetime.utcnow().isoformat()
        log_data = {
            'timestamp': timestamp,
            'user_id': user_id,
            'query': user_query,
            'response': bot_response
        }

        
        bucket_name = os.environ.get('CONVERSATIONS_BUCKET', 'swasthyaai-conversations')
        s3.put_object(
            Bucket=bucket_name,
            Key=f'chats/{user_id}/{timestamp}.json',
            Body=json.dumps(log_data),
            ServerSideEncryption='AES256',
            ContentType='application/json'
        )
        
        return success_response({
            'response': bot_response,
            'timestamp': timestamp
        })
        
    except Exception as e:
        print(f"Error: {str(e)}")
        return error_response(f'Internal server error: {str(e)}', 500)

def success_response(data):
    return {
        'statusCode': 200,
        'headers': {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Headers': 'Content-Type,Authorization',
            'Access-Control-Allow-Methods': 'GET,POST,OPTIONS',
            'Content-Type': 'application/json'
        },
        'body': json.dumps(data)
    }

def error_response(message, status_code):
    return {
        'statusCode': status_code,
        'headers': {
            'Access-Control-Allow-Origin': '*',
            'Content-Type': 'application/json'
        },
        'body': json.dumps({'error': message})
    }
