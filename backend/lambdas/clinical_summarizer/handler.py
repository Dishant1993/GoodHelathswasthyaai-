"""
SwasthyaAI - Clinical Summarizer Lambda Function
Converts unstructured clinical notes into structured SOAP format
"""

import json
import os
import boto3
import logging
from datetime import datetime
from typing import Dict, Any, List
from decimal import Decimal

# Initialize AWS clients
bedrock_runtime = boto3.client('bedrock-runtime', region_name=os.environ['AWS_REGION'])
comprehend_medical = boto3.client('comprehendmedical', region_name=os.environ['AWS_REGION'])
dynamodb = boto3.resource('dynamodb', region_name=os.environ['AWS_REGION'])
cloudwatch = boto3.client('cloudwatch', region_name=os.environ['AWS_REGION'])

# Initialize logger
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Environment variables
CLINICAL_NOTES_TABLE = os.environ['CLINICAL_NOTES_TABLE']
BEDROCK_MODEL_ID = os.environ.get('BEDROCK_MODEL_ID', 'anthropic.claude-3-sonnet-20240229-v1:0')
CONFIDENCE_THRESHOLD = float(os.environ.get('CONFIDENCE_THRESHOLD', '0.7'))

# DynamoDB table
clinical_notes_table = dynamodb.Table(CLINICAL_NOTES_TABLE)


def lambda_handler(event, context):
    """
    Main Lambda handler for clinical note summarization
    
    Expected event structure:
    {
        "patient_id": "uuid",
        "clinical_text": "unstructured clinical note",
        "doctor_id": "uuid",
        "note_type": "consultation|admission|discharge"
    }
    """
    try:
        logger.info(f"Received event: {json.dumps(event)}")
        
        # Parse input
        body = json.loads(event['body']) if 'body' in event else event
        patient_id = body['patient_id']
        clinical_text = body['clinical_text']
        doctor_id = body['doctor_id']
        note_type = body.get('note_type', 'consultation')
        
        # Step 1: Extract medical entities using Comprehend Medical
        logger.info("Extracting medical entities...")
        entities = extract_medical_entities(clinical_text)
        
        # Step 2: Generate SOAP note using Bedrock
        logger.info("Generating SOAP note...")
        soap_note = generate_soap_note(clinical_text, entities)
        
        # Step 3: Calculate confidence scores
        logger.info("Calculating confidence scores...")
        confidence_scores = calculate_confidence_scores(soap_note, entities, clinical_text)
        
        # Step 4: Store draft SOAP note in DynamoDB
        logger.info("Storing SOAP note...")
        note_id = store_soap_note(
            patient_id=patient_id,
            doctor_id=doctor_id,
            note_type=note_type,
            original_text=clinical_text,
            soap_note=soap_note,
            entities=entities,
            confidence_scores=confidence_scores
        )
        
        # Step 5: Send metrics to CloudWatch
        send_metrics(confidence_scores)
        
        # Prepare response
        response = {
            'note_id': note_id,
            'soap_note': soap_note,
            'entities': entities,
            'confidence_scores': confidence_scores,
            'requires_review': any(score < CONFIDENCE_THRESHOLD for score in confidence_scores.values())
        }
        
        logger.info(f"Successfully generated SOAP note: {note_id}")
        
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps(response, default=decimal_default)
        }
        
    except Exception as e:
        logger.error(f"Error processing clinical note: {str(e)}", exc_info=True)
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'error': 'Internal server error',
                'message': str(e)
            })
        }


def extract_medical_entities(text: str) -> List[Dict[str, Any]]:
    """
    Extract medical entities using Amazon Comprehend Medical
    """
    try:
        response = comprehend_medical.detect_entities_v2(Text=text)
        
        entities = []
        for entity in response['Entities']:
            if entity['Score'] >= CONFIDENCE_THRESHOLD:
                entities.append({
                    'text': entity['Text'],
                    'type': entity['Type'],
                    'category': entity['Category'],
                    'score': float(entity['Score']),
                    'begin_offset': entity['BeginOffset'],
                    'end_offset': entity['EndOffset'],
                    'attributes': entity.get('Attributes', []),
                    'traits': entity.get('Traits', [])
                })
        
        logger.info(f"Extracted {len(entities)} medical entities")
        return entities
        
    except Exception as e:
        logger.error(f"Error extracting entities: {str(e)}")
        return []


def generate_soap_note(clinical_text: str, entities: List[Dict[str, Any]]) -> Dict[str, str]:
    """
    Generate SOAP note using Amazon Bedrock (Claude)
    """
    try:
        # Prepare entities summary
        entities_summary = "\n".join([
            f"- {e['text']} ({e['type']}, confidence: {e['score']:.2f})"
            for e in entities[:20]  # Limit to top 20 entities
        ])
        
        # Construct prompt
        prompt = f"""You are a medical documentation assistant. Convert the following clinical note into a structured SOAP format.

Input Clinical Note:
{clinical_text}

Extracted Medical Entities:
{entities_summary}

Generate a SOAP note with the following sections:
- Subjective: Patient's reported symptoms and history
- Objective: Observable findings, vitals, examination results
- Assessment: Clinical diagnosis and interpretation
- Plan: Treatment plan, medications, follow-up

Requirements:
- Preserve all medical entities from the input
- Use professional medical terminology
- Be concise but complete
- Include confidence assessment for each section (0-1 scale)

Output Format (JSON):
{{
  "subjective": "...",
  "subjective_confidence": 0.95,
  "objective": "...",
  "objective_confidence": 0.90,
  "assessment": "...",
  "assessment_confidence": 0.85,
  "plan": "...",
  "plan_confidence": 0.88
}}"""
        
        # Call Bedrock
        request_body = {
            "anthropic_version": "bedrock-2023-05-31",
            "max_tokens": 2000,
            "temperature": 0.3,
            "top_p": 0.9,
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
        content = response_body['content'][0]['text']
        
        # Parse JSON from response
        # Extract JSON from markdown code blocks if present
        if '```json' in content:
            content = content.split('```json')[1].split('```')[0].strip()
        elif '```' in content:
            content = content.split('```')[1].split('```')[0].strip()
        
        soap_note = json.loads(content)
        
        logger.info("Successfully generated SOAP note")
        return soap_note
        
    except Exception as e:
        logger.error(f"Error generating SOAP note: {str(e)}")
        # Return empty SOAP note on error
        return {
            'subjective': '',
            'subjective_confidence': 0.0,
            'objective': '',
            'objective_confidence': 0.0,
            'assessment': '',
            'assessment_confidence': 0.0,
            'plan': '',
            'plan_confidence': 0.0
        }


def calculate_confidence_scores(
    soap_note: Dict[str, Any],
    entities: List[Dict[str, Any]],
    original_text: str
) -> Dict[str, float]:
    """
    Calculate overall confidence scores for the SOAP note
    """
    try:
        # Extract confidence scores from SOAP note
        subjective_conf = soap_note.get('subjective_confidence', 0.0)
        objective_conf = soap_note.get('objective_confidence', 0.0)
        assessment_conf = soap_note.get('assessment_confidence', 0.0)
        plan_conf = soap_note.get('plan_confidence', 0.0)
        
        # Calculate entity coverage (% of entities included in SOAP)
        soap_text = ' '.join([
            soap_note.get('subjective', ''),
            soap_note.get('objective', ''),
            soap_note.get('assessment', ''),
            soap_note.get('plan', '')
        ]).lower()
        
        entities_in_soap = sum(1 for e in entities if e['text'].lower() in soap_text)
        entity_coverage = entities_in_soap / len(entities) if entities else 1.0
        
        # Calculate completeness (all sections present and non-empty)
        completeness = 1.0 if all([
            soap_note.get('subjective'),
            soap_note.get('objective'),
            soap_note.get('assessment'),
            soap_note.get('plan')
        ]) else 0.5
        
        # Calculate overall confidence
        overall_confidence = (
            0.3 * (subjective_conf + objective_conf + assessment_conf + plan_conf) / 4 +
            0.4 * entity_coverage +
            0.3 * completeness
        )
        
        return {
            'subjective': float(subjective_conf),
            'objective': float(objective_conf),
            'assessment': float(assessment_conf),
            'plan': float(plan_conf),
            'entity_coverage': float(entity_coverage),
            'completeness': float(completeness),
            'overall': float(overall_confidence)
        }
        
    except Exception as e:
        logger.error(f"Error calculating confidence scores: {str(e)}")
        return {
            'subjective': 0.0,
            'objective': 0.0,
            'assessment': 0.0,
            'plan': 0.0,
            'entity_coverage': 0.0,
            'completeness': 0.0,
            'overall': 0.0
        }


def store_soap_note(
    patient_id: str,
    doctor_id: str,
    note_type: str,
    original_text: str,
    soap_note: Dict[str, Any],
    entities: List[Dict[str, Any]],
    confidence_scores: Dict[str, float]
) -> str:
    """
    Store SOAP note in DynamoDB
    """
    try:
        note_id = f"{datetime.utcnow().isoformat()}Z"
        
        item = {
            'patient_id': patient_id,
            'note_id': note_id,
            'note_type': note_type,
            'original_text': original_text,
            'soap_sections': {
                'subjective': soap_note.get('subjective', ''),
                'objective': soap_note.get('objective', ''),
                'assessment': soap_note.get('assessment', ''),
                'plan': soap_note.get('plan', '')
            },
            'entities': entities,
            'confidence_scores': confidence_scores,
            'status': 'draft',
            'created_by': doctor_id,
            'created_at': datetime.utcnow().isoformat(),
            'updated_at': datetime.utcnow().isoformat()
        }
        
        # Convert floats to Decimal for DynamoDB
        item = json.loads(json.dumps(item), parse_float=Decimal)
        
        clinical_notes_table.put_item(Item=item)
        
        logger.info(f"Stored SOAP note: {note_id}")
        return note_id
        
    except Exception as e:
        logger.error(f"Error storing SOAP note: {str(e)}")
        raise


def send_metrics(confidence_scores: Dict[str, float]):
    """
    Send metrics to CloudWatch
    """
    try:
        cloudwatch.put_metric_data(
            Namespace='SwasthyaAI/ClinicalSummarizer',
            MetricData=[
                {
                    'MetricName': 'OverallConfidence',
                    'Value': confidence_scores['overall'],
                    'Unit': 'None'
                },
                {
                    'MetricName': 'EntityCoverage',
                    'Value': confidence_scores['entity_coverage'],
                    'Unit': 'None'
                }
            ]
        )
    except Exception as e:
        logger.warning(f"Error sending metrics: {str(e)}")


def decimal_default(obj):
    """JSON serializer for Decimal objects"""
    if isinstance(obj, Decimal):
        return float(obj)
    raise TypeError(f"Object of type {type(obj)} is not JSON serializable")
