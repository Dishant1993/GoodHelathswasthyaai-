import boto3
import json
import os
from datetime import datetime
from decimal import Decimal

dynamodb = boto3.resource('dynamodb', region_name=os.environ.get('REGION', 'us-east-1'))
s3 = boto3.client('s3', region_name=os.environ.get('REGION', 'us-east-1'))

# DynamoDB tables
clinical_notes_table = dynamodb.Table(os.environ.get('CLINICAL_NOTES_TABLE', 'swasthyaai-dev-clinical-notes'))
appointments_table = dynamodb.Table(os.environ.get('APPOINTMENTS_TABLE', 'swasthyaai-Appointments-dev'))
timeline_table = dynamodb.Table(os.environ.get('TIMELINE_TABLE', 'swasthyaai-dev-timeline'))

def lambda_handler(event, context):
    try:
        body = json.loads(event.get('body', '{}'))
        path = event.get('path', '')
        http_method = event.get('httpMethod', '')
        
        if '/history/patient' in path and http_method == 'GET':
            return handle_get_patient_history(event)
        elif '/history/timeline' in path and http_method == 'GET':
            return handle_get_timeline(event)
        elif '/history/notes' in path and http_method == 'GET':
            return handle_get_clinical_notes(event)
        elif '/history/appointments' in path and http_method == 'GET':
            return handle_get_appointments(event)
        else:
            return error_response('Invalid endpoint', 404)
            
    except Exception as e:
        print(f"Error: {str(e)}")
        return error_response(f'Internal server error: {str(e)}', 500)

def handle_get_patient_history(event):
    """Get comprehensive patient history"""
    try:
        patient_id = event.get('queryStringParameters', {}).get('patient_id')
        
        if not patient_id:
            return error_response('patient_id is required', 400)
        
        # Get clinical notes
        notes_response = clinical_notes_table.query(
            IndexName='PatientIndex',
            KeyConditionExpression='patient_id = :pid',
            ExpressionAttributeValues={':pid': patient_id},
            ScanIndexForward=False,  # Most recent first
            Limit=50
        )
        
        # Get appointments
        appointments_response = appointments_table.query(
            IndexName='PatientIndex',
            KeyConditionExpression='patient_id = :pid',
            ExpressionAttributeValues={':pid': patient_id},
            ScanIndexForward=False,
            Limit=50
        )
        
        # Get timeline events
        timeline_response = timeline_table.query(
            KeyConditionExpression='patient_id = :pid',
            ExpressionAttributeValues={':pid': patient_id},
            ScanIndexForward=False,
            Limit=100
        )
        
        history = {
            'patient_id': patient_id,
            'clinical_notes': notes_response.get('Items', []),
            'appointments': appointments_response.get('Items', []),
            'timeline': timeline_response.get('Items', []),
            'summary': {
                'total_notes': len(notes_response.get('Items', [])),
                'total_appointments': len(appointments_response.get('Items', [])),
                'total_events': len(timeline_response.get('Items', []))
            }
        }
        
        return success_response(history)
        
    except Exception as e:
        print(f"Get patient history error: {str(e)}")
        return error_response(f'Failed to get patient history: {str(e)}', 500)

def handle_get_timeline(event):
    """Get patient timeline"""
    try:
        patient_id = event.get('queryStringParameters', {}).get('patient_id')
        
        if not patient_id:
            return error_response('patient_id is required', 400)
        
        response = timeline_table.query(
            KeyConditionExpression='patient_id = :pid',
            ExpressionAttributeValues={':pid': patient_id},
            ScanIndexForward=False,
            Limit=100
        )
        
        return success_response({
            'patient_id': patient_id,
            'timeline': response.get('Items', []),
            'count': len(response.get('Items', []))
        })
        
    except Exception as e:
        print(f"Get timeline error: {str(e)}")
        return error_response(f'Failed to get timeline: {str(e)}', 500)

def handle_get_clinical_notes(event):
    """Get patient clinical notes"""
    try:
        patient_id = event.get('queryStringParameters', {}).get('patient_id')
        
        if not patient_id:
            return error_response('patient_id is required', 400)
        
        response = clinical_notes_table.query(
            IndexName='PatientIndex',
            KeyConditionExpression='patient_id = :pid',
            ExpressionAttributeValues={':pid': patient_id},
            ScanIndexForward=False,
            Limit=50
        )
        
        notes = response.get('Items', [])
        
        # Enrich with S3 URLs if available
        for note in notes:
            if note.get('s3_key'):
                try:
                    url = s3.generate_presigned_url(
                        'get_object',
                        Params={
                            'Bucket': os.environ.get('CLINICAL_LOGS_BUCKET', 'swasthyaai-clinical-logs-dev-348103269436'),
                            'Key': note['s3_key']
                        },
                        ExpiresIn=3600
                    )
                    note['download_url'] = url
                except Exception as e:
                    print(f"Error generating presigned URL: {str(e)}")
        
        return success_response({
            'patient_id': patient_id,
            'notes': notes,
            'count': len(notes)
        })
        
    except Exception as e:
        print(f"Get clinical notes error: {str(e)}")
        return error_response(f'Failed to get clinical notes: {str(e)}', 500)

def handle_get_appointments(event):
    """Get patient appointments"""
    try:
        patient_id = event.get('queryStringParameters', {}).get('patient_id')
        
        if not patient_id:
            return error_response('patient_id is required', 400)
        
        response = appointments_table.query(
            IndexName='PatientIndex',
            KeyConditionExpression='patient_id = :pid',
            ExpressionAttributeValues={':pid': patient_id},
            ScanIndexForward=False,
            Limit=50
        )
        
        appointments = response.get('Items', [])
        
        # Categorize appointments
        upcoming = []
        past = []
        current_date = datetime.utcnow().isoformat()
        
        for apt in appointments:
            if apt.get('date', '') >= current_date[:10]:
                upcoming.append(apt)
            else:
                past.append(apt)
        
        return success_response({
            'patient_id': patient_id,
            'appointments': {
                'upcoming': upcoming,
                'past': past,
                'all': appointments
            },
            'count': {
                'upcoming': len(upcoming),
                'past': len(past),
                'total': len(appointments)
            }
        })
        
    except Exception as e:
        print(f"Get appointments error: {str(e)}")
        return error_response(f'Failed to get appointments: {str(e)}', 500)

def success_response(data):
    return {
        'statusCode': 200,
        'headers': {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Headers': 'Content-Type,Authorization',
            'Access-Control-Allow-Methods': 'GET,POST,OPTIONS',
            'Content-Type': 'application/json'
        },
        'body': json.dumps(data, default=decimal_default)
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

def decimal_default(obj):
    if isinstance(obj, Decimal):
        return float(obj)
    raise TypeError
