import type { Metadata } from 'next'

export const metadata: Metadata = {
  title: 'BlackRoad Operator',
  description: 'Operator control panel for BlackRoad infrastructure management',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en">
      <body style={{
        margin: 0,
        fontFamily: '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif',
        backgroundColor: '#0a0a0a',
        color: '#e0e0e0'
      }}>
        {children}
      </body>
    </html>
  )
}
