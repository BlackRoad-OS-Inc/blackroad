import express from 'express';
const app = express();
app.get('/health', (req, res) => res.json({ service: 'roadhealth', status: 'ok' }));
app.listen(3000, () => console.log('🖤 roadhealth running'));
export default app;
