import { useState } from 'react';
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
  Chip,
  Divider,
  Grid,
  MenuItem,
  Select,
  FormControl,
  InputLabel,
} from '@mui/material';
import CheckCircleIcon from '@mui/icons-material/CheckCircle';
import CancelIcon from '@mui/icons-material/Cancel';
import SearchIcon from '@mui/icons-material/Search';
import { insuranceAPI } from '../services/api';

interface AnalysisResult {
  eligible: boolean;
  coverage_percentage: number;
  explanation: string;
  confidence?: number;
  check_id?: string;
  timestamp?: string;
}

// Common procedure codes
const PROCEDURE_CODES = [
  { code: 'CPT-99213', name: 'Office Visit - Established Patient (15 min)' },
  { code: 'CPT-99214', name: 'Office Visit - Established Patient (25 min)' },
  { code: 'CPT-99215', name: 'Office Visit - Established Patient (40 min)' },
  { code: 'CPT-70450', name: 'CT Scan - Head/Brain without Contrast' },
  { code: 'CPT-71020', name: 'Chest X-Ray - 2 Views' },
  { code: 'CPT-80053', name: 'Comprehensive Metabolic Panel' },
  { code: 'CPT-85025', name: 'Complete Blood Count (CBC)' },
  { code: 'CPT-93000', name: 'Electrocardiogram (ECG/EKG)' },
  { code: 'CPT-99283', name: 'Emergency Department Visit - Moderate' },
  { code: 'CPT-29881', name: 'Knee Arthroscopy/Surgery' },
];

// Sample policy keys (in production, these would come from user's profile)
const SAMPLE_POLICIES = [
  'policies/sample/basic-health-policy.txt',
  'policies/sample/premium-health-policy.txt',
  'policies/sample/family-health-policy.txt',
];

const InsuranceChecker = () => {
  const [policyKey, setPolicyKey] = useState('');
  const [procedureCode, setProcedureCode] = useState('');
  const [providerNetwork, setProviderNetwork] = useState('');
  const [loading, setLoading] = useState(false);
  const [result, setResult] = useState<AnalysisResult | null>(null);
  const [error, setError] = useState('');

  const handleAnalyze = async () => {
    if (!policyKey || !procedureCode) {
      setError('Policy and procedure code are required');
      return;
    }

    setLoading(true);
    setError('');
    setResult(null);

    try {
      const patientId = localStorage.getItem('userId') || 'anonymous';
      
      // Parse provider network if provided
      let networkData = {};
      if (providerNetwork.trim()) {
        try {
          networkData = JSON.parse(providerNetwork);
        } catch (e) {
          setError('Invalid JSON format for provider network');
          setLoading(false);
          return;
        }
      }

      const data = await insuranceAPI.analyze({
        policy_key: policyKey,
        procedure_code: procedureCode,
        provider_network: networkData,
        patient_id: patientId,
      });

      if (data.error) {
        setError(data.error);
      } else {
        setResult(data);
      }
    } catch (err) {
      console.error('Insurance analysis error:', err);
      setError('Failed to connect to the server. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <Box>
      <Typography variant="h4" gutterBottom sx={{ color: 'primary.main', fontWeight: 600 }}>
        Insurance Eligibility Checker
      </Typography>
      <Typography variant="body2" color="text.secondary" sx={{ mb: 3 }}>
        Check if your medical procedure is covered by your insurance policy
      </Typography>

      <Paper sx={{ p: 3, mb: 3 }}>
        <Typography variant="h6" gutterBottom sx={{ color: 'primary.main' }}>
          Policy & Procedure Information
        </Typography>
        <Divider sx={{ mb: 3 }} />

        <Grid container spacing={3}>
          <Grid item xs={12} md={6}>
            <FormControl fullWidth>
              <InputLabel>Insurance Policy</InputLabel>
              <Select
                value={policyKey}
                onChange={(e) => setPolicyKey(e.target.value)}
                label="Insurance Policy"
              >
                <MenuItem value="">
                  <em>Select a policy</em>
                </MenuItem>
                {SAMPLE_POLICIES.map((policy) => (
                  <MenuItem key={policy} value={policy}>
                    {policy.split('/').pop()?.replace('.txt', '').replace(/-/g, ' ').toUpperCase()}
                  </MenuItem>
                ))}
              </Select>
            </FormControl>
            <Typography variant="caption" color="text.secondary" sx={{ mt: 1, display: 'block' }}>
              Select your insurance policy type
            </Typography>
          </Grid>

          <Grid item xs={12} md={6}>
            <FormControl fullWidth>
              <InputLabel>Procedure Code</InputLabel>
              <Select
                value={procedureCode}
                onChange={(e) => setProcedureCode(e.target.value)}
                label="Procedure Code"
              >
                <MenuItem value="">
                  <em>Select a procedure</em>
                </MenuItem>
                {PROCEDURE_CODES.map((proc) => (
                  <MenuItem key={proc.code} value={proc.code}>
                    {proc.code} - {proc.name}
                  </MenuItem>
                ))}
              </Select>
            </FormControl>
            <Typography variant="caption" color="text.secondary" sx={{ mt: 1, display: 'block' }}>
              Select the medical procedure you need
            </Typography>
          </Grid>

          <Grid item xs={12}>
            <TextField
              fullWidth
              label="Provider Network (Optional)"
              placeholder='{"hospital": "Apollo", "network": "PPO"}'
              value={providerNetwork}
              onChange={(e) => setProviderNetwork(e.target.value)}
              multiline
              rows={2}
              helperText="Optional: Enter provider network details as JSON"
            />
          </Grid>
        </Grid>

        <Button
          variant="contained"
          size="large"
          onClick={handleAnalyze}
          disabled={loading || !policyKey || !procedureCode}
          sx={{ mt: 3 }}
          startIcon={loading ? <CircularProgress size={20} color="inherit" /> : <SearchIcon />}
          fullWidth
        >
          {loading ? 'Analyzing Coverage...' : 'Check Coverage'}
        </Button>
      </Paper>

      {error && (
        <Alert severity="error" sx={{ mb: 3 }}>
          {error}
        </Alert>
      )}

      {result && (
        <Card sx={{ mb: 3, border: result.eligible ? '2px solid #4caf50' : '2px solid #f44336' }}>
          <CardContent>
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, mb: 3 }}>
              {result.eligible ? (
                <CheckCircleIcon sx={{ fontSize: 56, color: 'success.main' }} />
              ) : (
                <CancelIcon sx={{ fontSize: 56, color: 'error.main' }} />
              )}
              <Box sx={{ flex: 1 }}>
                <Typography variant="h5" sx={{ fontWeight: 600, mb: 1 }}>
                  {result.eligible ? 'Procedure is Covered ✓' : 'Procedure Not Covered ✗'}
                </Typography>
                <Box sx={{ display: 'flex', gap: 1, alignItems: 'center' }}>
                  <Chip
                    label={`Coverage: ${result.coverage_percentage}%`}
                    color={result.eligible ? 'success' : 'error'}
                    size="medium"
                  />
                  {result.confidence && (
                    <Chip
                      label={`Confidence: ${(result.confidence * 100).toFixed(0)}%`}
                      color={result.confidence > 0.8 ? 'success' : 'warning'}
                      size="medium"
                      variant="outlined"
                    />
                  )}
                </Box>
              </Box>
            </Box>

            <Divider sx={{ my: 2 }} />

            <Typography variant="h6" gutterBottom sx={{ color: 'primary.main' }}>
              Analysis Details
            </Typography>
            <Paper variant="outlined" sx={{ p: 2, bgcolor: 'grey.50', mb: 2 }}>
              <Typography variant="body1" sx={{ whiteSpace: 'pre-wrap' }}>
                {result.explanation}
              </Typography>
            </Paper>

            {result.check_id && (
              <Box sx={{ mt: 2 }}>
                <Typography variant="caption" color="text.secondary">
                  Check ID: {result.check_id}
                </Typography>
                {result.timestamp && (
                  <Typography variant="caption" color="text.secondary" sx={{ ml: 2 }}>
                    • Analyzed: {new Date(result.timestamp).toLocaleString()}
                  </Typography>
                )}
              </Box>
            )}

            {result.eligible && (
              <Alert severity="success" sx={{ mt: 2 }}>
                <Typography variant="body2">
                  <strong>Next Steps:</strong> Contact your insurance provider to confirm coverage details and get pre-authorization if required.
                </Typography>
              </Alert>
            )}

            {!result.eligible && (
              <Alert severity="warning" sx={{ mt: 2 }}>
                <Typography variant="body2">
                  <strong>Alternative Options:</strong> Consider discussing alternative procedures with your doctor or exploring payment plans with your healthcare provider.
                </Typography>
              </Alert>
            )}
          </CardContent>
        </Card>
      )}

      {!result && !error && !loading && (
        <Paper sx={{ p: 4, textAlign: 'center', bgcolor: 'grey.50' }}>
          <Typography variant="body1" color="text.secondary">
            Select your insurance policy and procedure code above to check coverage eligibility
          </Typography>
        </Paper>
      )}
    </Box>
  );
};

export default InsuranceChecker;
