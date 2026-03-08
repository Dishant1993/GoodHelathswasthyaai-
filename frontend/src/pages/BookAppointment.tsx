import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  Box,
  Typography,
  Paper,
  TextField,
  Button,
  Grid,
  MenuItem,
  Alert,
  Snackbar,
  Card,
  CardContent,
  Avatar,
  Chip,
  CircularProgress
} from '@mui/material';
import EventIcon from '@mui/icons-material/Event';
import PersonIcon from '@mui/icons-material/Person';
import AccessTimeIcon from '@mui/icons-material/AccessTime';
import { appointmentAPI, authAPI } from '../services/api';

interface Doctor {
  user_id: string;
  name: string;
  email: string;
  specialization?: string;
  experience?: string;
  degree?: string;
}

const BookAppointment = () => {
  const navigate = useNavigate();
  const [doctors, setDoctors] = useState<Doctor[]>([]);
  const [loadingDoctors, setLoadingDoctors] = useState(true);
  const [selectedDoctor, setSelectedDoctor] = useState('');
  const [date, setDate] = useState('');
  const [time, setTime] = useState('');
  const [reason, setReason] = useState('');
  const [loading, setLoading] = useState(false);
  const [showSuccess, setShowSuccess] = useState(false);
  const [error, setError] = useState('');

  const timeSlots = [
    '09:00', '09:30', '10:00', '10:30', '11:00', '11:30',
    '14:00', '14:30', '15:00', '15:30', '16:00', '16:30'
  ];

  useEffect(() => {
    fetchDoctors();
  }, []);

  const fetchDoctors = async () => {
    setLoadingDoctors(true);
    setError('');
    try {
      const response = await authAPI.getDoctors();
      
      console.log('Doctors API response:', response);
      
      if (response.success && response.doctors) {
        console.log('Doctors loaded:', response.doctors.length);
        setDoctors(response.doctors);
      } else {
        const errorMsg = response.error || 'Failed to load doctors';
        console.error('Doctors API error:', errorMsg);
        setError(errorMsg);
      }
    } catch (err) {
      console.error('Error fetching doctors:', err);
      setError('Failed to load doctors list. Please try again.');
    } finally {
      setLoadingDoctors(false);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setLoading(true);

    try {
      const patientId = localStorage.getItem('userId') || localStorage.getItem('userEmail') || 'patient123';
      
      const data = await appointmentAPI.book({
        patient_id: patientId,
        doctor_id: selectedDoctor,
        date: date,
        time: time,
        reason: reason
      });

      if (data.error) {
        setError(data.error);
      } else {
        setShowSuccess(true);
        setTimeout(() => {
          navigate('/');
        }, 2000);
      }
    } catch (err) {
      console.error('Booking error:', err);
      setError('Failed to connect to the server. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  const selectedDoctorInfo = doctors.find(d => d.user_id === selectedDoctor);

  if (loadingDoctors) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', minHeight: '400px' }}>
        <CircularProgress />
      </Box>
    );
  }

  return (
    <Box>
      <Typography variant="h4" gutterBottom sx={{ color: 'primary.main', fontWeight: 600 }}>
        Book Appointment
      </Typography>
      <Typography variant="body1" color="text.secondary" sx={{ mb: 3 }}>
        Schedule a consultation with our healthcare professionals
      </Typography>

      <Grid container spacing={3}>
        <Grid item xs={12} md={8}>
          <Paper sx={{ p: 4 }}>
            <Box component="form" onSubmit={handleSubmit}>
              <Grid container spacing={3}>
                <Grid item xs={12}>
                  <Typography variant="h6" sx={{ color: 'primary.main', mb: 2 }}>
                    Appointment Details
                  </Typography>
                </Grid>

                {error && (
                  <Grid item xs={12}>
                    <Alert severity="error">{error}</Alert>
                  </Grid>
                )}

                <Grid item xs={12}>
                  <TextField
                    fullWidth
                    select
                    label="Select Doctor"
                    value={selectedDoctor}
                    onChange={(e) => setSelectedDoctor(e.target.value)}
                    required
                  >
                    {doctors.map((doctor) => (
                      <MenuItem key={doctor.user_id} value={doctor.user_id}>
                        {doctor.name} - {doctor.specialization || 'General Practice'}
                      </MenuItem>
                    ))}
                  </TextField>
                </Grid>

                <Grid item xs={12} md={6}>
                  <TextField
                    fullWidth
                    type="date"
                    label="Appointment Date"
                    value={date}
                    onChange={(e) => setDate(e.target.value)}
                    InputLabelProps={{ shrink: true }}
                    inputProps={{ min: new Date().toISOString().split('T')[0] }}
                    required
                  />
                </Grid>

                <Grid item xs={12} md={6}>
                  <TextField
                    fullWidth
                    select
                    label="Appointment Time"
                    value={time}
                    onChange={(e) => setTime(e.target.value)}
                    required
                  >
                    {timeSlots.map((slot) => (
                      <MenuItem key={slot} value={slot}>
                        {slot}
                      </MenuItem>
                    ))}
                  </TextField>
                </Grid>

                <Grid item xs={12}>
                  <TextField
                    fullWidth
                    label="Reason for Visit"
                    value={reason}
                    onChange={(e) => setReason(e.target.value)}
                    multiline
                    rows={4}
                    placeholder="Please describe your symptoms or reason for consultation"
                    required
                  />
                </Grid>

                <Grid item xs={12}>
                  <Button
                    type="submit"
                    variant="contained"
                    size="large"
                    fullWidth
                    disabled={loading}
                    startIcon={<EventIcon />}
                  >
                    {loading ? 'Booking...' : 'Book Appointment'}
                  </Button>
                </Grid>
              </Grid>
            </Box>
          </Paper>
        </Grid>

        <Grid item xs={12} md={4}>
          {selectedDoctorInfo && (
            <Card>
              <CardContent>
                <Box sx={{ display: 'flex', flexDirection: 'column', alignItems: 'center', textAlign: 'center' }}>
                  <Avatar sx={{ width: 80, height: 80, bgcolor: 'primary.main', mb: 2 }}>
                    <PersonIcon sx={{ fontSize: 48 }} />
                  </Avatar>
                  <Typography variant="h6" sx={{ fontWeight: 600 }}>
                    {selectedDoctorInfo.name}
                  </Typography>
                  {selectedDoctorInfo.degree && (
                    <Typography variant="body2" color="text.secondary" sx={{ mb: 1 }}>
                      {selectedDoctorInfo.degree}
                    </Typography>
                  )}
                  <Chip
                    label={selectedDoctorInfo.specialization || 'General Practice'}
                    color="primary"
                    size="small"
                    sx={{ mt: 1, mb: 2 }}
                  />
                  {selectedDoctorInfo.experience && (
                    <Typography variant="body2" color="text.secondary">
                      Experience: {selectedDoctorInfo.experience}
                    </Typography>
                  )}
                </Box>
              </CardContent>
            </Card>
          )}

          <Card sx={{ mt: 2 }}>
            <CardContent>
              <Typography variant="h6" sx={{ color: 'primary.main', mb: 2 }}>
                Appointment Summary
              </Typography>
              {date && (
                <Box sx={{ display: 'flex', alignItems: 'center', mb: 1 }}>
                  <EventIcon sx={{ mr: 1, color: 'primary.main' }} />
                  <Typography variant="body2">
                    {new Date(date).toLocaleDateString('en-US', { 
                      weekday: 'long', 
                      year: 'numeric', 
                      month: 'long', 
                      day: 'numeric' 
                    })}
                  </Typography>
                </Box>
              )}
              {time && (
                <Box sx={{ display: 'flex', alignItems: 'center' }}>
                  <AccessTimeIcon sx={{ mr: 1, color: 'primary.main' }} />
                  <Typography variant="body2">{time}</Typography>
                </Box>
              )}
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      <Snackbar
        open={showSuccess}
        autoHideDuration={3000}
        onClose={() => setShowSuccess(false)}
        anchorOrigin={{ vertical: 'bottom', horizontal: 'center' }}
      >
        <Alert severity="success" onClose={() => setShowSuccess(false)}>
          Appointment booked successfully!
        </Alert>
      </Snackbar>
    </Box>
  );
};

export default BookAppointment;
