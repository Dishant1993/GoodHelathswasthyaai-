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
  Snackbar,
  MenuItem
} from '@mui/material';
import PersonIcon from '@mui/icons-material/Person';
import SaveIcon from '@mui/icons-material/Save';

const PatientProfile = () => {
  const [name, setName] = useState(localStorage.getItem('userName') || '');
  const [email, setEmail] = useState(localStorage.getItem('userEmail') || '');
  const [age, setAge] = useState(localStorage.getItem('patientAge') || '');
  const [gender, setGender] = useState(localStorage.getItem('patientGender') || '');
  const [phone, setPhone] = useState(localStorage.getItem('patientPhone') || '');
  const [weight, setWeight] = useState(localStorage.getItem('patientWeight') || '');
  const [bloodGroup, setBloodGroup] = useState(localStorage.getItem('patientBloodGroup') || '');
  const [allergies, setAllergies] = useState(localStorage.getItem('patientAllergies') || '');
  const [address, setAddress] = useState(localStorage.getItem('patientAddress') || '');
  const [city, setCity] = useState(localStorage.getItem('patientCity') || '');
  const [state, setState] = useState(localStorage.getItem('patientState') || '');
  const [zipCode, setZipCode] = useState(localStorage.getItem('patientZipCode') || '');
  const [showSuccess, setShowSuccess] = useState(false);

  const handleSave = () => {
    localStorage.setItem('userName', name);
    localStorage.setItem('userEmail', email);
    localStorage.setItem('patientAge', age);
    localStorage.setItem('patientGender', gender);
    localStorage.setItem('patientPhone', phone);
    localStorage.setItem('patientWeight', weight);
    localStorage.setItem('patientBloodGroup', bloodGroup);
    localStorage.setItem('patientAllergies', allergies);
    localStorage.setItem('patientAddress', address);
    localStorage.setItem('patientCity', city);
    localStorage.setItem('patientState', state);
    localStorage.setItem('patientZipCode', zipCode);
    setShowSuccess(true);
  };

  return (
    <Box>
      <Typography variant="h4" gutterBottom sx={{ color: 'primary.main', fontWeight: 600 }}>
        Patient Profile
      </Typography>
      <Typography variant="body1" color="text.secondary" sx={{ mb: 3 }}>
        Manage your personal information
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

          <Grid item xs={12} md={4}>
            <TextField
              fullWidth
              label="Age"
              type="number"
              value={age}
              onChange={(e) => setAge(e.target.value)}
              required
            />
          </Grid>

          <Grid item xs={12} md={4}>
            <TextField
              fullWidth
              select
              label="Gender"
              value={gender}
              onChange={(e) => setGender(e.target.value)}
            >
              <MenuItem value="male">Male</MenuItem>
              <MenuItem value="female">Female</MenuItem>
              <MenuItem value="other">Other</MenuItem>
            </TextField>
          </Grid>

          <Grid item xs={12} md={4}>
            <TextField
              fullWidth
              select
              label="Blood Group"
              value={bloodGroup}
              onChange={(e) => setBloodGroup(e.target.value)}
            >
              <MenuItem value="A+">A+</MenuItem>
              <MenuItem value="A-">A-</MenuItem>
              <MenuItem value="B+">B+</MenuItem>
              <MenuItem value="B-">B-</MenuItem>
              <MenuItem value="AB+">AB+</MenuItem>
              <MenuItem value="AB-">AB-</MenuItem>
              <MenuItem value="O+">O+</MenuItem>
              <MenuItem value="O-">O-</MenuItem>
            </TextField>
          </Grid>

          <Grid item xs={12} md={6}>
            <TextField
              fullWidth
              label="Phone Number"
              value={phone}
              onChange={(e) => setPhone(e.target.value)}
            />
          </Grid>

          <Grid item xs={12} md={6}>
            <TextField
              fullWidth
              label="Weight (kg)"
              type="number"
              value={weight}
              onChange={(e) => setWeight(e.target.value)}
              placeholder="Enter weight in kg"
            />
          </Grid>

          <Grid item xs={12}>
            <TextField
              fullWidth
              label="Allergies"
              value={allergies}
              onChange={(e) => setAllergies(e.target.value)}
              multiline
              rows={3}
              placeholder="List any allergies (e.g., Penicillin, Peanuts, Latex)"
              helperText="Please list all known allergies separated by commas"
            />
          </Grid>

          {/* Location Information */}
          <Grid item xs={12} sx={{ mt: 2 }}>
            <Typography variant="h6" sx={{ color: 'primary.main', mb: 2 }}>
              Location
            </Typography>
          </Grid>

          <Grid item xs={12}>
            <TextField
              fullWidth
              label="Address"
              value={address}
              onChange={(e) => setAddress(e.target.value)}
              multiline
              rows={2}
            />
          </Grid>

          <Grid item xs={12} md={4}>
            <TextField
              fullWidth
              label="City"
              value={city}
              onChange={(e) => setCity(e.target.value)}
            />
          </Grid>

          <Grid item xs={12} md={4}>
            <TextField
              fullWidth
              label="State"
              value={state}
              onChange={(e) => setState(e.target.value)}
            />
          </Grid>

          <Grid item xs={12} md={4}>
            <TextField
              fullWidth
              label="ZIP Code"
              value={zipCode}
              onChange={(e) => setZipCode(e.target.value)}
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

export default PatientProfile;
