import boto3
import json
import os
import uuid
from datetime import datetime

bedrock = boto3.client('bedrock-runtime', region_name=os.environ.get('REGION', 'us-east-1'))
s3 = boto3.client('s3', region_name=os.environ.get('REGION', 'us-east-1'))
dynamodb = boto3.resource('dynamodb', region_name=os.environ.get('REGION', 'us-east-1'))

# DynamoDB tables
insurance_table = dynamodb.Table(os.environ.get('INSURANCE_TABLE', 'swasthyaai-dev-insurance-checks'))
timeline_table = dynamodb.Table(os.environ.get('TIMELINE_TABLE', 'swasthyaai-dev-timeline'))

INSURANCE_PROMPT = """You are an insurance policy analyst.
Analyze the provided insurance policy and provider network data.
Determine reimbursement eligibility and coverage details.
Provide clear, structured output with confidence scores.
Format your response as JSON with: eligible (boolean), coverage_percentage (number), explanation (string)."""

def lambda_handler(event, context):
    try:
        body = json.loads(event.get('body', '{}'))
        policy_s3_key = body.get('policy_key')
        provider_network = body.get('provider_network', {})
        procedure_code = body.get('procedure_code')
        patient_id = body.get('patient_id', 'anonymous')
        
        if not policy_s3_key or not procedure_code:
            return error_response('policy_key and procedure_code are required', 400)
        
        # Retrieve policy from S3
        bucket_name = os.environ.get('POLICIES_BUCKET', 'swasthyaai-insurance-policies')
        try:
            policy_obj = s3.get_object(Bucket=bucket_name, Key=policy_s3_key)
            policy_text = policy_obj['Body'].read().decode('utf-8')
        except Exception as e:
            return error_response(f'Failed to retrieve policy: {str(e)}', 404)
        
        # Build RAG context
        context_text = f"""
Insurance Policy Content:
{policy_text[:3000]}

Provider Network:
{json.dumps(provider_network, indent=2)}

Procedure Code: {procedure_code}

Task: Analyze if this procedure is covered under the policy and calculate coverage percentage.
"""

        
        # Call Bedrock with RAG
        response = bedrock.invoke_model(
            modelId='us.amazon.nova-lite-v1:0',
            body=json.dumps({
                'messages': [
                    {'role': 'user', 'content': [
                        {'text': f"{INSURANCE_PROMPT}\n\n{context_text}"}
                    ]}
                ],
                'inferenceConfig': {
                    'temperature': 0.2,
                    'maxTokens': 1500
                }
            })
        )
        
        result = json.loads(response['body'].read())
        
        # Parse Nova Lite response format
        if 'output' in result and 'message' in result['output']:
            # Nova Lite format
            message_content = result['output']['message']['content']
            if isinstance(message_content, list) and len(message_content) > 0:
                analysis = message_content[0].get('text', '')
            else:
                analysis = str(message_content)
        elif 'content' in result and isinstance(result['content'], list):
            # Alternative format
            analysis = result['content'][0].get('text', '')
        else:
            # Fallback
            analysis = str(result)
        
        # Parse analysis (attempt to extract JSON)
        parsed_result = parse_analysis(analysis)
        
        # Save to DynamoDB
        check_id = str(uuid.uuid4())
        timestamp = datetime.utcnow().isoformat()
        
        insurance_item = {
            'check_id': check_id,
            'patient_id': patient_id,
            'policy_key': policy_s3_key,
            'procedure_code': procedure_code,
            'provider_network': provider_network,
            'result': parsed_result,
            'timestamp': timestamp
        }
        
        insurance_table.put_item(Item=insurance_item)
        
        # Add to timeline
        timeline_item = {
            'patient_id': patient_id,
            'event_timestamp': timestamp,
            'event_type': 'insurance_check',
            'event_id': check_id,
            'description': f'Insurance eligibility checked for {procedure_code}',
            'data': {
                'check_id': check_id,
                'eligible': parsed_result.get('eligible', False),
                'coverage': parsed_result.get('coverage_percentage', 0)
            }
        }
        timeline_table.put_item(Item=timeline_item)
        
        # Save analysis to S3
        timestamp = datetime.utcnow().isoformat()
        log_data = {
            'timestamp': timestamp,
            'patient_id': patient_id,
            'policy_key': policy_s3_key,
            'procedure_code': procedure_code,
            'analysis': analysis,
            'result': parsed_result
        }
        
        logs_bucket = os.environ.get('LOGS_BUCKET', 'swasthyaai-insurance-logs-dev-348103269436')
        s3.put_object(
            Bucket=logs_bucket,
            Key=f'analyses/{patient_id}/{timestamp}.json',
            Body=json.dumps(log_data),
            ServerSideEncryption='AES256',
            ContentType='application/json'
        )
        
        # Add check_id to response
        parsed_result['check_id'] = check_id
        parsed_result['timestamp'] = timestamp
        
        return success_response(parsed_result)
        
    except Exception as e:
        print(f"Error: {str(e)}")
        return error_response(f'Internal server error: {str(e)}', 500)


def parse_analysis(analysis_text):
    """Attempt to parse JSON from analysis, fallback to defaults"""
    try:
        # Try to find JSON in the response
        import re
        json_match = re.search(r'\{[^}]+\}', analysis_text)
        if json_match:
            return json.loads(json_match.group())
    except:
        pass
    
    # Fallback: simple keyword analysis
    eligible = 'eligible' in analysis_text.lower() or 'covered' in analysis_text.lower()
    coverage = 80 if eligible else 0
    
    return {
        'eligible': eligible,
        'coverage_percentage': coverage,
        'explanation': analysis_text,
        'confidence': 0.85
    }

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
