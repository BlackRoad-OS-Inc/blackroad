/**
 * Genesis Earth Page
 * Planet generation using Smith Chart × Lo Shu × Spherical Harmonics
 */

export const metadata = {
  title: 'Genesis Earth - Lucidia',
  description: 'Mathematical planet generation using Smith Chart impedance mapping, Lo Shu magic square, and spherical harmonics',
};

export default function GenesisPage() {
  return (
    <iframe
      src="/genesis-earth.html"
      className="w-full h-screen border-0"
      title="Genesis Earth - Smith Chart × Lo Shu × Spherical Harmonics"
    />
  );
}
