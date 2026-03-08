"""
SwasthyaAI - Patient Explainer Lambda Function
Generates patient-friendly explanations in multiple languages
"""

import json
import os
import boto3
import logging
from datetime import datetime
from typing import Dict, Any
from decimal import Decimal

# Initialize AWS clients
bedrock_runtime = boto3.client('bedrock-runtime', region_name=os.environ['AWS_REGION'])
translate = boto3.client('translate', region_name=os.environ['AWS_REGION'])
dynamodb = boto3.resource('dynamodb', region_name=os.environ['AWS_REGION'])

# Initialize logger
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Environment variables
CLINICAL_NOTES_TABLE = os.environ['CLINICAL_NOTES_TABLE']
BEDROCK_MODEL_ID = os.environ.get('BEDROCK_MODEL_ID', 'anthropic.claude-3-sonnet-20240229-v1:0')

# DynamoDB table
clinical_notes_table = dynamodb.Table(CLINICAL_NOTES_TABLE)

# Supported languages
SUPPORTED_LANGUAGES = {
    'en': 'English',
    'hi': 'Hindi',
    'ta': 'Tamil',
    'te': 'Telugu',
    'bn': 'Bengali',
    'mr': 'Marathi',
    'gu': 'Gujarati',
    'kn': 'Kannada',
    'ml': 'Malayalam',
    'pa': 'Punjabi'
}


def lambda_handler(event, context):
    """
    Main Lambda handler for patient explanation generation
    
    Expected event structure:
    {
        "note_id": "uuid",
        "patient_id": "uuid",
        "target_language": "hi",
        "clinical_content": "SOAP note or diagnosis"
    }
    """
    try:
        logger.info(f"Received event: {json.dumps(event)}")
        
        # Parse input
        body = json.loads(event['body']) if 'body' in event else event
        note_id = body.get('note_id')
        patient_id = body['patient_id']
        target_language = body.get('target_language', 'en')
        clinical_content = body.get('clinical_content', '')
        
        # Validate language
        if target_language not in SUPPORTED_LANGUAGES:
            return error_response(400, f"Unsupported language: {target_language}")
        
        # If note_id provided, fetch clinical content
        if note_id and not clinical_content:
            clinical_content = fetch_clinical_content(patient_id, note_id)
        
        if not clinical_content:
            return error_response(400, "No clinical content provided")
        
        # Step 1: Generate simplified explanation in English
        logger.info("Generating patient-friendly explanation...")
        english_explanation = generate_patient_explanation(clinical_content)
        
        # Step 2: Translate to target language if not English
        if target_language != 'en':
            logger.info(f"Translating to {SUPPORTED_LANGUAGES[target_language]}...")
            translated_explanation = translate_explanation(english_explanation, target_language)
        else:
            translated_explanation = english_explanation
        
        # Step 3: Calculate confidence score
        confidence_score = calculate_explanation_confidence(
            english_explanation,
            clinical_content
        )
        
        # Step 4: Store explanation
        explanation_id = store_explanation(
            patient_id=patient_id,
            note_id=note_id,
            english_text=english_explanation,
            translated_text=translated_explanation,
            target_language=target_language,
            confidence_score=confidence_score
        )
        
        # Prepare response
        response = {
            'explanation_id': explanation_id,
            'english_explanation': english_explanation,
            'translated_explanation': translated_explanation,
            'target_language': target_language,
            'language_name': SUPPORTED_LANGUAGES[target_language],
            'confidence_score': confidence_score,
            'requires_review': confidence_score < 0.7
        }
        
        logger.info(f"Successfully generated explanation: {explanation_id}")
        
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps(response, default=decimal_default)
        }
        
    except Exception as e:
        logger.error(f"Error generating explanation: {str(e)}", exc_info=True)
        return error_response(500, str(e))


def fetch_clinical_content(patient_id: str, note_id: str) -> str:
    """Fetch clinical content from DynamoDB"""
    try:
        response = clinical_notes_table.get_item(
            Key={'patient_id': patient_id, 'note_id': note_id}
        )
        
        if 'Item' not in response:
            return ""
        
        item = response['Item']
        soap = item.get('soap_sections', {})
        
        # Combine SOAP sections
        content = f"""
Symptoms: {soap.get('subjective', '')}
Findings: {soap.get('objective', '')}
Diagnosis: {soap.get('assessment', '')}
Treatment Plan: {soap.get('plan', '')}
        """.strip()
        
        return content
        
    except Exception as e:
        logger.error(f"Error fetching clinical content: {str(e)}")
        return ""


def generate_patient_explanation(clinical_content: str) -> str:
    """Generate patient-friendly explanation using Bedrock"""
    try:
        prompt = f"""You are a medical communication expert. Explain the following medical information in simple, patient-friendly language.

Medical Content:
{clinical_content}

Guidelines:
- Use simple, everyday words (avoid medical jargon)
- Explain medical terms when necessary
- Use analogies and examples when helpful
- Be reassuring but honest
- Include what the patient should do next
- Keep sentences short and clear
- Write at a 6th-8th grade reading level
- Be empathetic and supportive

Generate a patient-friendly explanation that helps them understand their condition and treatment."""

        request_body = {
            "anthropic_version": "bedrock-2023-05-31",
            "max_tokens": 1500,
            "temperature": 0.5,
            "messages": [
                {
                    "role": "user",
                    "content": prompt
                }
            ]
        }
        
        response = bedrock_runtime.invoke_model(
            modelId=BEDROCK_MODEL_ID,
            body=json.dumps(request_body)
        )
        
        response_body = json.loads(response['body'].read())
        explanation = response_body['content'][0]['text'].strip()
        
        logger.info("Successfully generated patient explanation")
        return explanation
        
    except Exception as e:
        logger.error(f"Error generating explanation: {str(e)}")
        return "Unable to generate explanation at this time."


def translate_explanation(text: str, target_language: str) -> str:
    """Translate explanation to target language"""
    try:
        response = translate.translate_text(
            Text=text,
            SourceLanguageCode='en',
            TargetLanguageCode=target_language,
            Settings={
                'Formality': 'FORMAL'
            }
        )
        
        translated_text = response['TranslatedText']
        logger.info(f"Successfully translated to {target_language}")
        return translated_text
        
    except Exception as e:
        logger.error(f"Error translating text: {str(e)}")
        return text  # Return original text on error


def calculate_explanation_confidence(explanation: str, clinical_content: str) -> float:
    """Calculate confidence score for explanation"""
    try:
        # Length check (not too short, not too long)
        word_count = len(explanation.split())
        length_score = 1.0 if 50 <= word_count <= 300 else 0.7
        
        # Readability check (simple heuristic)
        avg_word_length = sum(len(word) for word in explanation.split()) / word_count
        readability_score = 1.0 if avg_word_length < 6 else 0.8
        
        # Content coverage (check if key terms are explained)
        coverage_score = 0.9  # Placeholder
        
        # Overall confidence
        confidence = (length_score + readability_score + coverage_score) / 3
        
        return float(confidence)
        
    except Exception as e:
        logger.error(f"Error calculating confidence: {str(e)}")
        return 0.5


def store_explanation(
    patient_id: str,
    note_id: str,
    english_text: str,
    translated_text: str,
    target_language: str,
    confidence_score: float
) -> str:
    """Store explanation in DynamoDB"""
    try:
        explanation_id = f"exp-{datetime.utcnow().isoformat()}Z"
        
        # Update clinical note with explanation
        clinical_notes_table.update_item(
            Key={'patient_id': patient_id, 'note_id': note_id},
            UpdateExpression='SET patient_explanation = :exp, updated_at = :updated',
            ExpressionAttributeValues={
                ':exp': {
                    'explanation_id': explanation_id,
                    'english_text': english_text,
                    'translated_text': translated_text,
                    'target_language': target_language,
                    'confidence_score': Decimal(str(confidence_score)),
                    'created_at': datetime.utcnow().isoformat()
                },
                ':updated': datetime.utcnow().isoformat()
            }
        )
        
        logger.info(f"Stored explanation: {explanation_id}")
        return explanation_id
        
    except Exception as e:
        logger.error(f"Error storing explanation: {str(e)}")
        raise


def error_response(status_code: int, message: str):
    """Generate error response"""
    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps({
            'error': message
        })
    }


def decimal_default(obj):
    """JSON serializer for Decimal objects"""
    if isinstance(obj, Decimal):
        return float(obj)
    raise TypeError(f"Object of type {type(obj)} is not JSON serializable")
