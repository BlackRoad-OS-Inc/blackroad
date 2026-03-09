import express from 'express';
const app = express();
app.get('/health', (req, res) => res.json({ service: 'roadpipeline', status: 'ok' }));
app.listen(3000, () => console.log('🖤 roadpipeline running'));
export default app;
