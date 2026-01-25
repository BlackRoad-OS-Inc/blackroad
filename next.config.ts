import type { NextConfig } from "next";
import nextra from 'nextra';

const withNextra = nextra({
  defaultShowCopyCode: true,
  latex: true,
});

const nextConfig: NextConfig = {
  output: 'standalone',
  // Optimize for documentation
  experimental: {
    optimizePackageImports: ['nextra-theme-docs'],
  },
};

export default withNextra(nextConfig);
