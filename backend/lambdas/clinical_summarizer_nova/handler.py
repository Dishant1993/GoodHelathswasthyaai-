"""
SwasthyaAI - Clinical Summarizer Lambda Function (Nova 2 Lite)
Converts unstructured clinical notes into structured SOAP format using Amazon Nova 2 Lite
"""

import json
import os
import boto3
import logging
import uuid
from datetime import datetime
from typing import Dict, Any, List
from decimal import Decimal

# Initialize AWS clients
bedrock_runtime = boto3.client('bedrock-runtime', region_name=os.environ.get('REGION', 'us-east-1'))
comprehend_medical = boto3.client('comprehendmedical', region_name=os.environ.get('REGION', 'us-east-1'))
s3 = boto3.client('s3', region_name=os.environ.get('REGION', 'us-east-1'))
dynamodb = boto3.resource('dynamodb', region_name=os.environ.get('REGION', 'us-east-1'))

# DynamoDB tables
clinical_notes_table = dynamodb.Table(os.environ.get('CLINICAL_NOTES_TABLE', 'swasthyaai-dev-clinical-notes'))
timeline_table = dynamodb.Table(os.environ.get('TIMELINE_TABLE', 'swasthyaai-dev-timeline'))

# Initialize logger
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Environment variables
BEDROCK_MODEL_ID = 'us.amazon.nova-lite-v1:0'
CONFIDENCE_THRESHOLD = float(os.environ.get('CONFIDENCE_THRESHOLD', '0.9'))
LOGS_BUCKET = os.environ.get('LOGS_BUCKET', 'swasthyaai-clinical-logs')

SYSTEM_PROMPT = """You are a specialized medical assistant. 
Format clinical notes into S, O, A, and P sections with at least a 90% confidence score. 
Be concise and HIPAA-compliant. Output as JSON with subjective, objective, assessment, and plan fields."""


def lambda_handler(event, context):
    """Main Lambda handler for clinical note summarization"""
    try:
        logger.info(f"Received event: {json.dumps(event)}")
        
        # Parse input
        body = json.loads(event.get('body', '{}'))
        patient_id = body.get('patient_id')
        clinical_text = body.get('clinical_data') or body.get('clinical_text')
        user_id = body.get('user_id') or body.get('doctor_id', 'anonymous')
        
        if not clinical_text:
            return error_response('clinical_data or clinical_text is required', 400)

        
        # Step 1: Extract medical entities
        logger.info("Extracting medical entities...")
        entities = extract_medical_entities(clinical_text)
        
        # Step 2: Generate SOAP note using Nova 2 Lite
        logger.info("Generating SOAP note with Nova 2 Lite...")
        soap_note = generate_soap_note_nova(clinical_text, entities)
        
        # Step 3: Calculate confidence
        confidence = calculate_confidence(soap_note, entities)
        
        # Step 4: Save to DynamoDB
        note_id = str(uuid.uuid4())
        timestamp = datetime.utcnow().isoformat()
        
        clinical_note_item = {
            'note_id': note_id,
            'patient_id': patient_id or 'unknown',
            'doctor_id': user_id,
            'clinical_text': clinical_text,
            'soap_note': soap_note,
            'entities': entities,
            'confidence': Decimal(str(confidence)),
            'created_at': timestamp,
            'requires_review': confidence < CONFIDENCE_THRESHOLD
        }
        
        clinical_notes_table.put_item(Item=clinical_note_item)
        
        # Add to timeline
        if patient_id:
            timeline_item = {
                'patient_id': patient_id,
                'event_timestamp': timestamp,
                'event_type': 'clinical_note',
                'event_id': note_id,
                'description': f'Clinical note created by {user_id}',
                'data': {
                    'note_id': note_id,
                    'confidence': Decimal(str(confidence))
                }
            }
            timeline_table.put_item(Item=timeline_item)
        
        # Step 5: Save to S3
        log_data = {
            'timestamp': timestamp,
            'user_id': user_id,
            'patient_id': patient_id,
            'query': clinical_text,
            'response': soap_note,
            'entities': entities,
            'confidence': confidence
        }
        
        s3.put_object(
            Bucket=LOGS_BUCKET,
            Key=f'logs/{user_id}/{timestamp}.json',
            Body=json.dumps(log_data),
            ServerSideEncryption='AES256',
            ContentType='application/json'
        )
        
        response_data = {
            'note_id': note_id,
            'soap_note': soap_note,
            'confidence': float(confidence),
            'entities_count': len(entities),
            'requires_review': confidence < CONFIDENCE_THRESHOLD,
            'timestamp': timestamp
        }
        
        logger.info(f"Successfully generated SOAP note with confidence: {confidence}")
        return success_response(response_data)
        
    except Exception as e:
        logger.error(f"Error: {str(e)}", exc_info=True)
        return error_response(f'Internal server error: {str(e)}', 500)


def extract_medical_entities(text: str) -> List[Dict[str, Any]]:
    """Extract medical entities using Amazon Comprehend Medical"""
    try:
        response = comprehend_medical.detect_entities_v2(Text=text)
        entities = []
        
        for entity in response['Entities']:
            if entity['Score'] >= 0.7:
                entities.append({
                    'text': entity['Text'],
                    'type': entity['Type'],
                    'category': entity['Category'],
                    'score': Decimal(str(entity['Score']))
                })
        
        logger.info(f"Extracted {len(entities)} medical entities")
        return entities
    except Exception as e:
        logger.error(f"Error extracting entities: {str(e)}")
        return []



def generate_soap_note_nova(clinical_text: str, entities: List[Dict[str, Any]]) -> Dict[str, str]:
    """Generate SOAP note using Amazon Nova 2 Lite"""
    try:
        entities_summary = "\n".join([
            f"- {e['text']} ({e['type']})" for e in entities[:15]
        ])
        
        user_prompt = f"""Clinical Note:
{clinical_text}

Key Medical Entities:
{entities_summary}

Generate a SOAP note in JSON format with these exact fields:
- subjective: Patient's symptoms and history
- objective: Observable findings and vitals
- assessment: Diagnosis and clinical interpretation
- plan: Treatment plan and follow-up

Be concise, professional, and HIPAA-compliant."""
        
        # Call Nova Lite
        response = bedrock_runtime.invoke_model(
            modelId=BEDROCK_MODEL_ID,
            body=json.dumps({
                'messages': [
                    {'role': 'user', 'content': [
                        {'text': f"{SYSTEM_PROMPT}\n\n{user_prompt}"}
                    ]}
                ],
                'inferenceConfig': {
                    'temperature': 0.3,
                    'maxTokens': 2000
                }
            })
        )
        
        result = json.loads(response['body'].read())
        
        # Parse Nova Lite response format
        if 'output' in result and 'message' in result['output']:
            message_content = result['output']['message']['content']
            if isinstance(message_content, list) and len(message_content) > 0:
                soap_text = message_content[0].get('text', '')
            else:
                soap_text = str(message_content)
        elif 'content' in result and isinstance(result['content'], list):
            soap_text = result['content'][0].get('text', '')
        else:
            soap_text = str(result)
        
        # Parse JSON from response
        if '```json' in soap_text:
            soap_text = soap_text.split('```json')[1].split('```')[0].strip()
        elif '```' in soap_text:
            soap_text = soap_text.split('```')[1].split('```')[0].strip()
        
        soap_note = json.loads(soap_text)
        
        # Ensure all required fields exist
        required_fields = ['subjective', 'objective', 'assessment', 'plan']
        for field in required_fields:
            if field not in soap_note:
                soap_note[field] = ''
        
        logger.info("Successfully generated SOAP note with Nova 2 Lite")
        return soap_note
        
    except Exception as e:
        logger.error(f"Error generating SOAP note: {str(e)}")
        return {
            'subjective': '',
            'objective': '',
            'assessment': '',
            'plan': '',
            'error': str(e)
        }


def calculate_confidence(soap_note: Dict[str, str], entities: List[Dict[str, Any]]) -> float:
    """Calculate confidence score for SOAP note"""
    try:
        # Check completeness
        completeness = sum(1 for field in ['subjective', 'objective', 'assessment', 'plan'] 
                          if soap_note.get(field)) / 4.0
        
        # Check entity coverage
        soap_text = ' '.join(soap_note.values()).lower()
        entities_found = sum(1 for e in entities if e['text'].lower() in soap_text)
        entity_coverage = entities_found / len(entities) if entities else 1.0
        
        # Calculate overall confidence
        confidence = (0.6 * completeness + 0.4 * entity_coverage)
        
        return round(confidence, 2)
    except:
        return 0.5


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
