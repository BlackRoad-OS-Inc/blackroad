import express from 'express';
const app = express();
app.get('/health', (req, res) => res.json({ service: 'roadpermissions', status: 'ok' }));
app.listen(3000, () => console.log('🖤 roadpermissions running'));
export default app;
