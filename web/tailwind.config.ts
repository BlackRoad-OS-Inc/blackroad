import type { Config } from 'tailwindcss'

const config: Config = {
  content: [
    './pages/**/*.{js,ts,jsx,tsx,mdx}',
    './components/**/*.{js,ts,jsx,tsx,mdx}',
    './app/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    extend: {
      colors: {
        // BlackRoad brand colors
        brand: {
          orange: '#FF9D00',
          'orange-dark': '#FF6B00',
          pink: '#FF0066',
          'pink-dark': '#FF006B',
          purple: '#D600AA',
          violet: '#7700FF',
          blue: '#0066FF',
        },
        // Semantic colors
        primary: {
          50: '#fff7ed',
          100: '#ffedd5',
          200: '#fed7aa',
          300: '#fdba74',
          400: '#fb923c',
          500: '#FF9D00',
          600: '#FF6B00',
          700: '#c2410c',
          800: '#9a3412',
          900: '#7c2d12',
        },
      },
      backgroundImage: {
        'gradient-radial': 'radial-gradient(var(--tw-gradient-stops))',
        'gradient-brand': 'linear-gradient(135deg, #FF9D00 0%, #FF0066 50%, #7700FF 100%)',
        'gradient-dark': 'linear-gradient(180deg, #0a0a0a 0%, #1a1a2e 100%)',
      },
      animation: {
        'fade-in': 'fadeIn 0.5s ease-in-out',
        'slide-up': 'slideUp 0.5s ease-out',
        'pulse-slow': 'pulse 3s cubic-bezier(0.4, 0, 0.6, 1) infinite',
        'glow': 'glow 2s ease-in-out infinite alternate',
      },
      keyframes: {
        fadeIn: {
          '0%': { opacity: '0' },
          '100%': { opacity: '1' },
        },
        slideUp: {
          '0%': { transform: 'translateY(20px)', opacity: '0' },
          '100%': { transform: 'translateY(0)', opacity: '1' },
        },
        glow: {
          '0%': { boxShadow: '0 0 20px rgba(255, 157, 0, 0.3)' },
          '100%': { boxShadow: '0 0 40px rgba(255, 0, 102, 0.5)' },
        },
      },
    },
  },
  plugins: [require('tailwindcss-animate')],
}

export default config
