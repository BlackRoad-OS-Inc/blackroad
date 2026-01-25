// Map tile styles configuration
export const STYLES = {
    satellite: {
        version: 8,
        name: 'Satellite',
        sources: {
            'satellite': {
                type: 'raster',
                tiles: [
                    'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
                ],
                tileSize: 256,
                maxzoom: 19,
                attribution: '© Esri'
            }
        },
        layers: [{
            id: 'satellite-layer',
            type: 'raster',
            source: 'satellite',
            minzoom: 0,
            maxzoom: 22
        }],
        glyphs: 'https://demotiles.maplibre.org/font/{fontstack}/{range}.pbf'
    },
    streets: {
        version: 8,
        name: 'Streets',
        sources: {
            'osm': {
                type: 'raster',
                tiles: [
                    'https://a.tile.openstreetmap.org/{z}/{x}/{y}.png',
                    'https://b.tile.openstreetmap.org/{z}/{x}/{y}.png',
                    'https://c.tile.openstreetmap.org/{z}/{x}/{y}.png'
                ],
                tileSize: 256,
                maxzoom: 19,
                attribution: '© OpenStreetMap'
            }
        },
        layers: [{
            id: 'osm-layer',
            type: 'raster',
            source: 'osm'
        }],
        glyphs: 'https://demotiles.maplibre.org/font/{fontstack}/{range}.pbf'
    },
    dark: {
        version: 8,
        name: 'Dark',
        sources: {
            'carto-dark': {
                type: 'raster',
                tiles: [
                    'https://a.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
                    'https://b.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
                    'https://c.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png'
                ],
                tileSize: 256,
                maxzoom: 20,
                attribution: '© CARTO'
            }
        },
        layers: [{
            id: 'carto-layer',
            type: 'raster',
            source: 'carto-dark'
        }],
        glyphs: 'https://demotiles.maplibre.org/font/{fontstack}/{range}.pbf'
    },
    terrain: {
        version: 8,
        name: 'Terrain',
        sources: {
            'stamen': {
                type: 'raster',
                tiles: [
                    'https://tiles.stadiamaps.com/tiles/stamen_terrain/{z}/{x}/{y}.jpg'
                ],
                tileSize: 256,
                maxzoom: 18,
                attribution: '© Stadia Maps'
            }
        },
        layers: [{
            id: 'stamen-layer',
            type: 'raster',
            source: 'stamen'
        }],
        glyphs: 'https://demotiles.maplibre.org/font/{fontstack}/{range}.pbf'
    },
    hybrid: {
        version: 8,
        name: 'Hybrid',
        sources: {
            'hybrid': {
                type: 'raster',
                tiles: [
                    'https://mt0.google.com/vt/lyrs=y&x={x}&y={y}&z={z}',
                    'https://mt1.google.com/vt/lyrs=y&x={x}&y={y}&z={z}'
                ],
                tileSize: 256,
                maxzoom: 21,
                attribution: '© Google'
            }
        },
        layers: [{
            id: 'hybrid-layer',
            type: 'raster',
            source: 'hybrid'
        }],
        glyphs: 'https://demotiles.maplibre.org/font/{fontstack}/{range}.pbf'
    }
};

// Map configuration
export const MAP_CONFIG = {
    center: [0, 20],
    zoom: 1.5,
    minZoom: 0,
    maxZoom: 22,
    projection: 'globe',
    antialias: true
};

// Fog configurations for different styles
export const FOG_CONFIG = {
    default: {
        color: 'rgb(186, 210, 235)',
        'high-color': 'rgb(36, 92, 223)',
        'horizon-blend': 0.02,
        'space-color': 'rgb(5, 5, 15)',
        'star-intensity': 0.6
    },
    dark: {
        color: 'rgb(20, 20, 30)',
        'high-color': 'rgb(10, 20, 50)',
        'horizon-blend': 0.02,
        'space-color': 'rgb(5, 5, 15)',
        'star-intensity': 0.6
    }
};

// 3D Buildings layer configuration
export const BUILDINGS_3D_LAYER = {
    id: '3d-buildings',
    source: 'openmaptiles',
    'source-layer': 'building',
    type: 'fill-extrusion',
    minzoom: 14,
    paint: {
        'fill-extrusion-color': '#aaa',
        'fill-extrusion-height': ['get', 'render_height'],
        'fill-extrusion-base': ['get', 'render_min_height'],
        'fill-extrusion-opacity': 0.6
    }
};
