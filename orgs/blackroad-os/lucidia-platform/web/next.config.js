/** @type {import('next').NextConfig} */
const nextConfig = {
  output: 'export',
  reactStrictMode: true,
  images: {
    domains: ['lucidia.ai', 'api.lucidia.ai'],
    unoptimized: true,
  },
  trailingSlash: true,
}

module.exports = nextConfig
