import express from 'express';
const app = express();
app.get('/health', (req, res) => res.json({ service: 'roadfiles', status: 'ok' }));
app.listen(3000, () => console.log('🖤 roadfiles running'));
export default app;
