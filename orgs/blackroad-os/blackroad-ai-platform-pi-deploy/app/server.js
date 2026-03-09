const http = require('http');
const PORT = process.env.PORT || 3000;
const PI_NAME = process.env.PI_NAME || 'unknown';
const SERVICE_NAME = process.env.SERVICE_NAME || 'blackroad-ai-platform';

const server = http.createServer((req, res) => {
    if (req.url === '/health') {
        res.writeHead(200, {'Content-Type': 'application/json'});
        res.end(JSON.stringify({status: 'healthy'}));
    } else {
        res.writeHead(200, {'Content-Type': 'application/json'});
        res.end(JSON.stringify({
            service: SERVICE_NAME,
            description: 'AI Platform API',
            pi: PI_NAME,
            status: 'running',
            port: PORT,
            uptime: process.uptime(),
            timestamp: new Date().toISOString()
        }));
    }
});

server.listen(PORT, '0.0.0.0', () => {
    console.log(`🥧 ${SERVICE_NAME} running on ${PI_NAME}:${PORT}`);
    console.log(`🔗 Access: http://${PI_NAME}:${PORT}`);
});
