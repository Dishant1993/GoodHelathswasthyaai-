// API Service for SwasthyaAI
const API_ENDPOINT = import.meta.env.VITE_API_ENDPOINT || 'http://localhost:3001';

// Helper function to get auth headers
const getAuthHeaders = () => {
  const token = localStorage.getItem('authToken');
  return {
    'Content-Type': 'application/json',
    ...(token && { 'Authorization': `Bearer ${token}` })
  };
};

// Authentication APIs
export const authAPI = {
  signup: async (data: {
    email: string;
    password: string;
    name: string;
    role: 'doctor' | 'patient';
    degree?: string;
    experience?: string;
    specialization?: string;
    age?: string;
    gender?: string;
    phone?: string;
  }) => {
    const response = await fetch(`${API_ENDPOINT}/auth/signup`, {
      method: 'POST',
      headers: getAuthHeaders(),
      body: JSON.stringify(data)
    });
    return response.json();
  },

  login: async (email: string, password: string) => {
    const response = await fetch(`${API_ENDPOINT}/auth/login`, {
      method: 'POST',
      headers: getAuthHeaders(),
      body: JSON.stringify({ email, password })
    });
    return response.json();
  },

  getProfile: async (email: string) => {
    const response = await fetch(`${API_ENDPOINT}/auth/profile?email=${email}`, {
      method: 'GET',
      headers: getAuthHeaders()
    });
    return response.json();
  },

  updateProfile: async (data: any) => {
    const response = await fetch(`${API_ENDPOINT}/auth/profile`, {
      method: 'PUT',
      headers: getAuthHeaders(),
      body: JSON.stringify(data)
    });
    return response.json();
  },

  getDoctors: async () => {
    const response = await fetch(`${API_ENDPOINT}/auth/doctors`, {
      method: 'GET',
      headers: getAuthHeaders()
    });
    return response.json();
  },

  getPatients: async () => {
    const response = await fetch(`${API_ENDPOINT}/auth/patients`, {
      method: 'GET',
      headers: getAuthHeaders()
    });
    return response.json();
  }
};

// Appointment APIs
export const appointmentAPI = {
  book: async (data: {
    patient_id: string;
    doctor_id: string;
    date: string;
    time: string;
    reason: string;
  }) => {
    const response = await fetch(`${API_ENDPOINT}/appointments/book`, {
      method: 'POST',
      headers: getAuthHeaders(),
      body: JSON.stringify(data)
    });
    return response.json();
  },

  getAll: async () => {
    const response = await fetch(`${API_ENDPOINT}/appointments`, {
      method: 'GET',
      headers: getAuthHeaders()
    });
    return response.json();
  },

  getByPatient: async (patient_id: string) => {
    const response = await fetch(`${API_ENDPOINT}/appointments/patient?patient_id=${patient_id}`, {
      method: 'GET',
      headers: getAuthHeaders()
    });
    return response.json();
  },

  getByDoctor: async (doctor_id: string) => {
    const response = await fetch(`${API_ENDPOINT}/appointments/doctor?doctor_id=${doctor_id}`, {
      method: 'GET',
      headers: getAuthHeaders()
    });
    return response.json();
  }
};

// Clinical Note APIs
export const clinicalAPI = {
  generateSOAP: async (data: {
    clinical_data: string;
    patient_id?: string;
    doctor_id?: string;
  }) => {
    const response = await fetch(`${API_ENDPOINT}/clinical/generate`, {
      method: 'POST',
      headers: getAuthHeaders(),
      body: JSON.stringify(data)
    });
    return response.json();
  }
};

// Patient History APIs
export const historyAPI = {
  getPatientHistory: async (patient_id: string) => {
    const response = await fetch(`${API_ENDPOINT}/history/patient?patient_id=${patient_id}`, {
      method: 'GET',
      headers: getAuthHeaders()
    });
    return response.json();
  },

  getTimeline: async (patient_id: string) => {
    const response = await fetch(`${API_ENDPOINT}/history/timeline?patient_id=${patient_id}`, {
      method: 'GET',
      headers: getAuthHeaders()
    });
    return response.json();
  },

  getClinicalNotes: async (patient_id: string) => {
    const response = await fetch(`${API_ENDPOINT}/history/notes?patient_id=${patient_id}`, {
      method: 'GET',
      headers: getAuthHeaders()
    });
    return response.json();
  },

  getAppointments: async (patient_id: string) => {
    const response = await fetch(`${API_ENDPOINT}/history/appointments?patient_id=${patient_id}`, {
      method: 'GET',
      headers: getAuthHeaders()
    });
    return response.json();
  }
};

// Insurance APIs
export const insuranceAPI = {
  analyze: async (data: {
    policy_key: string;
    procedure_code: string;
    provider_network?: any;
    patient_id: string;
  }) => {
    const response = await fetch(`${API_ENDPOINT}/insurance/analyze`, {
      method: 'POST',
      headers: getAuthHeaders(),
      body: JSON.stringify(data)
    });
    return response.json();
  }
};

// Chatbot APIs
export const chatAPI = {
  sendMessage: async (query: string, user_id: string) => {
    const response = await fetch(`${API_ENDPOINT}/chat`, {
      method: 'POST',
      headers: getAuthHeaders(),
      body: JSON.stringify({ query, user_id })
    });
    return response.json();
  }
};

export default {
  authAPI,
  appointmentAPI,
  clinicalAPI,
  historyAPI,
  insuranceAPI,
  chatAPI
};
