/**
 * PM2 Ecosystem Configuration
 *
 * Services on Octavia (192.168.4.38):
 *   - API Gateway (:3000)
 *   - Operator API (:3001)
 *   - Command Center (:3003)
 *   - Tools API (:3004)
 *   - Agents API (:3005)
 *   - Subdomain Router (:4000)
 *   - Info Server (:8090)
 *
 * Services on Cecilia (192.168.4.89):
 *   - Payment Gateway (:3002)
 *
 * Deploy to Octavia:
 *   scp -r phase4-services/ pi@192.168.4.38:/home/pi/blackroad-services/
 *   ssh pi@192.168.4.38 'cd /home/pi/blackroad-services && npm install && pm2 start ecosystem.config.cjs'
 *
 * Deploy Payment Gateway to Cecilia:
 *   scp -r phase4-services/{payment-gateway,adapters,package.json,tsconfig.json,.env} pi@192.168.4.89:/home/pi/blackroad-services/
 *   ssh pi@192.168.4.89 'cd /home/pi/blackroad-services && npm install && pm2 start ecosystem.config.cjs --only payment-gateway'
 */

const dotenv = require('dotenv');
dotenv.config();

module.exports = {
  apps: [
    // ── Tier 1: Critical API ──
    {
      name: 'api-gateway',
      script: 'npx',
      args: 'tsx api-gateway/server.ts',
      env: {
        PORT: 3000,
        NODE_ENV: 'production',
        PG_HOST: process.env.PG_HOST || '10.10.0.2',
        PG_PORT: process.env.PG_PORT || '5432',
        PG_USER: process.env.PG_USER || 'blackroad',
        PG_PASSWORD: process.env.PG_PASSWORD,
        REDIS_HOST: process.env.REDIS_HOST || '10.10.0.2',
        REDIS_PORT: process.env.REDIS_PORT || '6379',
        REDIS_PASSWORD: process.env.REDIS_PASSWORD,
      },
      max_memory_restart: '256M',
      instances: 1,
      autorestart: true,
      watch: false,
      error_file: '/home/pi/logs/api-gateway-error.log',
      out_file: '/home/pi/logs/api-gateway-out.log',
      merge_logs: true,
    },

    {
      name: 'payment-gateway',
      script: 'npx',
      args: 'tsx payment-gateway/server.ts',
      env: {
        PORT: 3002,
        NODE_ENV: 'production',
        PG_HOST: '127.0.0.1', // Local on Cecilia
        PG_PORT: '5432',
        PG_USER: process.env.PG_USER || 'blackroad',
        PG_PASSWORD: process.env.PG_PASSWORD,
        REDIS_HOST: '127.0.0.1',
        REDIS_PORT: '6379',
        REDIS_PASSWORD: process.env.REDIS_PASSWORD,
        STRIPE_SECRET_KEY: process.env.STRIPE_SECRET_KEY,
        STRIPE_PUBLISHABLE_KEY: process.env.STRIPE_PUBLISHABLE_KEY,
        STRIPE_WEBHOOK_SECRET: process.env.STRIPE_WEBHOOK_SECRET,
        STRIPE_PRICE_PRO_MONTHLY: process.env.STRIPE_PRICE_PRO_MONTHLY,
        STRIPE_PRICE_PRO_YEARLY: process.env.STRIPE_PRICE_PRO_YEARLY,
        STRIPE_PRICE_ENT_MONTHLY: process.env.STRIPE_PRICE_ENT_MONTHLY,
        STRIPE_PRICE_ENT_YEARLY: process.env.STRIPE_PRICE_ENT_YEARLY,
      },
      max_memory_restart: '256M',
      instances: 1,
      autorestart: true,
      watch: false,
      error_file: '/home/pi/logs/payment-gateway-error.log',
      out_file: '/home/pi/logs/payment-gateway-out.log',
      merge_logs: true,
    },

    // ── Subdomain Router ──
    {
      name: 'subdomain-router',
      script: 'npx',
      args: 'tsx subdomain-router/server.ts',
      env: {
        PORT: 4000,
        NODE_ENV: 'production',
        PG_HOST: process.env.PG_HOST || '10.10.0.2',
        PG_PASSWORD: process.env.PG_PASSWORD,
        REDIS_HOST: process.env.REDIS_HOST || '10.10.0.2',
        REDIS_PASSWORD: process.env.REDIS_PASSWORD,
      },
      max_memory_restart: '512M',
      instances: 1,
      autorestart: true,
      watch: false,
      error_file: '/home/pi/logs/subdomain-router-error.log',
      out_file: '/home/pi/logs/subdomain-router-out.log',
      merge_logs: true,
    },

    // ── Info Server (consolidated boilerplate workers) ──
    {
      name: 'info-server',
      script: 'npx',
      args: 'tsx info-server/server.ts',
      env: {
        PORT: 8090,
        NODE_ENV: 'production',
      },
      max_memory_restart: '128M',
      instances: 1,
      autorestart: true,
      watch: false,
    },
  ],
};
