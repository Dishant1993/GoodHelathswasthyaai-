const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, PutCommand, QueryCommand, GetCommand } = require('@aws-sdk/lib-dynamodb');

const client = new DynamoDBClient({ region: process.env.AWS_REGION || 'ap-south-1' });
const docClient = DynamoDBDocumentClient.from(client);

const APPOINTMENTS_TABLE = process.env.APPOINTMENTS_TABLE || 'SwasthyaAI-Appointments';
const DOCTORS_TABLE = process.env.DOCTORS_TABLE || 'SwasthyaAI-Doctors';

exports.handler = async (event) => {
    try {
        const httpMethod = event.httpMethod || event.requestContext?.http?.method;
        const path = event.path || event.requestContext?.http?.path;
        
        if (httpMethod === 'OPTIONS') {
            return corsResponse(200, {});
        }
        
        if (httpMethod === 'POST' && path.includes('/book')) {
            return await bookAppointment(event);
        }
        
        if (httpMethod === 'GET' && path.includes('/patient')) {
            return await listAppointments(event);
        }
        
        if (httpMethod === 'GET' && path.includes('/doctor')) {
            return await listDoctorAppointments(event);
        }
        
        if (httpMethod === 'GET' && path.includes('/availability')) {
            return await checkAvailability(event);
        }
        
        if (httpMethod === 'GET' && path.includes('/list')) {
            return await listAppointments(event);
        }
        
        return errorResponse('Invalid endpoint', 404);
        
    } catch (error) {
        console.error('Error:', error);
        return errorResponse(`Internal server error: ${error.message}`, 500);
    }
};

async function bookAppointment(event) {
    const body = JSON.parse(event.body || '{}');
    const { patient_id, doctor_id, date, time, reason } = body;
    
    if (!patient_id || !doctor_id || !date || !time) {
        return errorResponse('patient_id, doctor_id, date, and time are required', 400);
    }

    
    // Check if slot is available
    const isAvailable = await checkSlotAvailability(doctor_id, date, time);
    if (!isAvailable) {
        return errorResponse('Time slot not available', 409);
    }
    
    // Create appointment
    const appointment_id = `${patient_id}-${Date.now()}`;
    const timestamp = new Date().toISOString();
    
    const appointment = {
        appointment_id,
        patient_id,
        doctor_id,
        date,
        time,
        reason: reason || 'General consultation',
        status: 'confirmed',
        created_at: timestamp,
        updated_at: timestamp
    };
    
    await docClient.send(new PutCommand({
        TableName: APPOINTMENTS_TABLE,
        Item: appointment
    }));
    
    return successResponse({
        appointment_id,
        status: 'confirmed',
        message: 'Appointment booked successfully'
    });
}

async function checkAvailability(event) {
    const params = event.queryStringParameters || {};
    const { doctor_id, date } = params;
    
    if (!doctor_id || !date) {
        return errorResponse('doctor_id and date are required', 400);
    }
    
    // Query appointments for doctor on specific date
    const result = await docClient.send(new QueryCommand({
        TableName: APPOINTMENTS_TABLE,
        IndexName: 'DoctorDateIndex',
        KeyConditionExpression: 'doctor_id = :doctor_id AND #date = :date',
        ExpressionAttributeNames: { '#date': 'date' },
        ExpressionAttributeValues: {
            ':doctor_id': doctor_id,
            ':date': date
        }
    }));

    
    const bookedSlots = result.Items.map(item => item.time);
    const allSlots = generateTimeSlots();
    const availableSlots = allSlots.filter(slot => !bookedSlots.includes(slot));
    
    return successResponse({
        doctor_id,
        date,
        available_slots: availableSlots,
        booked_slots: bookedSlots
    });
}

async function listAppointments(event) {
    const params = event.queryStringParameters || {};
    const { patient_id } = params;
    
    if (!patient_id) {
        return errorResponse('patient_id is required', 400);
    }
    
    const result = await docClient.send(new QueryCommand({
        TableName: APPOINTMENTS_TABLE,
        IndexName: 'PatientIndex',
        KeyConditionExpression: 'patient_id = :patient_id',
        ExpressionAttributeValues: {
            ':patient_id': patient_id
        }
    }));
    
    return successResponse({
        appointments: result.Items || []
    });
}

async function listDoctorAppointments(event) {
    const params = event.queryStringParameters || {};
    const { doctor_id } = params;
    
    if (!doctor_id) {
        return errorResponse('doctor_id is required', 400);
    }
    
    const result = await docClient.send(new QueryCommand({
        TableName: APPOINTMENTS_TABLE,
        IndexName: 'DoctorDateIndex',
        KeyConditionExpression: 'doctor_id = :doctor_id',
        ExpressionAttributeValues: {
            ':doctor_id': doctor_id
        }
    }));
    
    return successResponse({
        appointments: result.Items || []
    });
}

async function checkSlotAvailability(doctor_id, date, time) {
    const result = await docClient.send(new QueryCommand({
        TableName: APPOINTMENTS_TABLE,
        IndexName: 'DoctorDateIndex',
        KeyConditionExpression: 'doctor_id = :doctor_id AND #date = :date',
        FilterExpression: '#time = :time',
        ExpressionAttributeNames: { '#date': 'date', '#time': 'time' },
        ExpressionAttributeValues: {
            ':doctor_id': doctor_id,
            ':date': date,
            ':time': time
        }
    }));
    
    return result.Items.length === 0;
}

function generateTimeSlots() {
    const slots = [];
    for (let hour = 9; hour < 17; hour++) {
        slots.push(`${hour.toString().padStart(2, '0')}:00`);
        slots.push(`${hour.toString().padStart(2, '0')}:30`);
    }
    return slots;
}

function successResponse(data) {
    return corsResponse(200, data);
}

function errorResponse(message, statusCode) {
    return corsResponse(statusCode, { error: message });
}

function corsResponse(statusCode, body) {
    return {
        statusCode,
        headers: {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Headers': 'Content-Type,Authorization',
            'Access-Control-Allow-Methods': 'GET,POST,OPTIONS',
            'Content-Type': 'application/json'
        },
        body: JSON.stringify(body)
    };
}
