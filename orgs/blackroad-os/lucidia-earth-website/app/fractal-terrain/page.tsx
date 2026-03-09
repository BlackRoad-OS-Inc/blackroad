/**
 * Fractal Terrain Page
 * Interactive viewer for PS-SHA∞ fractal terrain generation
 */

export const metadata = {
  title: 'Fractal Terrain - Lucidia Earth',
  description: 'Interactive fractal terrain generation with PS-SHA∞ deterministic seeds and 64×64 recursive subdivision',
};

export default function FractalTerrainPage() {
  return (
    <iframe
      src="/fractal-earth.html"
      className="w-full h-screen border-0"
      title="Lucidia Earth - Fractal Terrain"
    />
  );
}
