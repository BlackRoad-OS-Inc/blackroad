export class BuildingsManager {
    constructor(mapManager) {
        this.mapManager = mapManager;
        this.enabled = false;
        this.buildingsSourceId = 'osm-buildings';
        this.buildingsLayerId = '3d-buildings';
    }

    toggle() {
        if (this.enabled) {
            this.disable();
        } else {
            this.enable();
        }
        return this.enabled;
    }

    enable() {
        const map = this.mapManager.map;

        // Check if source already exists
        if (!map.getSource(this.buildingsSourceId)) {
            // Add OSM Buildings source
            map.addSource(this.buildingsSourceId, {
                type: 'vector',
                url: 'https://tiles.openfreemap.org/planet'
            });
        }

        // Check if layer already exists
        if (!map.getLayer(this.buildingsLayerId)) {
            map.addLayer({
                id: this.buildingsLayerId,
                type: 'fill-extrusion',
                source: this.buildingsSourceId,
                'source-layer': 'building',
                minzoom: 14,
                paint: {
                    'fill-extrusion-color': [
                        'interpolate',
                        ['linear'],
                        ['get', 'render_height'],
                        0, '#888',
                        50, '#666',
                        100, '#555',
                        200, '#444'
                    ],
                    'fill-extrusion-height': [
                        'interpolate',
                        ['linear'],
                        ['zoom'],
                        14, 0,
                        15, ['*', ['coalesce', ['get', 'render_height'], 5], 0.5],
                        16, ['coalesce', ['get', 'render_height'], 5]
                    ],
                    'fill-extrusion-base': [
                        'interpolate',
                        ['linear'],
                        ['zoom'],
                        14, 0,
                        15, ['*', ['coalesce', ['get', 'render_min_height'], 0], 0.5],
                        16, ['coalesce', ['get', 'render_min_height'], 0]
                    ],
                    'fill-extrusion-opacity': 0.7
                }
            });
        }

        this.enabled = true;
    }

    disable() {
        const map = this.mapManager.map;

        if (map.getLayer(this.buildingsLayerId)) {
            map.removeLayer(this.buildingsLayerId);
        }

        this.enabled = false;
    }

    isEnabled() {
        return this.enabled;
    }
}
