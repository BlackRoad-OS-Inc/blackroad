import express from 'express';
const app = express();
app.get('/health', (req, res) => res.json({ service: 'roadbackups', status: 'ok' }));
app.listen(3000, () => console.log('🖤 roadbackups running'));
export default app;
