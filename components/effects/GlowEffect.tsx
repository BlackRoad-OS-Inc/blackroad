'use client';

import { motion } from 'framer-motion';

interface GlowEffectProps {
  className?: string;
}

export default function GlowEffect({ className = '' }: GlowEffectProps) {
  return (
    <motion.div
      className={`absolute inset-0 bg-gradient-radial from-glow to-transparent opacity-20 pointer-events-none ${className}`}
      animate={{
        opacity: [0.1, 0.3, 0.1],
        scale: [0.8, 1.2, 0.8],
      }}
      transition={{
        duration: 8,
        repeat: Infinity,
        ease: "easeInOut",
      }}
    />
  );
}
