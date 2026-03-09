import express from 'express';
const app = express();
app.get('/health', (req, res) => res.json({ service: 'roadmigrations', status: 'ok' }));
app.listen(3000, () => console.log('🖤 roadmigrations running'));
export default app;
