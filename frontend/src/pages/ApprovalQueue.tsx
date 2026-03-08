import { Box, Typography, Paper, List } from '@mui/material';

const ApprovalQueue = () => {
  return (
    <Box>
      <Typography variant="h4" gutterBottom>
        Approval Queue
      </Typography>
      <Paper sx={{ p: 3 }}>
        <Typography variant="body2" color="text.secondary">
          No pending approvals
        </Typography>
        <List>
          {/* Approval items will be listed here */}
        </List>
      </Paper>
    </Box>
  );
};

export default ApprovalQueue;
