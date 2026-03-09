import express from 'express';
const app = express();
app.get('/health', (req, res) => res.json({ service: 'roadlocalize', status: 'ok' }));
app.listen(3000, () => console.log('🖤 roadlocalize running'));
export default app;
