import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  Box,
  Typography,
  Grid,
  Paper,
  Card,
  CardContent,
  Button,
  Chip,
  Avatar,
  List,
  ListItem,
  ListItemText,
  ListItemAvatar,
  Divider,
  IconButton,
  Tooltip,
  CircularProgress,
  Alert
} from '@mui/material';
import PersonIcon from '@mui/icons-material/Person';
import EventIcon from '@mui/icons-material/Event';
import HistoryIcon from '@mui/icons-material/History';
import NoteAddIcon from '@mui/icons-material/NoteAdd';
import FiberNewIcon from '@mui/icons-material/FiberNew';
import VisibilityIcon from '@mui/icons-material/Visibility';
import { appointmentAPI, authAPI } from '../services/api';

interface Appointment {
  appointment_id: string;
  patient_id: string;
  patient_name: string;
  doctor_id: string;
  doctor_name: string;
  date: string;
  time: string;
  reason: string;
  status: string;
}

const DoctorDashboard = () => {
  const navigate = useNavigate();
  const doctorName = localStorage.getItem('userName') || 'Dr. Smith';
  const doctorId = localStorage.getItem('userId') || '';

  const [appointments, setAppointments] = useState<Appointment[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const fetchAppointments = async () => {
      try {
        setLoading(true);
        setError(null);
        
        console.log('Fetching appointments for doctor:', doctorId);
        const response = await appointmentAPI.getByDoctor(doctorId);
        console.log('Appointments API response:', response);
        
        if (response.appointments) {
          console.log('Total appointments:', response.appointments.length);
          
          // Fetch all patients to get their names
          const patientsResponse = await authAPI.getPatients();
          const patients = patientsResponse.patients || [];
          
          // Create a map of patient_id to patient_name
          const patientMap = new Map(
            patients.map((p: any) => [p.patient_id || p.user_id, p.name])
          );
          
          // Enrich appointments with patient names
          const enrichedAppointments = response.appointments.map((apt: any) => ({
            ...apt,
            patient_name: patientMap.get(apt.patient_id) || 'Unknown Patient',
            doctor_name: doctorName
          }));
          
          // Filter for upcoming appointments only (today or future)
          const today = new Date();
          today.setHours(0, 0, 0, 0);
          
          const upcomingAppointments = enrichedAppointments.filter((apt: Appointment) => {
            const aptDate = new Date(apt.date);
            console.log('Appointment date:', apt.date, 'Parsed:', aptDate, 'Today:', today, 'Is upcoming:', aptDate >= today);
            return aptDate >= today;
          });
          
          console.log('Upcoming appointments:', upcomingAppointments.length);
          setAppointments(upcomingAppointments);
        } else if (response.error) {
          console.error('API error:', response.error);
          setError(response.error || 'Failed to fetch appointments');
        } else {
          console.error('Unexpected response format:', response);
          setError('Failed to fetch appointments');
        }
      } catch (err) {
        console.error('Error fetching appointments:', err);
        setError('Failed to load appointments. Please try again.');
      } finally {
        setLoading(false);
      }
    };

    if (doctorId) {
      fetchAppointments();
    } else {
      console.error('No doctor ID found in localStorage');
      setError('Doctor ID not found. Please log in again.');
      setLoading(false);
    }
  }, [doctorId, doctorName]);

  const handleViewPatientHistory = (patientId: string) => {
    navigate(`/patient/${patientId}`);
  };

  const handleCreateNote = () => {
    navigate('/note/new');
  };

  return (
    <Box>
      <Typography variant="h4" gutterBottom sx={{ color: 'primary.main', fontWeight: 600 }}>
        Doctor Dashboard
      </Typography>
      <Typography variant="body1" color="text.secondary" sx={{ mb: 3 }}>
        Welcome back, {doctorName}
      </Typography>

      <Grid container spacing={3}>
        {/* Stats Cards */}
        <Grid item xs={12} md={4}>
          <Card sx={{ bgcolor: 'primary.main', color: 'white' }}>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                <Box>
                  <Typography variant="h3" sx={{ fontWeight: 600 }}>
                    {loading ? '-' : appointments.length}
                  </Typography>
                  <Typography variant="body2">
                    Upcoming Appointments
                  </Typography>
                </Box>
                <EventIcon sx={{ fontSize: 48, opacity: 0.8 }} />
              </Box>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} md={4}>
          <Card sx={{ bgcolor: 'secondary.main' }}>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                <Box>
                  <Typography variant="h3" sx={{ fontWeight: 600, color: 'primary.main' }}>
                    {loading ? '-' : appointments.filter(a => {
                      const today = new Date().toISOString().split('T')[0];
                      return a.date === today;
                    }).length}
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    Scheduled Today
                  </Typography>
                </Box>
                <FiberNewIcon sx={{ fontSize: 48, opacity: 0.6, color: 'primary.main' }} />
              </Box>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} md={4}>
          <Card>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                <Box>
                  <Typography variant="h3" sx={{ fontWeight: 600, color: 'primary.main' }}>
                    {loading ? '-' : appointments.filter(a => a.status === 'completed').length}
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    Completed
                  </Typography>
                </Box>
                <HistoryIcon sx={{ fontSize: 48, opacity: 0.6, color: 'primary.main' }} />
              </Box>
            </CardContent>
          </Card>
        </Grid>

        {/* Appointments List */}
        <Grid item xs={12}>
          <Paper sx={{ p: 3 }}>
            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2 }}>
              <Typography variant="h6" sx={{ color: 'primary.main' }}>
                Upcoming Appointments
              </Typography>
              <Button
                variant="contained"
                startIcon={<NoteAddIcon />}
                onClick={handleCreateNote}
              >
                Create Clinical Note
              </Button>
            </Box>
            <Divider sx={{ mb: 2 }} />
            
            {loading ? (
              <Box sx={{ display: 'flex', justifyContent: 'center', py: 4 }}>
                <CircularProgress />
              </Box>
            ) : error ? (
              <Alert severity="error" sx={{ mb: 2 }}>
                {error}
              </Alert>
            ) : appointments.length === 0 ? (
              <Box sx={{ textAlign: 'center', py: 4 }}>
                <Typography variant="body1" color="text.secondary">
                  No upcoming appointments
                </Typography>
              </Box>
            ) : (
              <List>
                {appointments.map((appointment, index) => (
                  <Box key={appointment.appointment_id}>
                    <ListItem
                      secondaryAction={
                        <Box>
                          <Tooltip title="View Patient History">
                            <IconButton
                              edge="end"
                              onClick={() => handleViewPatientHistory(appointment.patient_id)}
                            >
                              <VisibilityIcon />
                            </IconButton>
                          </Tooltip>
                        </Box>
                      }
                    >
                      <ListItemAvatar>
                        <Avatar sx={{ bgcolor: 'primary.main' }}>
                          <PersonIcon />
                        </Avatar>
                      </ListItemAvatar>
                      <ListItemText
                        primary={
                          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                            <Typography variant="subtitle1" sx={{ fontWeight: 500 }}>
                              {appointment.patient_name}
                            </Typography>
                            <Chip
                              label={appointment.status}
                              size="small"
                              color={appointment.status === 'confirmed' ? 'primary' : 'default'}
                            />
                          </Box>
                        }
                        secondary={
                          <>
                            <Typography variant="body2" component="span">
                              {appointment.date} • {appointment.time} • {appointment.reason}
                            </Typography>
                          </>
                        }
                      />
                    </ListItem>
                    {index < appointments.length - 1 && <Divider variant="inset" component="li" />}
                  </Box>
                ))}
              </List>
            )}
          </Paper>
        </Grid>
      </Grid>
    </Box>
  );
};

export default DoctorDashboard;
