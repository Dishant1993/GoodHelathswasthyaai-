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
  List,
  ListItem,
  ListItemText,
  ListItemIcon,
  Divider,
  Chip,
  Avatar,
  CircularProgress,
  Alert
} from '@mui/material';
import EventIcon from '@mui/icons-material/Event';
import DescriptionIcon from '@mui/icons-material/Description';
import VerifiedUserIcon from '@mui/icons-material/VerifiedUser';
import PersonIcon from '@mui/icons-material/Person';
import CalendarTodayIcon from '@mui/icons-material/CalendarToday';
import DownloadIcon from '@mui/icons-material/Download';
import { appointmentAPI } from '../services/api';

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

const PatientDashboard = () => {
  const navigate = useNavigate();
  const patientName = localStorage.getItem('userName') || 'Patient';
  const patientId = localStorage.getItem('userId') || '';

  const [appointments, setAppointments] = useState<Appointment[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    fetchAppointments();
  }, []);

  const fetchAppointments = async () => {
    setLoading(true);
    setError('');
    try {
      const data = await appointmentAPI.getByPatient(patientId);
      if (data.error) {
        setError(data.error);
      } else {
        setAppointments(data.appointments || []);
      }
    } catch (err) {
      console.error('Error fetching appointments:', err);
      setError('Failed to load appointments');
    } finally {
      setLoading(false);
    }
  };

  const getAppointmentStatus = (appointment: Appointment) => {
    const appointmentDate = new Date(`${appointment.date}T${appointment.time}`);
    const now = new Date();
    
    if (appointment.status === 'cancelled') return 'cancelled';
    if (appointmentDate < now) return 'completed';
    return 'upcoming';
  };

  const upcomingAppointments = appointments.filter(apt => getAppointmentStatus(apt) === 'upcoming');
  const pastAppointments = appointments.filter(apt => getAppointmentStatus(apt) !== 'upcoming');

  const handleBookAppointment = () => {
    // Navigate to appointment booking
    navigate('/book-appointment');
  };

  const handleCheckInsurance = () => {
    navigate('/insurance');
  };

  const handleEditProfile = () => {
    navigate('/profile');
  };

  const handleDownloadReport = (appointmentId: string) => {
    console.log('Downloading report for appointment:', appointmentId);
    // Implement download logic
  };

  return (
    <Box>
      <Typography variant="h4" gutterBottom sx={{ color: 'primary.main', fontWeight: 600 }}>
        Patient Dashboard
      </Typography>
      <Typography variant="body1" color="text.secondary" sx={{ mb: 3 }}>
        Welcome back, {patientName}
      </Typography>

      <Grid container spacing={3}>
        {/* Profile Card */}
        <Grid item xs={12} md={4}>
          <Card sx={{ bgcolor: 'primary.main', color: 'white' }}>
            <CardContent>
              <Box sx={{ display: 'flex', flexDirection: 'column', alignItems: 'center', textAlign: 'center' }}>
                <Avatar sx={{ width: 80, height: 80, mb: 2, bgcolor: 'white', color: 'primary.main' }}>
                  <PersonIcon sx={{ fontSize: 48 }} />
                </Avatar>
                <Typography variant="h6" sx={{ fontWeight: 600 }}>
                  {patientName}
                </Typography>
                <Typography variant="body2" sx={{ mb: 2, opacity: 0.9 }}>
                  {localStorage.getItem('userEmail') || 'patient@example.com'}
                </Typography>
                <Button
                  variant="contained"
                  sx={{ bgcolor: 'white', color: 'primary.main', '&:hover': { bgcolor: 'secondary.main' } }}
                  onClick={handleEditProfile}
                  fullWidth
                >
                  Edit Profile
                </Button>
              </Box>
            </CardContent>
          </Card>
        </Grid>

        {/* Quick Actions */}
        <Grid item xs={12} md={8}>
          <Paper sx={{ p: 3 }}>
            <Typography variant="h6" sx={{ color: 'primary.main', mb: 2 }}>
              Quick Actions
            </Typography>
            <Grid container spacing={2}>
              <Grid item xs={12} sm={6}>
                <Button
                  variant="contained"
                  fullWidth
                  startIcon={<EventIcon />}
                  onClick={handleBookAppointment}
                  sx={{ py: 2 }}
                >
                  Book Appointment
                </Button>
              </Grid>
              <Grid item xs={12} sm={6}>
                <Button
                  variant="outlined"
                  fullWidth
                  startIcon={<VerifiedUserIcon />}
                  onClick={handleCheckInsurance}
                  sx={{ py: 2 }}
                >
                  Check Insurance
                </Button>
              </Grid>
            </Grid>
          </Paper>
        </Grid>

        {/* Appointments */}
        <Grid item xs={12}>
          <Paper sx={{ p: 3 }}>
            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2 }}>
              <Typography variant="h6" sx={{ color: 'primary.main' }}>
                My Appointments
              </Typography>
              <Button
                variant="text"
                startIcon={<CalendarTodayIcon />}
                onClick={handleBookAppointment}
              >
                Book New
              </Button>
            </Box>
            <Divider sx={{ mb: 2 }} />
            
            {loading ? (
              <Box sx={{ display: 'flex', justifyContent: 'center', py: 4 }}>
                <CircularProgress />
              </Box>
            ) : error ? (
              <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert>
            ) : appointments.length === 0 ? (
              <Box sx={{ textAlign: 'center', py: 4 }}>
                <Typography variant="body1" color="text.secondary">
                  No appointments found. Book your first appointment!
                </Typography>
                <Button
                  variant="contained"
                  startIcon={<EventIcon />}
                  onClick={handleBookAppointment}
                  sx={{ mt: 2 }}
                >
                  Book Appointment
                </Button>
              </Box>
            ) : (
              <>
                {upcomingAppointments.length > 0 && (
                  <>
                    <Typography variant="subtitle1" sx={{ fontWeight: 600, mb: 1, color: 'primary.main' }}>
                      Upcoming Appointments
                    </Typography>
                    <List>
                      {upcomingAppointments.map((appointment, index) => (
                        <Box key={appointment.appointment_id}>
                          <ListItem
                            sx={{
                              bgcolor: 'secondary.main',
                              borderRadius: 1,
                              mb: 1
                            }}
                          >
                            <ListItemIcon>
                              <Avatar sx={{ bgcolor: 'primary.main' }}>
                                <EventIcon />
                              </Avatar>
                            </ListItemIcon>
                            <ListItemText
                              primary={
                                <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                                  <Typography variant="subtitle1" sx={{ fontWeight: 500 }}>
                                    Doctor ID: {appointment.doctor_id}
                                  </Typography>
                                  <Chip
                                    label="upcoming"
                                    size="small"
                                    color="primary"
                                  />
                                </Box>
                              }
                              secondary={
                                <>
                                  <Typography variant="body2" component="span">
                                    {new Date(appointment.date).toLocaleDateString()} at {appointment.time}
                                  </Typography>
                                  <br />
                                  <Typography variant="body2" component="span" color="text.secondary">
                                    {appointment.reason}
                                  </Typography>
                                </>
                              }
                            />
                          </ListItem>
                          {index < upcomingAppointments.length - 1 && <Divider />}
                        </Box>
                      ))}
                    </List>
                  </>
                )}
                
                {pastAppointments.length > 0 && (
                  <>
                    <Typography variant="subtitle1" sx={{ fontWeight: 600, mb: 1, mt: 3, color: 'text.secondary' }}>
                      Past Appointments
                    </Typography>
                    <List>
                      {pastAppointments.map((appointment, index) => (
                        <Box key={appointment.appointment_id}>
                          <ListItem sx={{ borderRadius: 1, mb: 1 }}>
                            <ListItemIcon>
                              <Avatar sx={{ bgcolor: 'grey.400' }}>
                                <EventIcon />
                              </Avatar>
                            </ListItemIcon>
                            <ListItemText
                              primary={
                                <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                                  <Typography variant="subtitle1" sx={{ fontWeight: 500 }}>
                                    Doctor ID: {appointment.doctor_id}
                                  </Typography>
                                  <Chip
                                    label={getAppointmentStatus(appointment)}
                                    size="small"
                                    color="default"
                                  />
                                </Box>
                              }
                              secondary={
                                <>
                                  <Typography variant="body2" component="span">
                                    {new Date(appointment.date).toLocaleDateString()} at {appointment.time}
                                  </Typography>
                                  <br />
                                  <Typography variant="body2" component="span" color="text.secondary">
                                    {appointment.reason}
                                  </Typography>
                                </>
                              }
                            />
                            <Button
                              variant="outlined"
                              size="small"
                              startIcon={<DownloadIcon />}
                              onClick={() => handleDownloadReport(appointment.appointment_id)}
                            >
                              Download Report
                            </Button>
                          </ListItem>
                          {index < pastAppointments.length - 1 && <Divider />}
                        </Box>
                      ))}
                    </List>
                  </>
                )}
              </>
            )}
          </Paper>
        </Grid>

        {/* Insurance Section */}
        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                <VerifiedUserIcon sx={{ fontSize: 40, color: 'primary.main', mr: 2 }} />
                <Box>
                  <Typography variant="h6" sx={{ color: 'primary.main' }}>
                    Insurance Eligibility
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    Check if your procedure is covered
                  </Typography>
                </Box>
              </Box>
              <Button
                variant="contained"
                fullWidth
                onClick={handleCheckInsurance}
              >
                Check Coverage
              </Button>
            </CardContent>
          </Card>
        </Grid>

        {/* Consultation Reports */}
        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                <DescriptionIcon sx={{ fontSize: 40, color: 'primary.main', mr: 2 }} />
                <Box>
                  <Typography variant="h6" sx={{ color: 'primary.main' }}>
                    Consultation Reports
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    View and download your reports
                  </Typography>
                </Box>
              </Box>
              <Button
                variant="outlined"
                fullWidth
              >
                View All Reports
              </Button>
            </CardContent>
          </Card>
        </Grid>
      </Grid>
    </Box>
  );
};

export default PatientDashboard;
