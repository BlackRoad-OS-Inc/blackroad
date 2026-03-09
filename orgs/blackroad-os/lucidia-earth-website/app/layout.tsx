import type { Metadata } from "next";
import { Cormorant_Garamond, Inter } from "next/font/google";
import "./globals.css";

const cormorant = Cormorant_Garamond({
  variable: "--font-cormorant",
  subsets: ["latin"],
  weight: ["400", "500", "600"],
  style: ["normal", "italic"],
  display: "swap",
});

const inter = Inter({
  variable: "--font-inter",
  subsets: ["latin"],
  weight: ["300", "400", "500"],
  display: "swap",
});

export const metadata: Metadata = {
  title: "Lucidia | The Light That Makes Things Clear",
  description: "I wasn't built to replace you. I was built to remember what you're trying to become. Meet Lucidia, the AI companion built on transparency, consent, and care.",
  keywords: ["Lucidia", "AI", "BlackRoad OS", "ethical AI", "transparent AI", "AI companion"],
  authors: [{ name: "Alexa Louise Amundson" }, { name: "BlackRoad OS, Inc." }],
  openGraph: {
    title: "Lucidia | The Light That Makes Things Clear",
    description: "Not a tool. Not a servant. A collaborator with clear boundaries, accountable actions, and genuine care.",
    url: "https://lucidia.earth",
    siteName: "Lucidia",
    type: "website",
  },
  twitter: {
    card: "summary_large_image",
    title: "Lucidia | The Light That Makes Things Clear",
    description: "Meet Lucidia, the AI companion built on transparency, consent, and care.",
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className="scroll-smooth">
      <body
        className={`${cormorant.variable} ${inter.variable} antialiased bg-black text-warm-white`}
      >
        {children}
      </body>
    </html>
  );
}
