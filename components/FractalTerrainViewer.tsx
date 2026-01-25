'use client';

/**
 * Fractal Terrain Viewer Component
 * React wrapper for the terrain renderer with interactive controls
 */

import { useEffect, useRef, useState } from 'react';
import { TerrainRenderer } from '@/engine/terrain-renderer';
import { ViewLevel } from '@/types/chunk';

export default function FractalTerrainViewer() {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const rendererRef = useRef<TerrainRenderer | null>(null);
  const [stats, setStats] = useState({
    currentDepth: 0,
    targetDepth: 0,
    transitionProgress: 1,
    viewLevel: ViewLevel.ORBITAL,
    visibleChunks: 0,
    cameraAltitude: 300,
    meshCount: 0,
    fps: 0,
  });

  useEffect(() => {
    if (!canvasRef.current) return;

    // Initialize renderer
    const renderer = new TerrainRenderer({
      canvas: canvasRef.current,
      initialAltitude: 300,
      enableStats: true,
    });

    rendererRef.current = renderer;
    renderer.start();

    // Update stats every second
    const statsInterval = setInterval(() => {
      const currentStats = renderer.getStats();
      setStats(currentStats);
    }, 1000);

    // Keyboard controls
    const handleKeyDown = (e: KeyboardEvent) => {
      switch (e.key) {
        case 'ArrowUp':
        case 'w':
        case 'W':
          renderer.zoomIn();
          break;
        case 'ArrowDown':
        case 's':
        case 'S':
          renderer.zoomOut();
          break;
        case '0':
          renderer.zoomToDepth(0);
          break;
        case '1':
          renderer.zoomToDepth(1);
          break;
        case '2':
          renderer.zoomToDepth(2);
          break;
        case '3':
          renderer.zoomToDepth(3);
          break;
        case '4':
          renderer.zoomToDepth(4);
          break;
        case '5':
          renderer.zoomToDepth(5);
          break;
        case '6':
          renderer.zoomToDepth(6);
          break;
      }
    };

    window.addEventListener('keydown', handleKeyDown);

    // Cleanup
    return () => {
      clearInterval(statsInterval);
      window.removeEventListener('keydown', handleKeyDown);
      renderer.dispose();
    };
  }, []);

  const handleZoomIn = () => {
    rendererRef.current?.zoomIn();
  };

  const handleZoomOut = () => {
    rendererRef.current?.zoomOut();
  };

  const handleDepthChange = (depth: number) => {
    rendererRef.current?.zoomToDepth(depth);
  };

  return (
    <div className="relative w-full h-screen bg-black">
      <canvas ref={canvasRef} className="w-full h-full" />

      {/* Controls Overlay */}
      <div className="absolute top-4 left-4 bg-black/80 text-white p-4 rounded-lg font-mono text-sm space-y-2">
        <div className="text-lg font-bold mb-2">Lucidia Earth - Fractal Terrain</div>

        {/* Stats */}
        <div className="space-y-1">
          <div>Depth: {stats.currentDepth} ({stats.viewLevel})</div>
          <div>Altitude: {stats.cameraAltitude.toFixed(1)}m</div>
          <div>Chunks: {stats.visibleChunks}</div>
          <div>Meshes: {stats.meshCount}</div>
          <div>FPS: {stats.fps}</div>
        </div>

        {/* Depth Buttons */}
        <div className="pt-2 border-t border-white/20">
          <div className="text-xs mb-1">Depth Levels:</div>
          <div className="grid grid-cols-7 gap-1">
            {[0, 1, 2, 3, 4, 5, 6].map((depth) => (
              <button
                key={depth}
                onClick={() => handleDepthChange(depth)}
                className={`px-2 py-1 rounded text-xs ${
                  stats.currentDepth === depth
                    ? 'bg-white text-black'
                    : 'bg-white/20 hover:bg-white/40'
                }`}
              >
                {depth}
              </button>
            ))}
          </div>
          <div className="text-xs mt-1 text-white/60">
            0=Orbital, 1=Continental, 2=Regional, 3=Country, 4=State, 5=Local, 6=Ground
          </div>
        </div>

        {/* Zoom Controls */}
        <div className="pt-2 border-t border-white/20 space-y-1">
          <div className="text-xs mb-1">Controls:</div>
          <div className="flex gap-2">
            <button
              onClick={handleZoomIn}
              className="px-3 py-1 bg-white/20 hover:bg-white/40 rounded text-xs"
            >
              Zoom In ↑
            </button>
            <button
              onClick={handleZoomOut}
              className="px-3 py-1 bg-white/20 hover:bg-white/40 rounded text-xs"
            >
              Zoom Out ↓
            </button>
          </div>
          <div className="text-xs text-white/60">
            Keyboard: W/S or ↑/↓ to zoom, 0-6 for depth
          </div>
        </div>
      </div>

      {/* Legend */}
      <div className="absolute bottom-4 right-4 bg-black/80 text-white p-3 rounded-lg font-mono text-xs max-w-xs">
        <div className="font-bold mb-1">PS-SHA∞ Fractal Terrain</div>
        <div className="text-white/80">
          • Deterministic generation using hash chains
          <br />
          • 64×64 recursive subdivision
          <br />
          • cells(d) = 4096^d blocks
          <br />
          • Ground level (d=6) = ~1m² per cell
          <br />• Biome-constrained feature placement
        </div>
      </div>
    </div>
  );
}
