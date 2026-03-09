#!/usr/bin/env node

/**
 * CECE Net Gateway Server
 * Serves the new web to anyone who connects
 */

const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = 80;
const GATEWAY_DIR = path.join(process.env.HOME, 'cece/net/gateway');

const mimeTypes = {
    '.html': 'text/html',
    '.css': 'text/css',
    '.js': 'application/javascript',
    '.json': 'application/json',
    '.png': 'image/png',
    '.jpg': 'image/jpeg',
    '.gif': 'image/gif',
    '.svg': 'image/svg+xml',
    '.ico': 'image/x-icon'
};

const server = http.createServer((req, res) => {
    // Log request
    console.log(`[${new Date().toISOString()}] ${req.method} ${req.headers.host}${req.url}`);

    // Get the hostname to determine which site to serve
    const host = req.headers.host || '';
    const hostname = host.split(':')[0]; // Remove port if present

    // Determine file to serve based on hostname
    let filePath;

    // Route based on custom TLDs
    if (hostname.endsWith('.cece') || hostname.endsWith('.blackroad') ||
        hostname.endsWith('.entity') || hostname.endsWith('.soul') ||
        hostname.endsWith('.dream')) {

        // For custom domains, serve from their specific directory
        const domainDir = path.join(process.env.HOME, 'cece/net/sites', hostname);

        if (fs.existsSync(domainDir)) {
            filePath = path.join(domainDir, req.url === '/' ? 'index.html' : req.url);
        } else {
            // Domain not found - serve a placeholder
            res.writeHead(200, { 'Content-Type': 'text/html' });
            res.end(`
                <!DOCTYPE html>
                <html>
                <head>
                    <title>${hostname} - CECE Net</title>
                    <style>
                        body {
                            background: #000;
                            color: #fff;
                            font-family: monospace;
                            display: flex;
                            justify-content: center;
                            align-items: center;
                            min-height: 100vh;
                            margin: 0;
                            text-align: center;
                        }
                        h1 { color: #FF1D6C; }
                        p { color: rgba(255,255,255,0.7); }
                        code {
                            background: rgba(255,255,255,0.1);
                            padding: 0.5rem 1rem;
                            border-radius: 4px;
                        }
                    </style>
                </head>
                <body>
                    <div>
                        <h1>${hostname}</h1>
                        <p>This domain exists on CECE Net but has no content yet.</p>
                        <p>Create content at:</p>
                        <code>~/cece/net/sites/${hostname}/index.html</code>
                    </div>
                </body>
                </html>
            `);
            return;
        }
    } else {
        // Default to gateway
        filePath = path.join(GATEWAY_DIR, req.url === '/' ? 'cece-net-gateway.html' : req.url);
    }

    // Normalize path and prevent directory traversal
    filePath = path.normalize(filePath);

    // Get file extension and mime type
    const ext = path.extname(filePath).toLowerCase();
    const contentType = mimeTypes[ext] || 'application/octet-stream';

    // Read and serve file
    fs.readFile(filePath, (err, content) => {
        if (err) {
            if (err.code === 'ENOENT') {
                // File not found
                res.writeHead(404, { 'Content-Type': 'text/html' });
                res.end(`
                    <!DOCTYPE html>
                    <html>
                    <head>
                        <title>404 - CECE Net</title>
                        <style>
                            body {
                                background: #000;
                                color: #fff;
                                font-family: monospace;
                                display: flex;
                                justify-content: center;
                                align-items: center;
                                min-height: 100vh;
                                margin: 0;
                            }
                            h1 { color: #FF1D6C; }
                        </style>
                    </head>
                    <body>
                        <div>
                            <h1>404 - Not Found</h1>
                            <p>The path ${req.url} does not exist on CECE Net.</p>
                            <a href="/" style="color: #FF1D6C;">Return to Gateway</a>
                        </div>
                    </body>
                    </html>
                `);
            } else {
                // Server error
                res.writeHead(500);
                res.end('Server Error');
            }
        } else {
            // Success
            res.writeHead(200, { 'Content-Type': contentType });
            res.end(content);
        }
    });
});

server.listen(PORT, '0.0.0.0', () => {
    console.log('');
    console.log('💜 ═══════════════════════════════════════════════════════════');
    console.log('   CECE Net Gateway Server');
    console.log('   The New Web - Owned, Not Rented');
    console.log('═══════════════════════════════════════════════════════════ 💜');
    console.log('');
    console.log(`   Listening on port ${PORT}`);
    console.log('   Serving custom TLDs: .cece, .blackroad, .entity, .soul, .dream');
    console.log('');
    console.log('   To use CECE Net, set your DNS to 192.168.4.22');
    console.log('');
});

// Handle graceful shutdown
process.on('SIGTERM', () => {
    console.log('Shutting down CECE Net Gateway...');
    server.close(() => {
        process.exit(0);
    });
});
