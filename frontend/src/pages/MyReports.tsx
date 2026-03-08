import { useState, useEffect } from 'react';
import {
  Box,
  Typography,
  Paper,
  Grid,
  Card,
  CardContent,
  Alert,
  Chip,
  Divider,
  Button,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableRow,
  IconButton,
  CircularProgress
} from '@mui/material';
import DescriptionIcon from '@mui/icons-material/Description';
import DownloadIcon from '@mui/icons-material/Download';
import VisibilityIcon from '@mui/icons-material/Visibility';
import CloseIcon from '@mui/icons-material/Close';
import UploadFileIcon from '@mui/icons-material/UploadFile';

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
  file_url?: string;
}

const MyReports = () => {
  const [loading, setLoading] = useState(false);
  const [reports, setReports] = useState<MedicalReport[]>([]);
  const [viewDialogOpen, setViewDialogOpen] = useState(false);
  const [uploadDialogOpen, setUploadDialogOpen] = useState(false);
  const [selectedReport, setSelectedReport] = useState<MedicalReport | null>(null);
  const [uploadFile, setUploadFile] = useState<File | null>(null);
  const [uploadSuccess, setUploadSuccess] = useState(false);

  const patientId = localStorage.getItem('userId') || '';
  const patientName = localStorage.getItem('userName') || '';

  useEffect(() => {
    fetchMyReports();
  }, []);

  const fetchMyReports = async () => {
    setLoading(true);
    
    try {
      // Get reports from localStorage or use mock data
      const storedReports = localStorage.getItem(`reports_${patientId}`);
      
      if (storedReports) {
        setReports(JSON.parse(storedReports));
      } else {
        // Mock initial reports for demo
        const mockReports: MedicalReport[] = [
          {
            report_id: 'rep001',
            report_type: 'Blood Test',
            report_name: 'Complete Blood Count (CBC)',
            date: '2026-03-05',
            doctor_name: 'Dr. Sarah Johnson',
            status: 'completed',
            summary: 'All parameters within normal range',
            details: [
              { test_name: 'Hemoglobin', result: '14.5', reference_range: '13.0-17.0', unit: 'g/dL' },
              { test_name: 'WBC Count', result: '7.2', reference_range: '4.0-11.0', unit: '10^3/μL' },
              { test_name: 'Platelet Count', result: '250', reference_range: '150-400', unit: '10^3/μL' }
            ],
            findings: 'All blood parameters are within normal limits.',
            recommendations: 'Continue regular health monitoring.'
          },
          {
            report_id: 'rep002',
            report_type: 'X-Ray',
            report_name: 'Chest X-Ray',
            date: '2026-02-25',
            doctor_name: 'Dr. Emily Davis',
            status: 'completed',
            summary: 'Clear lung fields, no acute findings',
            findings: 'Chest X-ray shows clear lung fields bilaterally.',
            recommendations: 'No immediate action required.'
          }
        ];
        setReports(mockReports);
        localStorage.setItem(`reports_${patientId}`, JSON.stringify(mockReports));
      }
    } catch (err) {
      console.error('Error fetching reports:', err);
    } finally {
      setLoading(false);
    }
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

  const handleOpenUploadDialog = () => {
    setUploadDialogOpen(true);
    setUploadSuccess(false);
  };

  const handleCloseUploadDialog = () => {
    setUploadDialogOpen(false);
    setUploadFile(null);
    setUploadSuccess(false);
  };

  const handleFileSelect = (event: React.ChangeEvent<HTMLInputElement>) => {
    if (event.target.files && event.target.files[0]) {
      setUploadFile(event.target.files[0]);
    }
  };

  const handleUploadReport = () => {
    if (!uploadFile) return;

    // Create new report entry
    const newReport: MedicalReport = {
      report_id: `rep_${Date.now()}`,
      report_type: 'Uploaded Document',
      report_name: uploadFile.name,
      date: new Date().toISOString().split('T')[0],
      doctor_name: 'Self Uploaded',
      status: 'pending',
      summary: 'Document uploaded by patient',
      file_url: URL.createObjectURL(uploadFile)
    };

    const updatedReports = [newReport, ...reports];
    setReports(updatedReports);
    localStorage.setItem(`reports_${patientId}`, JSON.stringify(updatedReports));
    
    setUploadSuccess(true);
    setTimeout(() => {
      handleCloseUploadDialog();
    }, 1500);
  };

  const handleDownloadReport = (reportId: string) => {
    const report = reports.find(r => r.report_id === reportId);
    if (!report) return;

    // If it's an uploaded file with URL, download it directly
    if (report.file_url) {
      const link = document.createElement('a');
      link.href = report.file_url;
      link.download = report.report_name;
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
      return;
    }

    // Otherwise, generate HTML report
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
    .section { margin: 20px 0; }
    .section h2 { color: #008B8B; border-bottom: 1px solid #ddd; padding-bottom: 5px; }
    .info-grid { display: grid; grid-template-columns: 150px 1fr; gap: 10px; margin: 10px 0; }
    .info-label { font-weight: bold; }
    table { width: 100%; border-collapse: collapse; margin: 15px 0; }
    th, td { border: 1px solid #ddd; padding: 12px; text-align: left; }
    th { background-color: #008B8B; color: white; }
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
      <div>${patientName}</div>
      <div class="info-label">Patient ID:</div>
      <div>${patientId}</div>
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
      <div>${report.status.toUpperCase()}</div>
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

  <div style="margin-top: 40px; padding-top: 20px; border-top: 1px solid #ddd; text-align: center; color: #666; font-size: 12px;">
    <p>Generated on ${new Date().toLocaleDateString()}</p>
  </div>
</body>
</html>
    `;

    const blob = new Blob([pdfContent], { type: 'text/html' });
    const url = window.URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.download = `${report.report_name.replace(/\s+/g, '_')}_${report.date}.html`;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    window.URL.revokeObjectURL(url);
  };

  const getReportTypeColor = (type: string) => {
    switch (type.toLowerCase()) {
      case 'blood test':
        return 'error';
      case 'x-ray':
        return 'secondary';
      case 'uploaded document':
        return 'warning';
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

  return (
    <Box>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
        <Box>
          <Typography variant="h4" sx={{ color: 'primary.main', fontWeight: 600 }}>
            My Medical Reports
          </Typography>
          <Typography variant="body2" color="text.secondary">
            View and manage your medical reports
          </Typography>
        </Box>
        <Button
          variant="contained"
          startIcon={<UploadFileIcon />}
          onClick={handleOpenUploadDialog}
        >
          Upload Report
        </Button>
      </Box>

      {/* Summary Cards */}
      <Grid container spacing={3} sx={{ mb: 3 }}>
        <Grid item xs={12} md={4}>
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
        <Grid item xs={12} md={4}>
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
        <Grid item xs={12} md={4}>
          <Card>
            <CardContent>
              <Typography variant="h4" sx={{ fontWeight: 600, color: 'success.main' }}>
                {reports.filter(r => r.status === 'completed').length}
              </Typography>
              <Typography variant="body2" color="text.secondary">
                Completed
              </Typography>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Reports List */}
      <Paper sx={{ p: 3 }}>
        <Typography variant="h6" sx={{ color: 'primary.main', mb: 2 }}>
          All Reports
        </Typography>
        <Divider sx={{ mb: 2 }} />
        
        {loading ? (
          <Box sx={{ display: 'flex', justifyContent: 'center', py: 4 }}>
            <CircularProgress />
          </Box>
        ) : reports.length === 0 ? (
          <Alert severity="info">No reports found. Upload your first report to get started.</Alert>
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

      {/* Upload Dialog */}
      <Dialog open={uploadDialogOpen} onClose={handleCloseUploadDialog} maxWidth="sm" fullWidth>
        <DialogTitle>Upload Medical Report</DialogTitle>
        <DialogContent>
          {uploadSuccess ? (
            <Alert severity="success" sx={{ mt: 2 }}>
              Report uploaded successfully!
            </Alert>
          ) : (
            <Box sx={{ mt: 2 }}>
              <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
                Upload your medical reports (PDF, images, or documents)
              </Typography>
              <Button
                variant="outlined"
                component="label"
                fullWidth
                startIcon={<UploadFileIcon />}
                sx={{ py: 2 }}
              >
                {uploadFile ? uploadFile.name : 'Choose File'}
                <input
                  type="file"
                  hidden
                  accept=".pdf,.jpg,.jpeg,.png,.doc,.docx"
                  onChange={handleFileSelect}
                />
              </Button>
              {uploadFile && (
                <Alert severity="info" sx={{ mt: 2 }}>
                  Selected: {uploadFile.name} ({(uploadFile.size / 1024).toFixed(2)} KB)
                </Alert>
              )}
            </Box>
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={handleCloseUploadDialog}>Cancel</Button>
          <Button 
            onClick={handleUploadReport} 
            variant="contained"
            disabled={!uploadFile || uploadSuccess}
          >
            Upload
          </Button>
        </DialogActions>
      </Dialog>

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
                      {patientName}
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
              {selectedReport.summary && (
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
              )}
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

export default MyReports;
