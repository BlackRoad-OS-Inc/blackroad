import express from 'express';
const app = express();
app.get('/health', (req, res) => res.json({ service: 'roadsessions', status: 'ok' }));
app.listen(3000, () => console.log('🖤 roadsessions running'));
export default app;
