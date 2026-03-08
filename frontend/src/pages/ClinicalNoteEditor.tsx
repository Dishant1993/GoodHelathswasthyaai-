import { useState } from 'react';
import { useParams } from 'react-router-dom';
import {
  Box,
  Typography,
  Paper,
  TextField,
  Button,
  CircularProgress,
  Alert,
  Card,
  CardContent,
  Divider,
} from '@mui/material';
import { clinicalAPI } from '../services/api';

interface SOAPNote {
  subjective: string;
  objective: string;
  assessment: string;
  plan: string;
}

interface GenerateResponse {
  note_id: string;
  soap_note: SOAPNote;
  confidence: number;
  requires_review: boolean;
}

const ClinicalNoteEditor = () => {
  const { noteId } = useParams<{ noteId: string }>();
  const [patientId, setPatientId] = useState('');
  const [clinicalText, setClinicalText] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [soapNote, setSoapNote] = useState<SOAPNote | null>(null);
  const [noteInfo, setNoteInfo] = useState<GenerateResponse | null>(null);

  const handleGenerate = async () => {
    if (!clinicalText || !patientId) {
      setError('Please enter both patient ID and clinical notes');
      return;
    }

    setLoading(true);
    setError('');
    setSoapNote(null);

    try {
      const data = await clinicalAPI.generateSOAP({
        patient_id: patientId,
        clinical_data: clinicalText,
        doctor_id: localStorage.getItem('userId') || 'anonymous',
      });

      if (data.soap_note) {
        setSoapNote(data.soap_note);
        setNoteInfo(data);
      } else if (data.error) {
        setError(data.error);
      }
    } catch (err) {
      console.error('Generate error:', err);
      setError('Failed to connect to server. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <Box>
      <Typography variant="h4" gutterBottom>
        {noteId ? 'Edit Clinical Note' : 'New Clinical Note'}
      </Typography>

      {error && (
        <Alert severity="error" sx={{ mb: 2 }}>
          {error}
        </Alert>
      )}

      <Paper sx={{ p: 3, mb: 3 }}>
        <TextField
          fullWidth
          label="Patient ID"
          margin="normal"
          placeholder="Enter patient ID"
          value={patientId}
          onChange={(e) => setPatientId(e.target.value)}
        />
        <TextField
          fullWidth
          label="Clinical Notes"
          margin="normal"
          multiline
          rows={10}
          placeholder="Enter clinical notes here..."
          value={clinicalText}
          onChange={(e) => setClinicalText(e.target.value)}
        />
        <Box sx={{ mt: 2, display: 'flex', gap: 2 }}>
          <Button
            variant="contained"
            color="primary"
            onClick={handleGenerate}
            disabled={loading || !clinicalText || !patientId}
            startIcon={loading ? <CircularProgress size={20} /> : null}
          >
            {loading ? 'Generating...' : 'Generate SOAP Note'}
          </Button>
        </Box>
      </Paper>

      {soapNote && (
        <Card>
          <CardContent>
            <Typography variant="h5" gutterBottom>
              Generated SOAP Note
            </Typography>
            
            {noteInfo && (
              <Alert severity={noteInfo.requires_review ? 'warning' : 'success'} sx={{ mb: 2 }}>
                Confidence: {(noteInfo.confidence * 100).toFixed(0)}%
                {noteInfo.requires_review && ' - Review recommended'}
              </Alert>
            )}

            <Box sx={{ mb: 2 }}>
              <Typography variant="h6" color="primary">
                Subjective
              </Typography>
              <Typography variant="body1" paragraph>
                {soapNote.subjective}
              </Typography>
            </Box>

            <Divider sx={{ my: 2 }} />

            <Box sx={{ mb: 2 }}>
              <Typography variant="h6" color="primary">
                Objective
              </Typography>
              <Typography variant="body1" paragraph>
                {soapNote.objective}
              </Typography>
            </Box>

            <Divider sx={{ my: 2 }} />

            <Box sx={{ mb: 2 }}>
              <Typography variant="h6" color="primary">
                Assessment
              </Typography>
              <Typography variant="body1" paragraph>
                {soapNote.assessment}
              </Typography>
            </Box>

            <Divider sx={{ my: 2 }} />

            <Box sx={{ mb: 2 }}>
              <Typography variant="h6" color="primary">
                Plan
              </Typography>
              <Typography variant="body1" paragraph>
                {soapNote.plan}
              </Typography>
            </Box>

            {noteInfo && (
              <Typography variant="caption" color="text.secondary">
                Note ID: {noteInfo.note_id}
              </Typography>
            )}
          </CardContent>
        </Card>
      )}
    </Box>
  );
};

export default ClinicalNoteEditor;
