/**
 * SwasthyaAI - History Manager Lambda Function
 * Manages patient timeline and generates snapshots
 */

const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, GetCommand, PutCommand, QueryCommand, UpdateCommand } = require('@aws-sdk/lib-dynamodb');
const { ElastiCacheClient, DescribeCacheClustersCommand } = require('@aws-sdk/client-elasticache');
const Redis = require('ioredis');

// Initialize AWS clients
const ddbClient = new DynamoDBClient({ region: process.env.AWS_REGION });
const docClient = DynamoDBDocumentClient.from(ddbClient);

// Environment variables
const TIMELINE_TABLE = process.env.TIMELINE_TABLE;
const PATIENTS_TABLE = process.env.PATIENTS_TABLE;
const CLINICAL_NOTES_TABLE = process.env.CLINICAL_NOTES_TABLE;
const REDIS_ENDPOINT = process.env.REDIS_ENDPOINT;
const CACHE_TTL = 3600; // 1 hour

// Redis client (lazy initialization)
let redisClient = null;

/**
 * Main Lambda handler
 */
exports.handler = async (event) => {
    console.log('Received event:', JSON.stringify(event));
    
    try {
        const body = event.body ? JSON.parse(event.body) : event;
        const action = body.action || event.httpMethod;
        
        let result;
        
        switch (action) {
            case 'GET':
            case 'getTimeline':
                result = await getPatientTimeline(body.patient_id, body.filters);
                break;
                
            case 'POST':
            case 'addEvent':
                result = await addTimelineEvent(body);
                break;
                
            case 'getSnapshot':
                result = await getPatientSnapshot(body.patient_id);
                break;
                
            case 'generateSnapshot':
                result = await generatePatientSnapshot(body.patient_id);
                break;
                
            default:
                throw new Error(`Unsupported action: ${action}`);
        }
        
        return {
            statusCode: 200,
            headers: {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            body: JSON.stringify(result)
        };
        
    } catch (error) {
        console.error('Error:', error);
        return {
            statusCode: 500,
            headers: {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            body: JSON.stringify({
                error: error.message
            })
        };
    }
};

/**
 * Get patient timeline with optional filters
 */
async function getPatientTimeline(patientId, filters = {}) {
    try {
        const params = {
            TableName: TIMELINE_TABLE,
            KeyConditionExpression: 'patient_id = :pid',
            ExpressionAttributeValues: {
                ':pid': patientId
            },
            ScanIndexForward: false, // Most recent first
            Limit: filters.limit || 50
        };
        
        // Add date range filter if provided
        if (filters.startDate && filters.endDate) {
            params.KeyConditionExpression += ' AND event_timestamp BETWEEN :start AND :end';
            params.ExpressionAttributeValues[':start'] = filters.startDate;
            params.ExpressionAttributeValues[':end'] = filters.endDate;
        }
        
        // Add event type filter if provided
        if (filters.eventType) {
            params.FilterExpression = 'event_type = :type';
            params.ExpressionAttributeValues[':type'] = filters.eventType;
        }
        
        const command = new QueryCommand(params);
        const response = await docClient.send(command);
        
        return {
            events: response.Items || [],
            count: response.Count,
            lastEvaluatedKey: response.LastEvaluatedKey
        };
        
    } catch (error) {
        console.error('Error getting timeline:', error);
        throw error;
    }
}

/**
 * Add new timeline event
 */
async function addTimelineEvent(eventData) {
    try {
        const event = {
            patient_id: eventData.patient_id,
            event_timestamp: eventData.event_timestamp || new Date().toISOString(),
            event_id: `evt-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`,
            event_type: eventData.event_type,
            event_data: eventData.event_data,
            source: eventData.source || 'manual_entry',
            created_by: eventData.created_by,
            created_at: new Date().toISOString()
        };
        
        const params = {
            TableName: TIMELINE_TABLE,
            Item: event
        };
        
        const command = new PutCommand(params);
        await docClient.send(command);
        
        // Invalidate cache for this patient
        await invalidateCache(eventData.patient_id);
        
        // Trigger snapshot regeneration (async)
        await generatePatientSnapshot(eventData.patient_id);
        
        return {
            success: true,
            event_id: event.event_id,
            message: 'Timeline event added successfully'
        };
        
    } catch (error) {
        console.error('Error adding timeline event:', error);
        throw error;
    }
}

/**
 * Get patient snapshot (with caching)
 */
async function getPatientSnapshot(patientId) {
    try {
        // Try to get from cache first
        const cachedSnapshot = await getFromCache(`snapshot:${patientId}`);
        if (cachedSnapshot) {
            console.log('Returning cached snapshot');
            return JSON.parse(cachedSnapshot);
        }
        
        // Generate new snapshot if not in cache
        console.log('Cache miss, generating new snapshot');
        const snapshot = await generatePatientSnapshot(patientId);
        
        // Cache the snapshot
        await setCache(`snapshot:${patientId}`, JSON.stringify(snapshot), CACHE_TTL);
        
        return snapshot;
        
    } catch (error) {
        console.error('Error getting snapshot:', error);
        throw error;
    }
}

/**
 * Generate patient snapshot from timeline and clinical notes
 */
async function generatePatientSnapshot(patientId) {
    try {
        const sixMonthsAgo = new Date();
        sixMonthsAgo.setMonth(sixMonthsAgo.getMonth() - 6);
        
        // Get recent timeline events
        const timeline = await getPatientTimeline(patientId, {
            startDate: sixMonthsAgo.toISOString(),
            limit: 100
        });
        
        // Get recent clinical notes
        const notesParams = {
            TableName: CLINICAL_NOTES_TABLE,
            KeyConditionExpression: 'patient_id = :pid',
            ExpressionAttributeValues: {
                ':pid': patientId
            },
            ScanIndexForward: false,
            Limit: 10
        };
        
        const notesCommand = new QueryCommand(notesParams);
        const notesResponse = await docClient.send(notesCommand);
        const clinicalNotes = notesResponse.Items || [];
        
        // Aggregate data
        const snapshot = {
            patient_id: patientId,
            generated_at: new Date().toISOString(),
            active_diagnoses: extractActiveDiagnoses(timeline.events, clinicalNotes),
            current_medications: extractCurrentMedications(timeline.events, clinicalNotes),
            allergies: extractAllergies(timeline.events),
            recent_vitals: extractRecentVitals(timeline.events),
            recent_visits: extractRecentVisits(timeline.events),
            upcoming_appointments: [], // Placeholder
            flags: generateFlags(timeline.events, clinicalNotes)
        };
        
        return snapshot;
        
    } catch (error) {
        console.error('Error generating snapshot:', error);
        throw error;
    }
}

/**
 * Extract active diagnoses from timeline and notes
 */
function extractActiveDiagnoses(events, notes) {
    const diagnoses = new Map();
    
    // Extract from timeline events
    events.filter(e => e.event_type === 'diagnosis').forEach(event => {
        const data = event.event_data;
        if (data.condition && data.status !== 'resolved') {
            diagnoses.set(data.condition, {
                condition: data.condition,
                icd10: data.icd10 || '',
                diagnosed_date: event.event_timestamp,
                status: data.status || 'active'
            });
        }
    });
    
    // Extract from clinical notes
    notes.forEach(note => {
        const entities = note.entities || [];
        entities.filter(e => e.type === 'MEDICAL_CONDITION').forEach(entity => {
            if (!diagnoses.has(entity.text)) {
                diagnoses.set(entity.text, {
                    condition: entity.text,
                    icd10: '',
                    diagnosed_date: note.created_at,
                    status: 'active'
                });
            }
        });
    });
    
    return Array.from(diagnoses.values()).slice(0, 10);
}

/**
 * Extract current medications
 */
function extractCurrentMedications(events, notes) {
    const medications = new Map();
    
    // Extract from timeline events
    events.filter(e => e.event_type === 'medication').forEach(event => {
        const data = event.event_data;
        if (data.medication && !data.stopped_date) {
            medications.set(data.medication, {
                medication: data.medication,
                dosage: data.dosage || '',
                started_date: event.event_timestamp,
                prescriber: data.prescriber || ''
            });
        }
    });
    
    // Extract from recent clinical notes
    const latestNote = notes[0];
    if (latestNote && latestNote.entities) {
        latestNote.entities.filter(e => e.type === 'MEDICATION').forEach(entity => {
            if (!medications.has(entity.text)) {
                medications.set(entity.text, {
                    medication: entity.text,
                    dosage: '',
                    started_date: latestNote.created_at,
                    prescriber: latestNote.created_by
                });
            }
        });
    }
    
    return Array.from(medications.values()).slice(0, 15);
}

/**
 * Extract allergies
 */
function extractAllergies(events) {
    const allergies = [];
    
    events.filter(e => e.event_type === 'allergy').forEach(event => {
        const data = event.event_data;
        allergies.push({
            allergen: data.allergen,
            reaction: data.reaction || '',
            severity: data.severity || 'unknown'
        });
    });
    
    return allergies;
}

/**
 * Extract recent vitals
 */
function extractRecentVitals(events) {
    const vitalEvents = events.filter(e => e.event_type === 'vitals');
    
    if (vitalEvents.length === 0) {
        return null;
    }
    
    const latestVitals = vitalEvents[0].event_data;
    return {
        ...latestVitals,
        recorded_at: vitalEvents[0].event_timestamp
    };
}

/**
 * Extract recent visits
 */
function extractRecentVisits(events) {
    return events
        .filter(e => e.event_type === 'consultation' || e.event_type === 'admission')
        .slice(0, 5)
        .map(event => ({
            date: event.event_timestamp.split('T')[0],
            type: event.event_type,
            provider: event.event_data.provider || '',
            chief_complaint: event.event_data.chief_complaint || ''
        }));
}

/**
 * Generate flags for critical information
 */
function generateFlags(events, notes) {
    const flags = [];
    
    // Check for allergies
    const allergies = extractAllergies(events);
    if (allergies.length > 0) {
        allergies.forEach(allergy => {
            if (allergy.severity === 'high' || allergy.severity === 'severe') {
                flags.push({
                    type: 'allergy',
                    message: `Severe allergy: ${allergy.allergen}`,
                    severity: 'high'
                });
            }
        });
    }
    
    // Check for chronic conditions
    const diagnoses = extractActiveDiagnoses(events, notes);
    const chronicConditions = ['diabetes', 'hypertension', 'asthma', 'copd'];
    diagnoses.forEach(diagnosis => {
        if (chronicConditions.some(cc => diagnosis.condition.toLowerCase().includes(cc))) {
            flags.push({
                type: 'chronic_condition',
                message: `Chronic condition: ${diagnosis.condition}`,
                severity: 'medium'
            });
        }
    });
    
    return flags;
}

/**
 * Redis cache operations
 */
async function getRedisClient() {
    if (!redisClient && REDIS_ENDPOINT) {
        redisClient = new Redis({
            host: REDIS_ENDPOINT.split(':')[0],
            port: parseInt(REDIS_ENDPOINT.split(':')[1] || '6379'),
            retryStrategy: (times) => {
                if (times > 3) return null;
                return Math.min(times * 50, 2000);
            }
        });
    }
    return redisClient;
}

async function getFromCache(key) {
    try {
        const client = await getRedisClient();
        if (!client) return null;
        return await client.get(key);
    } catch (error) {
        console.error('Cache get error:', error);
        return null;
    }
}

async function setCache(key, value, ttl) {
    try {
        const client = await getRedisClient();
        if (!client) return;
        await client.setex(key, ttl, value);
    } catch (error) {
        console.error('Cache set error:', error);
    }
}

async function invalidateCache(patientId) {
    try {
        const client = await getRedisClient();
        if (!client) return;
        await client.del(`snapshot:${patientId}`);
    } catch (error) {
        console.error('Cache invalidation error:', error);
    }
}
