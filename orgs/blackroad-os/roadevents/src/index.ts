import express from 'express';
const app = express();
app.get('/health', (req, res) => res.json({ service: 'roadevents', status: 'ok' }));
app.listen(3000, () => console.log('🖤 roadevents running'));
export default app;
