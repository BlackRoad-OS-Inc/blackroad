import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  output: 'export',
  // Enable experimental features for better performance
  experimental: {
    optimizePackageImports: ['framer-motion'],
  },
};

export default nextConfig;
