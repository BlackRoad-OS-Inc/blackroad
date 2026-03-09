import express from 'express';
const app = express();
app.get('/health', (req, res) => res.json({ service: 'roadsecrets', status: 'ok' }));
app.listen(3000, () => console.log('🖤 roadsecrets running'));
export default app;
