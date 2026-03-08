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
  ListItemText,
  ListItemButton,
  Avatar,
  IconButton,
  Button,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableRow
} from '@mui/material';
import PersonIcon from '@mui/icons-material/Person';
import ArrowBackIcon from '@mui/icons-material/ArrowBack';
import DescriptionIcon from '@mui/icons-material/Description';
import DownloadIcon from '@mui/icons-material/Download';
import VisibilityIcon from '@mui/icons-material/Visibility';
import CloseIcon from '@mui/icons-material/Close';
import { authAPI } from '../services/api';

interface Patient {
  user_id: string;
  name: string;
  email: string;
  age?: string;
  gender?: string;
}

interface MedicalReport {
  report_id: string;
  report_type: string;
  report_name: string;
  date: string;
  doctor_name: string;
  status: 'completed' | 'pending' | 'reviewed';
  summary?: string;
  details?: {
    test_name?: string;
    result?: string;
    reference_range?: string;
    unit?: string;
  }[];
  findings?: string;
  recommendations?: string;
}

const PatientReports = () => {
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [patients, setPatients] = useState<Patient[]>([]);
  const [selectedPatient, setSelectedPatient] = useState<Patient | null>(null);
  const [reports, setReports] = useState<MedicalReport[]>([]);
  const [viewDialogOpen, setViewDialogOpen] = useState(false);
  const [selectedReport, setSelectedReport] = useState<MedicalReport | null>(null);

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

  const fetchPatientReports = async (patientId: string) => {
    // Get reports from localStorage for this patient
    const storedReports = localStorage.getItem(`reports_${patientId}`);
    
    if (storedReports) {
      setReports(JSON.parse(storedReports));
    } else {
      setReports([]);
    }
  };
  const handlePatientClick = async (patient: Patient) => {
    setSelectedPatient(patient);
    await fetchPatientReports(patient.user_id);
  };

  const handleBackToList = () => {
    setSelectedPatient(null);
    setReports([]);
  };

  const handleDownloadReport = (reportId: string) => {
    const report = reports.find(r => r.report_id === reportId);
    if (!report || !selectedPatient) return;

    // Create PDF content
    const pdfContent = `
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>${report.report_name}</title>
  <style>
    body { font-family: Arial, sans-serif; padding: 40px; line-height: 1.6; }
    .header { text-align: center; margin-bottom: 30px; border-bottom: 2px solid #008B8B; padding-bottom: 20px; }
    .header h1 { color: #008B8B; margin: 0; }
    .header p { margin: 5px 0; color: #666; }
    .section { margin: 20px 0; }
    .section h2 { color: #008B8B; border-bottom: 1px solid #ddd; padding-bottom: 5px; }
    .info-grid { display: grid; grid-template-columns: 150px 1fr; gap: 10px; margin: 10px 0; }
    .info-label { font-weight: bold; color: #333; }
    table { width: 100%; border-collapse: collapse; margin: 15px 0; }
    th, td { border: 1px solid #ddd; padding: 12px; text-align: left; }
    th { background-color: #008B8B; color: white; }
    .status { display: inline-block; padding: 4px 12px; border-radius: 4px; font-size: 12px; }
    .status-completed { background-color: #4caf50; color: white; }
    .status-reviewed { background-color: #2196f3; color: white; }
    .footer { margin-top: 40px; padding-top: 20px; border-top: 1px solid #ddd; text-align: center; color: #666; font-size: 12px; }
  </style>
</head>
<body>
  <div class="header">
    <h1>SwasthyaAI Medical Report</h1>
    <p>AI-Powered Clinical Intelligence Assistant</p>
  </div>

  <div class="section">
    <h2>Patient Information</h2>
    <div class="info-grid">
      <div class="info-label">Patient Name:</div>
      <div>${selectedPatient.name}</div>
      <div class="info-label">Patient ID:</div>
      <div>${selectedPatient.user_id}</div>
      <div class="info-label">Age:</div>
      <div>${selectedPatient.age || 'N/A'}</div>
      <div class="info-label">Gender:</div>
      <div>${selectedPatient.gender || 'N/A'}</div>
    </div>
  </div>

  <div class="section">
    <h2>Report Details</h2>
    <div class="info-grid">
      <div class="info-label">Report Type:</div>
      <div>${report.report_type}</div>
      <div class="info-label">Report Name:</div>
      <div>${report.report_name}</div>
      <div class="info-label">Date:</div>
      <div>${new Date(report.date).toLocaleDateString()}</div>
      <div class="info-label">Doctor:</div>
      <div>${report.doctor_name}</div>
      <div class="info-label">Status:</div>
      <div><span class="status status-${report.status}">${report.status.toUpperCase()}</span></div>
    </div>
  </div>

  ${report.details ? `
  <div class="section">
    <h2>Test Results</h2>
    <table>
      <thead>
        <tr>
          <th>Test Name</th>
          <th>Result</th>
          <th>Reference Range</th>
          <th>Unit</th>
        </tr>
      </thead>
      <tbody>
        ${report.details.map(detail => `
          <tr>
            <td>${detail.test_name}</td>
            <td><strong>${detail.result}</strong></td>
            <td>${detail.reference_range}</td>
            <td>${detail.unit}</td>
          </tr>
        `).join('')}
      </tbody>
    </table>
  </div>
  ` : ''}

  ${report.findings ? `
  <div class="section">
    <h2>Findings</h2>
    <p>${report.findings}</p>
  </div>
  ` : ''}

  ${report.recommendations ? `
  <div class="section">
    <h2>Recommendations</h2>
    <p>${report.recommendations}</p>
  </div>
  ` : ''}

  <div class="section">
    <h2>Summary</h2>
    <p>${report.summary}</p>
  </div>

  <div class="footer">
    <p>This report was generated by SwasthyaAI on ${new Date().toLocaleDateString()}</p>
    <p>For medical advice, please consult with your healthcare provider</p>
  </div>
</body>
</html>
    `;

    // Create a blob and download
    const blob = new Blob([pdfContent], { type: 'text/html' });
    const url = window.URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.download = `${report.report_name.replace(/\s+/g, '_')}_${selectedPatient.name.replace(/\s+/g, '_')}_${report.date}.html`;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    window.URL.revokeObjectURL(url);
  };

  const handleViewReport = (reportId: string) => {
    const report = reports.find(r => r.report_id === reportId);
    if (report) {
      setSelectedReport(report);
      setViewDialogOpen(true);
    }
  };

  const handleCloseViewDialog = () => {
    setViewDialogOpen(false);
    setSelectedReport(null);
  };

  const getReportTypeColor = (type: string) => {
    switch (type.toLowerCase()) {
      case 'blood test':
        return 'error';
      case 'ct scan':
        return 'primary';
      case 'x-ray':
        return 'secondary';
      case 'mri':
        return 'info';
      default:
        return 'default';
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'completed':
        return 'success';
      case 'pending':
        return 'warning';
      case 'reviewed':
        return 'info';
      default:
        return 'default';
    }
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
          Patient Reports
        </Typography>
        <Typography variant="body2" color="text.secondary" sx={{ mb: 3 }}>
          Select a patient to view their medical reports
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

  // Patient Reports Detail View
  return (
    <Box>
      <Box sx={{ display: 'flex', alignItems: 'center', mb: 3 }}>
        <IconButton onClick={handleBackToList} sx={{ mr: 2 }}>
          <ArrowBackIcon />
        </IconButton>
        <Box>
          <Typography variant="h4" sx={{ color: 'primary.main', fontWeight: 600 }}>
            {selectedPatient.name} - Medical Reports
          </Typography>
          <Typography variant="body2" color="text.secondary">
            Patient ID: {selectedPatient.user_id}
          </Typography>
        </Box>
      </Box>

      {/* Summary Cards */}
      <Grid container spacing={3} sx={{ mb: 3 }}>
        <Grid item xs={12} md={3}>
          <Card>
            <CardContent>
              <Typography variant="h4" sx={{ fontWeight: 600, color: 'primary.main' }}>
                {reports.length}
              </Typography>
              <Typography variant="body2" color="text.secondary">
                Total Reports
              </Typography>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} md={3}>
          <Card>
            <CardContent>
              <Typography variant="h4" sx={{ fontWeight: 600, color: 'error.main' }}>
                {reports.filter(r => r.report_type === 'Blood Test').length}
              </Typography>
              <Typography variant="body2" color="text.secondary">
                Blood Tests
              </Typography>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} md={3}>
          <Card>
            <CardContent>
              <Typography variant="h4" sx={{ fontWeight: 600, color: 'primary.main' }}>
                {reports.filter(r => r.report_type === 'CT Scan' || r.report_type === 'MRI').length}
              </Typography>
              <Typography variant="body2" color="text.secondary">
                Imaging Scans
              </Typography>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} md={3}>
          <Card>
            <CardContent>
              <Typography variant="h4" sx={{ fontWeight: 600, color: 'success.main' }}>
                {reports.filter(r => r.status === 'reviewed').length}
              </Typography>
              <Typography variant="body2" color="text.secondary">
                Reviewed
              </Typography>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Reports List */}
      <Paper sx={{ p: 3 }}>
        <Typography variant="h6" sx={{ color: 'primary.main', mb: 2 }}>
          Medical Reports
        </Typography>
        <Divider sx={{ mb: 2 }} />
        
        {reports.length === 0 ? (
          <Alert severity="info">No reports found for this patient.</Alert>
        ) : (
          <Grid container spacing={2}>
            {reports.map((report) => (
              <Grid item xs={12} key={report.report_id}>
                <Card variant="outlined">
                  <CardContent>
                    <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                      <Box sx={{ flex: 1 }}>
                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 1 }}>
                          <DescriptionIcon sx={{ color: 'primary.main' }} />
                          <Typography variant="h6" sx={{ fontWeight: 500 }}>
                            {report.report_name}
                          </Typography>
                          <Chip 
                            label={report.report_type} 
                            size="small" 
                            color={getReportTypeColor(report.report_type)}
                          />
                          <Chip 
                            label={report.status} 
                            size="small" 
                            color={getStatusColor(report.status)}
                          />
                        </Box>
                        
                        <Typography variant="body2" color="text.secondary" sx={{ mb: 1 }}>
                          Date: {new Date(report.date).toLocaleDateString()} • Doctor: {report.doctor_name}
                        </Typography>
                        
                        {report.summary && (
                          <Typography variant="body2" sx={{ mt: 1 }}>
                            Summary: {report.summary}
                          </Typography>
                        )}
                      </Box>
                      
                      <Box sx={{ display: 'flex', gap: 1 }}>
                        <Button
                          variant="outlined"
                          size="small"
                          startIcon={<VisibilityIcon />}
                          onClick={() => handleViewReport(report.report_id)}
                        >
                          View
                        </Button>
                        <Button
                          variant="contained"
                          size="small"
                          startIcon={<DownloadIcon />}
                          onClick={() => handleDownloadReport(report.report_id)}
                        >
                          Download
                        </Button>
                      </Box>
                    </Box>
                  </CardContent>
                </Card>
              </Grid>
            ))}
          </Grid>
        )}
      </Paper>

      {/* View Report Dialog */}
      <Dialog 
        open={viewDialogOpen} 
        onClose={handleCloseViewDialog}
        maxWidth="md"
        fullWidth
      >
        <DialogTitle>
          <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <Typography variant="h6">
              {selectedReport?.report_name}
            </Typography>
            <IconButton onClick={handleCloseViewDialog}>
              <CloseIcon />
            </IconButton>
          </Box>
        </DialogTitle>
        <DialogContent dividers>
          {selectedReport && (
            <Box>
              {/* Report Header */}
              <Box sx={{ mb: 3 }}>
                <Grid container spacing={2}>
                  <Grid item xs={6}>
                    <Typography variant="body2" color="text.secondary">
                      Patient Name
                    </Typography>
                    <Typography variant="body1" sx={{ fontWeight: 500 }}>
                      {selectedPatient?.name}
                    </Typography>
                  </Grid>
                  <Grid item xs={6}>
                    <Typography variant="body2" color="text.secondary">
                      Patient ID
                    </Typography>
                    <Typography variant="body1" sx={{ fontWeight: 500 }}>
                      {selectedPatient?.user_id}
                    </Typography>
                  </Grid>
                  <Grid item xs={6}>
                    <Typography variant="body2" color="text.secondary">
                      Report Type
                    </Typography>
                    <Chip 
                      label={selectedReport.report_type} 
                      size="small" 
                      color={getReportTypeColor(selectedReport.report_type)}
                      sx={{ mt: 0.5 }}
                    />
                  </Grid>
                  <Grid item xs={6}>
                    <Typography variant="body2" color="text.secondary">
                      Date
                    </Typography>
                    <Typography variant="body1" sx={{ fontWeight: 500 }}>
                      {new Date(selectedReport.date).toLocaleDateString()}
                    </Typography>
                  </Grid>
                  <Grid item xs={6}>
                    <Typography variant="body2" color="text.secondary">
                      Doctor
                    </Typography>
                    <Typography variant="body1" sx={{ fontWeight: 500 }}>
                      {selectedReport.doctor_name}
                    </Typography>
                  </Grid>
                  <Grid item xs={6}>
                    <Typography variant="body2" color="text.secondary">
                      Status
                    </Typography>
                    <Chip 
                      label={selectedReport.status} 
                      size="small" 
                      color={getStatusColor(selectedReport.status)}
                      sx={{ mt: 0.5 }}
                    />
                  </Grid>
                </Grid>
              </Box>

              <Divider sx={{ my: 2 }} />

              {/* Test Results Table */}
              {selectedReport.details && selectedReport.details.length > 0 && (
                <Box sx={{ mb: 3 }}>
                  <Typography variant="h6" sx={{ color: 'primary.main', mb: 2 }}>
                    Test Results
                  </Typography>
                  <TableContainer component={Paper} variant="outlined">
                    <Table size="small">
                      <TableBody>
                        <TableRow sx={{ bgcolor: 'primary.main' }}>
                          <TableCell sx={{ color: 'white', fontWeight: 600 }}>Test Name</TableCell>
                          <TableCell sx={{ color: 'white', fontWeight: 600 }}>Result</TableCell>
                          <TableCell sx={{ color: 'white', fontWeight: 600 }}>Reference Range</TableCell>
                          <TableCell sx={{ color: 'white', fontWeight: 600 }}>Unit</TableCell>
                        </TableRow>
                        {selectedReport.details.map((detail, index) => (
                          <TableRow key={index}>
                            <TableCell>{detail.test_name}</TableCell>
                            <TableCell sx={{ fontWeight: 600 }}>{detail.result}</TableCell>
                            <TableCell>{detail.reference_range}</TableCell>
                            <TableCell>{detail.unit}</TableCell>
                          </TableRow>
                        ))}
                      </TableBody>
                    </Table>
                  </TableContainer>
                </Box>
              )}

              {/* Findings */}
              {selectedReport.findings && (
                <Box sx={{ mb: 3 }}>
                  <Typography variant="h6" sx={{ color: 'primary.main', mb: 1 }}>
                    Findings
                  </Typography>
                  <Paper variant="outlined" sx={{ p: 2, bgcolor: 'grey.50' }}>
                    <Typography variant="body2">
                      {selectedReport.findings}
                    </Typography>
                  </Paper>
                </Box>
              )}

              {/* Recommendations */}
              {selectedReport.recommendations && (
                <Box sx={{ mb: 3 }}>
                  <Typography variant="h6" sx={{ color: 'primary.main', mb: 1 }}>
                    Recommendations
                  </Typography>
                  <Paper variant="outlined" sx={{ p: 2, bgcolor: 'grey.50' }}>
                    <Typography variant="body2">
                      {selectedReport.recommendations}
                    </Typography>
                  </Paper>
                </Box>
              )}

              {/* Summary */}
              <Box>
                <Typography variant="h6" sx={{ color: 'primary.main', mb: 1 }}>
                  Summary
                </Typography>
                <Paper variant="outlined" sx={{ p: 2, bgcolor: 'grey.50' }}>
                  <Typography variant="body2">
                    {selectedReport.summary}
                  </Typography>
                </Paper>
              </Box>
            </Box>
          )}
        </DialogContent>
        <DialogActions>
          <Button 
            onClick={() => selectedReport && handleDownloadReport(selectedReport.report_id)}
            startIcon={<DownloadIcon />}
            variant="contained"
          >
            Download Report
          </Button>
          <Button onClick={handleCloseViewDialog}>
            Close
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default PatientReports;
