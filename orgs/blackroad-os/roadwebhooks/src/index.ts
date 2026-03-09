import express from 'express';
const app = express();
app.get('/health', (req, res) => res.json({ service: 'roadwebhooks', status: 'ok' }));
app.listen(3000, () => console.log('🖤 roadwebhooks running'));
export default app;
