import { configureStore } from '@reduxjs/toolkit';

// TODO: Add slices here as they are created
// import authReducer from './slices/authSlice';
// import patientReducer from './slices/patientSlice';

export const store = configureStore({
  reducer: {
    // auth: authReducer,
    // patient: patientReducer,
  },
});

export type RootState = ReturnType<typeof store.getState>;
export type AppDispatch = typeof store.dispatch;
