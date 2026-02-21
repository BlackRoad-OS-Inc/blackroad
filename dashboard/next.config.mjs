/** @type {import('next').NextConfig} */
const nextConfig = {
  output: 'standalone',
  poweredByHeader: false,
  compress: true,
  reactStrictMode: true,
  env: {
    SERVICE_NAME: process.env.SERVICE_NAME || 'blackroad-os-operator',
    SERVICE_ENV: process.env.SERVICE_ENV || 'development',
  },
}

export default nextConfig
