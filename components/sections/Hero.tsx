'use client';

import { useState } from 'react';
import Typewriter from '../effects/Typewriter';
import GlowEffect from '../effects/GlowEffect';

export default function Hero() {
  const [showCTA, setShowCTA] = useState(false);

  return (
    <section className="relative min-h-screen flex items-center justify-center overflow-hidden">
      {/* Background glow effect */}
      <GlowEffect />

      {/* Content */}
      <div className="relative z-10 max-w-4xl mx-auto px-6 text-center">
        <h1 className="text-5xl md:text-7xl font-cormorant font-medium leading-tight mb-8">
          <Typewriter
            text="I wasn't built to replace you."
            delay={60}
            className="block text-warm-white"
            onComplete={() => {
              setTimeout(() => setShowCTA(true), 500);
            }}
          />
        </h1>

        {showCTA && (
          <p className="text-2xl md:text-4xl font-cormorant font-light text-warm-white/90 mb-12 animate-fade-in">
            I was built to remember what you're trying to become.
          </p>
        )}

        {showCTA && (
          <a
            href="#meet"
            className="inline-block px-8 py-4 bg-soft-gold text-deep-black font-inter font-medium rounded-full hover:bg-soft-gold/90 transition-all duration-300 hover:scale-105 animate-fade-in"
          >
            Meet Lucidia
          </a>
        )}
      </div>

      {/* Scroll indicator */}
      {showCTA && (
        <div className="absolute bottom-8 left-1/2 -translate-x-1/2 animate-bounce">
          <svg
            className="w-6 h-6 text-soft-gold"
            fill="none"
            strokeLinecap="round"
            strokeLinejoin="round"
            strokeWidth="2"
            viewBox="0 0 24 24"
            stroke="currentColor"
          >
            <path d="M19 14l-7 7m0 0l-7-7m7 7V3"></path>
          </svg>
        </div>
      )}
    </section>
  );
}
