import React from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { ThemeProvider, createTheme } from '@mui/material/styles';
import CssBaseline from '@mui/material/CssBaseline';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { Provider } from 'react-redux';
import { Amplify } from 'aws-amplify';

// Components
import Layout from './components/Layout';
import PatientChatbot from './components/PatientChatbot';
import Login from './pages/Login';
import DoctorDashboard from './pages/DoctorDashboard';
import PatientDashboard from './pages/PatientDashboard';
import DoctorProfile from './pages/DoctorProfile';
import PatientProfile from './pages/PatientProfile';
import BookAppointment from './pages/BookAppointment';
import PatientRecord from './pages/PatientRecord';
import ClinicalNoteEditor from './pages/ClinicalNoteEditor';
import ApprovalQueue from './pages/ApprovalQueue';
import PatientReports from './pages/PatientReports';
import MyReports from './pages/MyReports';
import InsuranceChecker from './pages/InsuranceChecker';

// Store
import { store } from './store';

// AWS Amplify Configuration
Amplify.configure({
  Auth: {
    Cognito: {
      userPoolId: import.meta.env.VITE_COGNITO_USER_POOL_ID || '',
      userPoolClientId: import.meta.env.VITE_COGNITO_CLIENT_ID || ''
    }
  }
});

// Create theme with Deep Teal and Warm Cream
const theme = createTheme({
  palette: {
    primary: {
      main: '#008B8B', // Deep Teal
      light: '#20B2AA',
      dark: '#006666',
      contrastText: '#FFFFFF',
    },
    secondary: {
      main: '#F5F5DC', // Warm Cream
      light: '#FFFEF0',
      dark: '#E6E6CD',
      contrastText: '#333333',
    },
    background: {
      default: '#FAFAFA',
      paper: '#FFFFFF',
    },
    text: {
      primary: '#333333',
      secondary: '#666666',
    },
  },
  typography: {
    fontFamily: [
      '-apple-system',
      'BlinkMacSystemFont',
      '"Segoe UI"',
      'Roboto',
      '"Helvetica Neue"',
      'Arial',
      'sans-serif',
    ].join(','),
    h4: {
      fontWeight: 600,
      color: '#008B8B',
    },
    h6: {
      fontWeight: 500,
      color: '#008B8B',
    },
  },
  components: {
    MuiButton: {
      styleOverrides: {
        root: {
          borderRadius: 8,
          textTransform: 'none',
          fontWeight: 500,
        },
      },
    },
    MuiPaper: {
      styleOverrides: {
        root: {
          borderRadius: 12,
        },
      },
    },
  },
});

// Create React Query client
const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      refetchOnWindowFocus: false,
      retry: 1,
      staleTime: 5 * 60 * 1000, // 5 minutes
    },
  },
});

// Protected Route Component
const ProtectedRoute = ({ children }: { children: React.ReactNode }) => {
  const isAuthenticated = localStorage.getItem('isAuthenticated') === 'true';
  
  if (!isAuthenticated) {
    return <Navigate to="/login" replace />;
  }
  
  return <>{children}</>;
};

// Role-based Dashboard Component
const RoleBasedDashboard = () => {
  const userRole = localStorage.getItem('userRole');
  
  if (userRole === 'doctor') {
    return <DoctorDashboard />;
  } else if (userRole === 'patient') {
    return <PatientDashboard />;
  }
  
  // Default to patient dashboard if role not set
  return <PatientDashboard />;
};

// Role-based Reports Component
const RoleBasedReports = () => {
  const userRole = localStorage.getItem('userRole');
  
  if (userRole === 'doctor') {
    return <PatientReports />;
  } else {
    return <MyReports />;
  }
};

// Role-based Profile Component
const RoleBasedProfile = () => {
  const userRole = localStorage.getItem('userRole');
  
  if (userRole === 'doctor') {
    return <DoctorProfile />;
  } else {
    return <PatientProfile />;
  }
};

// Role-based History Component
const RoleBasedHistory = () => {
  const userRole = localStorage.getItem('userRole');
  
  if (userRole === 'doctor') {
    return <PatientRecord />;
  } else {
    return <RoleBasedDashboard />;
  }
};

function App() {
  return (
    <Provider store={store}>
      <QueryClientProvider client={queryClient}>
        <ThemeProvider theme={theme}>
          <CssBaseline />
          <Router>
            <Routes>
              <Route path="/login" element={<Login />} />
              <Route
                path="/"
                element={
                  <ProtectedRoute>
                    <Layout />
                  </ProtectedRoute>
                }
              >
                <Route index element={<RoleBasedDashboard />} />
                <Route path="profile" element={<RoleBasedProfile />} />
                <Route path="book-appointment" element={<BookAppointment />} />
                <Route path="patient/:patientId" element={<PatientRecord />} />
                <Route path="note/new" element={<ClinicalNoteEditor />} />
                <Route path="note/:noteId" element={<ClinicalNoteEditor />} />
                <Route path="approvals" element={<ApprovalQueue />} />
                <Route path="insurance" element={<InsuranceChecker />} />
                <Route path="patient-assistant" element={<RoleBasedDashboard />} />
                <Route path="history" element={<RoleBasedHistory />} />
                <Route path="insights" element={<RoleBasedDashboard />} />
                <Route path="reports" element={<RoleBasedReports />} />
                <Route path="settings" element={<RoleBasedDashboard />} />
              </Route>
            </Routes>
            <ProtectedRoute>
              <PatientChatbot />
            </ProtectedRoute>
          </Router>
        </ThemeProvider>
      </QueryClientProvider>
    </Provider>
  );
}

export default App;
