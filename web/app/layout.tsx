import type { Metadata } from 'next'
import { Inter } from 'next/font/google'
import './globals.css'

const inter = Inter({ subsets: ['latin'] })

export const metadata: Metadata = {
  title: 'Lucidia - AI-Powered Learning That Actually Works',
  description: 'Upload a problem, get visual explanations, actually understand it. The end of technical barriers to learning.',
  keywords: ['AI tutor', 'homework help', 'math help', 'learning platform', 'education', 'visual learning'],
  authors: [{ name: 'BlackRoad OS' }],
  openGraph: {
    title: 'Lucidia - AI-Powered Learning',
    description: 'Upload a problem, get visual explanations, actually understand it.',
    url: 'https://lucidia.ai',
    siteName: 'Lucidia',
    images: [
      {
        url: '/og-image.png',
        width: 1200,
        height: 630,
        alt: 'Lucidia - AI-Powered Learning',
      },
    ],
    locale: 'en_US',
    type: 'website',
  },
  twitter: {
    card: 'summary_large_image',
    title: 'Lucidia - AI-Powered Learning',
    description: 'Upload a problem, get visual explanations, actually understand it.',
    images: ['/og-image.png'],
  },
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en" className="dark">
      <body className={`${inter.className} bg-black text-white antialiased`}>
        {children}
      </body>
    </html>
  )
}
