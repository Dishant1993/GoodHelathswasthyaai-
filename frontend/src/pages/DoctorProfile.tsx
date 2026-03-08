import { useState } from 'react';
import {
  Box,
  Typography,
  Paper,
  TextField,
  Button,
  Grid,
  Avatar,
  Alert,
  Snackbar
} from '@mui/material';
import PersonIcon from '@mui/icons-material/Person';
import SaveIcon from '@mui/icons-material/Save';

const DoctorProfile = () => {
  const [name, setName] = useState(localStorage.getItem('userName') || '');
  const [email, setEmail] = useState(localStorage.getItem('userEmail') || '');
  const [degree, setDegree] = useState(localStorage.getItem('doctorDegree') || '');
  const [experience, setExperience] = useState(localStorage.getItem('doctorExperience') || '');
  const [specialization, setSpecialization] = useState(localStorage.getItem('doctorSpecialization') || '');
  const [phone, setPhone] = useState(localStorage.getItem('doctorPhone') || '');
  const [showSuccess, setShowSuccess] = useState(false);

  const handleSave = () => {
    localStorage.setItem('userName', name);
    localStorage.setItem('userEmail', email);
    localStorage.setItem('doctorDegree', degree);
    localStorage.setItem('doctorExperience', experience);
    localStorage.setItem('doctorSpecialization', specialization);
    localStorage.setItem('doctorPhone', phone);
    setShowSuccess(true);
  };

  return (
    <Box>
      <Typography variant="h4" gutterBottom sx={{ color: 'primary.main', fontWeight: 600 }}>
        Doctor Profile
      </Typography>
      <Typography variant="body1" color="text.secondary" sx={{ mb: 3 }}>
        Manage your professional information
      </Typography>

      <Paper sx={{ p: 4 }}>
        <Grid container spacing={3}>
          {/* Profile Picture Section */}
          <Grid item xs={12} sx={{ display: 'flex', justifyContent: 'center', mb: 2 }}>
            <Avatar
              sx={{
                width: 120,
                height: 120,
                bgcolor: 'primary.main',
                fontSize: 48
              }}
            >
              <PersonIcon sx={{ fontSize: 64 }} />
            </Avatar>
          </Grid>

          {/* Personal Information */}
          <Grid item xs={12}>
            <Typography variant="h6" sx={{ color: 'primary.main', mb: 2 }}>
              Personal Information
            </Typography>
          </Grid>

          <Grid item xs={12} md={6}>
            <TextField
              fullWidth
              label="Full Name"
              value={name}
              onChange={(e) => setName(e.target.value)}
              required
            />
          </Grid>

          <Grid item xs={12} md={6}>
            <TextField
              fullWidth
              label="Email Address"
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
            />
          </Grid>

          <Grid item xs={12} md={6}>
            <TextField
              fullWidth
              label="Phone Number"
              value={phone}
              onChange={(e) => setPhone(e.target.value)}
            />
          </Grid>

          {/* Professional Information */}
          <Grid item xs={12} sx={{ mt: 2 }}>
            <Typography variant="h6" sx={{ color: 'primary.main', mb: 2 }}>
              Professional Information
            </Typography>
          </Grid>

          <Grid item xs={12} md={6}>
            <TextField
              fullWidth
              label="Medical Degree"
              value={degree}
              onChange={(e) => setDegree(e.target.value)}
              placeholder="e.g., MBBS, MD"
              required
            />
          </Grid>

          <Grid item xs={12} md={6}>
            <TextField
              fullWidth
              label="Years of Experience"
              type="number"
              value={experience}
              onChange={(e) => setExperience(e.target.value)}
              required
            />
          </Grid>

          <Grid item xs={12}>
            <TextField
              fullWidth
              label="Specialization"
              value={specialization}
              onChange={(e) => setSpecialization(e.target.value)}
              placeholder="e.g., Cardiology, Pediatrics"
            />
          </Grid>

          {/* Save Button */}
          <Grid item xs={12} sx={{ mt: 2 }}>
            <Button
              variant="contained"
              size="large"
              startIcon={<SaveIcon />}
              onClick={handleSave}
            >
              Save Profile
            </Button>
          </Grid>
        </Grid>
      </Paper>

      <Snackbar
        open={showSuccess}
        autoHideDuration={3000}
        onClose={() => setShowSuccess(false)}
        anchorOrigin={{ vertical: 'bottom', horizontal: 'center' }}
      >
        <Alert severity="success" onClose={() => setShowSuccess(false)}>
          Profile updated successfully!
        </Alert>
      </Snackbar>
    </Box>
  );
};

export default DoctorProfile;
