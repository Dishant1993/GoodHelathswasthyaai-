import boto3
import json
import os
import hashlib
import uuid
from datetime import datetime
from decimal import Decimal

dynamodb = boto3.resource('dynamodb', region_name=os.environ.get('REGION', 'us-east-1'))
users_table = dynamodb.Table(os.environ.get('USERS_TABLE', 'swasthyaai-dev-users'))

def lambda_handler(event, context):
    try:
        # Parse request
        http_method = event.get('httpMethod', '')
        path = event.get('path', '')
        
        # Only parse body for POST/PUT requests
        body = {}
        if http_method in ['POST', 'PUT'] and event.get('body'):
            body = json.loads(event.get('body', '{}'))
        
        # Route to appropriate handler
        if '/auth/signup' in path and http_method == 'POST':
            return handle_signup(body)
        elif '/auth/login' in path and http_method == 'POST':
            return handle_login(body)
        elif '/auth/profile' in path and http_method == 'GET':
            return handle_get_profile(event)
        elif '/auth/profile' in path and http_method == 'PUT':
            return handle_update_profile(body)
        elif '/auth/doctors' in path and http_method == 'GET':
            return handle_get_doctors()
        elif '/auth/patients' in path and http_method == 'GET':
            return handle_get_patients()
        else:
            return error_response('Invalid endpoint', 404)
            
    except Exception as e:
        print(f"Error: {str(e)}")
        return error_response(f'Internal server error: {str(e)}', 500)

def handle_signup(body):
    """Handle user signup"""
    try:
        # Validate required fields
        email = body.get('email')
        password = body.get('password')
        name = body.get('name')
        role = body.get('role', 'patient')  # 'doctor' or 'patient'
        
        if not email or not password or not name:
            return error_response('Email, password, and name are required', 400)
        
        # Check if user already exists
        try:
            response = users_table.get_item(Key={'email': email})
            if 'Item' in response:
                return error_response('User already exists', 409)
        except Exception as e:
            print(f"Error checking existing user: {str(e)}")
        
        # Hash password
        password_hash = hashlib.sha256(password.encode()).hexdigest()
        
        # Create user ID
        user_id = str(uuid.uuid4())
        
        # Prepare user data
        user_data = {
            'user_id': user_id,
            'email': email,
            'password_hash': password_hash,
            'name': name,
            'role': role,
            'created_at': datetime.utcnow().isoformat(),
            'updated_at': datetime.utcnow().isoformat()
        }
        
        # Add role-specific fields
        if role == 'doctor':
            user_data.update({
                'degree': body.get('degree', ''),
                'experience': body.get('experience', ''),
                'specialization': body.get('specialization', ''),
                'phone': body.get('phone', '')
            })
        else:  # patient
            user_data.update({
                'age': body.get('age', ''),
                'gender': body.get('gender', ''),
                'phone': body.get('phone', ''),
                'address': body.get('address', ''),
                'city': body.get('city', ''),
                'state': body.get('state', ''),
                'zip_code': body.get('zip_code', ''),
                'blood_group': body.get('blood_group', '')
            })
        
        # Save to DynamoDB
        users_table.put_item(Item=user_data)
        
        # Remove password hash from response
        user_data.pop('password_hash', None)
        
        return success_response({
            'message': 'User created successfully',
            'user': user_data
        })
        
    except Exception as e:
        print(f"Signup error: {str(e)}")
        return error_response(f'Signup failed: {str(e)}', 500)

def handle_login(body):
    """Handle user login"""
    try:
        email = body.get('email')
        password = body.get('password')
        
        if not email or not password:
            return error_response('Email and password are required', 400)
        
        # Get user from database
        response = users_table.get_item(Key={'email': email})
        
        if 'Item' not in response:
            return error_response('Invalid credentials', 401)
        
        user = response['Item']
        
        # Verify password
        password_hash = hashlib.sha256(password.encode()).hexdigest()
        if user.get('password_hash') != password_hash:
            return error_response('Invalid credentials', 401)
        
        # Remove password hash from response
        user.pop('password_hash', None)
        
        # Generate session token (simplified - in production use JWT)
        session_token = str(uuid.uuid4())
        
        return success_response({
            'message': 'Login successful',
            'user': user,
            'token': session_token
        })
        
    except Exception as e:
        print(f"Login error: {str(e)}")
        return error_response(f'Login failed: {str(e)}', 500)

def handle_get_profile(event):
    """Get user profile"""
    try:
        # Get email from query parameters or headers
        email = event.get('queryStringParameters', {}).get('email')
        
        if not email:
            return error_response('Email is required', 400)
        
        response = users_table.get_item(Key={'email': email})
        
        if 'Item' not in response:
            return error_response('User not found', 404)
        
        user = response['Item']
        user.pop('password_hash', None)
        
        return success_response({'user': user})
        
    except Exception as e:
        print(f"Get profile error: {str(e)}")
        return error_response(f'Failed to get profile: {str(e)}', 500)

def handle_update_profile(body):
    """Update user profile"""
    try:
        email = body.get('email')
        
        if not email:
            return error_response('Email is required', 400)
        
        # Get existing user
        response = users_table.get_item(Key={'email': email})
        
        if 'Item' not in response:
            return error_response('User not found', 404)
        
        user = response['Item']
        
        # Update fields
        update_fields = ['name', 'phone', 'degree', 'experience', 'specialization',
                        'age', 'gender', 'address', 'city', 'state', 'zip_code', 'blood_group']
        
        for field in update_fields:
            if field in body:
                user[field] = body[field]
        
        user['updated_at'] = datetime.utcnow().isoformat()
        
        # Save updated user
        users_table.put_item(Item=user)
        
        user.pop('password_hash', None)
        
        return success_response({
            'message': 'Profile updated successfully',
            'user': user
        })
        
    except Exception as e:
        print(f"Update profile error: {str(e)}")
        return error_response(f'Failed to update profile: {str(e)}', 500)

def handle_get_doctors():
    """Get all doctors"""
    try:
        # Scan the table for all users with role='doctor'
        response = users_table.scan(
            FilterExpression='#role = :role',
            ExpressionAttributeNames={'#role': 'role'},
            ExpressionAttributeValues={':role': 'doctor'}
        )
        
        doctors = response.get('Items', [])
        
        # Remove password hashes
        for doctor in doctors:
            doctor.pop('password_hash', None)
        
        return success_response({
            'success': True,
            'doctors': doctors,
            'count': len(doctors)
        })
        
    except Exception as e:
        print(f"Get doctors error: {str(e)}")
        return error_response(f'Failed to get doctors: {str(e)}', 500)

def handle_get_patients():
    """Get all patients"""
    try:
        # Scan the table for all users with role='patient'
        response = users_table.scan(
            FilterExpression='#role = :role',
            ExpressionAttributeNames={'#role': 'role'},
            ExpressionAttributeValues={':role': 'patient'}
        )
        
        patients = response.get('Items', [])
        
        # Remove password hashes
        for patient in patients:
            patient.pop('password_hash', None)
        
        return success_response({
            'success': True,
            'patients': patients,
            'count': len(patients)
        })
        
    except Exception as e:
        print(f"Get patients error: {str(e)}")
        return error_response(f'Failed to get patients: {str(e)}', 500)

def success_response(data):
    return {
        'statusCode': 200,
        'headers': {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Headers': 'Content-Type,Authorization',
            'Access-Control-Allow-Methods': 'GET,POST,PUT,OPTIONS',
            'Content-Type': 'application/json'
        },
        'body': json.dumps(data, default=str)
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
