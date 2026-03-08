import { useState, useEffect } from 'react';
import {
  Box,
  Typography,
  Paper,
  Grid,
  Card,
  CardContent,
  CircularProgress,
  Alert,
  Chip,
  Divider,
  List,
  ListItem,
  ListItemText,
  ListItemButton,
  Avatar,
  IconButton
} from '@mui/material';
import PersonIcon from '@mui/icons-material/Person';
import ArrowBackIcon from '@mui/icons-material/ArrowBack';
import EventIcon from '@mui/icons-material/Event';
import { appointmentAPI, authAPI } from '../services/api';

interface Patient {
  user_id: string;
  name: string;
  email: string;
  age?: string;
  gender?: string;
  phone?: string;
  weight?: string;
  allergies?: string;
}

interface Appointment {
  appointment_id: string;
  patient_id: string;
  doctor_id: string;
  date: string;
  time: string;
  reason: string;
  status: string;
  created_at: string;
}

const PatientRecord = () => {
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [patients, setPatients] = useState<Patient[]>([]);
  const [selectedPatient, setSelectedPatient] = useState<Patient | null>(null);
  const [patientAppointments, setPatientAppointments] = useState<Appointment[]>([]);
  const [loadingAppointments, setLoadingAppointments] = useState(false);

  useEffect(() => {
    fetchPatients();
  }, []);

  const fetchPatients = async () => {
    setLoading(true);
    setError('');
    
    try {
      const response = await authAPI.getPatients();
      
      if (response.success && response.patients) {
        setPatients(response.patients);
      } else {
        setError(response.error || 'Failed to load patients');
      }
    } catch (err) {
      console.error('Error fetching patients:', err);
      setError('Failed to load patients');
    } finally {
      setLoading(false);
    }
  };

  const fetchPatientAppointments = async (patientId: string) => {
    setLoadingAppointments(true);
    try {
      const data = await appointmentAPI.getByPatient(patientId);
      if (data.error) {
        console.error('Error fetching appointments:', data.error);
        setPatientAppointments([]);
      } else {
        setPatientAppointments(data.appointments || []);
      }
    } catch (err) {
      console.error('Error fetching appointments:', err);
      setPatientAppointments([]);
    } finally {
      setLoadingAppointments(false);
    }
  };

  const handlePatientClick = async (patient: Patient) => {
    setSelectedPatient(patient);
    await fetchPatientAppointments(patient.user_id);
  };

  const handleBackToList = () => {
    setSelectedPatient(null);
    setPatientAppointments([]);
  };

  const getLastAppointment = () => {
    if (patientAppointments.length === 0) return null;
    
    // Sort by date and get the most recent
    const sorted = [...patientAppointments].sort((a, b) => {
      const dateA = new Date(`${a.date}T${a.time}`);
      const dateB = new Date(`${b.date}T${b.time}`);
      return dateB.getTime() - dateA.getTime();
    });
    
    return sorted[0];
  };

  if (loading) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', minHeight: '400px' }}>
        <CircularProgress />
      </Box>
    );
  }

  if (error) {
    return (
      <Alert severity="error" sx={{ mb: 3 }}>
        {error}
      </Alert>
    );
  }

  // Patient List View
  if (!selectedPatient) {
    return (
      <Box>
        <Typography variant="h4" gutterBottom sx={{ color: 'primary.main', fontWeight: 600 }}>
          Patient History
        </Typography>
        <Typography variant="body2" color="text.secondary" sx={{ mb: 3 }}>
          Select a patient to view their complete medical history
        </Typography>

        <Paper sx={{ p: 2 }}>
          <Typography variant="h6" sx={{ color: 'primary.main', mb: 2, px: 2, pt: 1 }}>
            Patient List ({patients.length})
          </Typography>
          <Divider sx={{ mb: 2 }} />
          
          {patients.length === 0 ? (
            <Alert severity="info">No patients found.</Alert>
          ) : (
            <List>
              {patients.map((patient, index) => (
                <Box key={patient.user_id}>
                  <ListItemButton onClick={() => handlePatientClick(patient)}>
                    <Avatar sx={{ bgcolor: 'primary.main', mr: 2 }}>
                      <PersonIcon />
                    </Avatar>
                    <ListItemText
                      primary={
                        <Typography variant="subtitle1" sx={{ fontWeight: 500 }}>
                          {patient.name}
                        </Typography>
                      }
                      secondary={
                        <>
                          <Typography variant="body2" component="span">
                            {patient.email}
                          </Typography>
                          {patient.age && (
                            <>
                              <br />
                              <Typography variant="body2" component="span" color="text.secondary">
                                Age: {patient.age} • Gender: {patient.gender || 'N/A'}
                              </Typography>
                            </>
                          )}
                        </>
                      }
                    />
                  </ListItemButton>
                  {index < patients.length - 1 && <Divider />}
                </Box>
              ))}
            </List>
          )}
        </Paper>
      </Box>
    );
  }

  // Patient Detail View
  const lastAppointment = getLastAppointment();

  return (
    <Box>
      <Box sx={{ display: 'flex', alignItems: 'center', mb: 3 }}>
        <IconButton onClick={handleBackToList} sx={{ mr: 2 }}>
          <ArrowBackIcon />
        </IconButton>
        <Box>
          <Typography variant="h4" sx={{ color: 'primary.main', fontWeight: 600 }}>
            {selectedPatient.name}
          </Typography>
          <Typography variant="body2" color="text.secondary">
            Patient ID: {selectedPatient.user_id}
          </Typography>
        </Box>
      </Box>

      {/* Patient Information Cards */}
      <Grid container spacing={3}>
        {/* Personal Information */}
        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Typography variant="h6" sx={{ color: 'primary.main', mb: 2 }}>
                Personal Information
              </Typography>
              <Grid container spacing={2}>
                <Grid item xs={6}>
                  <Typography variant="body2" color="text.secondary">
                    Name
                  </Typography>
                  <Typography variant="body1" sx={{ fontWeight: 500 }}>
                    {selectedPatient.name}
                  </Typography>
                </Grid>
                <Grid item xs={6}>
                  <Typography variant="body2" color="text.secondary">
                    Age
                  </Typography>
                  <Typography variant="body1" sx={{ fontWeight: 500 }}>
                    {selectedPatient.age || 'N/A'}
                  </Typography>
                </Grid>
                <Grid item xs={6}>
                  <Typography variant="body2" color="text.secondary">
                    Gender
                  </Typography>
                  <Typography variant="body1" sx={{ fontWeight: 500 }}>
                    {selectedPatient.gender || 'N/A'}
                  </Typography>
                </Grid>
                <Grid item xs={6}>
                  <Typography variant="body2" color="text.secondary">
                    Weight
                  </Typography>
                  <Typography variant="body1" sx={{ fontWeight: 500 }}>
                    {selectedPatient.weight ? `${selectedPatient.weight} kg` : 'N/A'}
                  </Typography>
                </Grid>
                <Grid item xs={12}>
                  <Typography variant="body2" color="text.secondary">
                    Email
                  </Typography>
                  <Typography variant="body1" sx={{ fontWeight: 500 }}>
                    {selectedPatient.email}
                  </Typography>
                </Grid>
                <Grid item xs={12}>
                  <Typography variant="body2" color="text.secondary">
                    Phone
                  </Typography>
                  <Typography variant="body1" sx={{ fontWeight: 500 }}>
                    {selectedPatient.phone || 'N/A'}
                  </Typography>
                </Grid>
              </Grid>
            </CardContent>
          </Card>
        </Grid>

        {/* Medical Information */}
        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Typography variant="h6" sx={{ color: 'primary.main', mb: 2 }}>
                Medical Information
              </Typography>
              <Box sx={{ mb: 3 }}>
                <Typography variant="body2" color="text.secondary" gutterBottom>
                  Allergies
                </Typography>
                <Typography variant="body1" sx={{ fontWeight: 500 }}>
                  {selectedPatient.allergies || 'None reported'}
                </Typography>
              </Box>
              
              {lastAppointment && (
                <Box>
                  <Typography variant="body2" color="text.secondary" gutterBottom>
                    Last Appointment
                  </Typography>
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 1 }}>
                    <EventIcon sx={{ fontSize: 20, color: 'primary.main' }} />
                    <Typography variant="body1" sx={{ fontWeight: 500 }}>
                      {new Date(lastAppointment.date).toLocaleDateString()}
                    </Typography>
                  </Box>
                  <Typography variant="body2" color="text.secondary">
                    Reason: {lastAppointment.reason}
                  </Typography>
                </Box>
              )}
            </CardContent>
          </Card>
        </Grid>

        {/* Appointments History */}
        <Grid item xs={12}>
          <Card>
            <CardContent>
              <Typography variant="h6" sx={{ color: 'primary.main', mb: 2 }}>
                Appointment History
              </Typography>
              
              {loadingAppointments ? (
                <Box sx={{ display: 'flex', justifyContent: 'center', py: 3 }}>
                  <CircularProgress />
                </Box>
              ) : patientAppointments.length === 0 ? (
                <Alert severity="info">No appointments found for this patient.</Alert>
              ) : (
                <List>
                  {patientAppointments.map((appointment, index) => (
                    <Box key={appointment.appointment_id}>
                      <ListItem>
                        <ListItemText
                          primary={
                            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                              <Typography variant="subtitle1" sx={{ fontWeight: 500 }}>
                                {new Date(appointment.date).toLocaleDateString()} at {appointment.time}
                              </Typography>
                              <Chip 
                                label={appointment.status || 'Completed'} 
                                size="small" 
                                color="primary"
                              />
                            </Box>
                          }
                          secondary={
                            <>
                              <Typography variant="body2" component="span">
                                Reason: {appointment.reason}
                              </Typography>
                              <br />
                              <Typography variant="body2" component="span" color="text.secondary">
                                Doctor ID: {appointment.doctor_id}
                              </Typography>
                            </>
                          }
                        />
                      </ListItem>
                      {index < patientAppointments.length - 1 && <Divider />}
                    </Box>
                  ))}
                </List>
              )}
            </CardContent>
          </Card>
        </Grid>

        {/* Consultation Reports & Prescriptions */}
        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Typography variant="h6" sx={{ color: 'primary.main', mb: 2 }}>
                Consultation Reports
              </Typography>
              <Alert severity="info">
                No consultation reports available yet. Reports will appear here after consultations.
              </Alert>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Typography variant="h6" sx={{ color: 'primary.main', mb: 2 }}>
                Prescriptions
              </Typography>
              <Alert severity="info">
                No prescriptions available yet. Prescriptions will appear here after consultations.
              </Alert>
            </CardContent>
          </Card>
        </Grid>
      </Grid>
    </Box>
  );
};

export default PatientRecord;
