export class MeasurementTools {
    constructor(mapManager) {
        this.mapManager = mapManager;
        this.mode = null; // 'distance', 'area', null
        this.points = [];
        this.markers = [];
        this.lineSourceId = 'measurement-line';
        this.polygonSourceId = 'measurement-polygon';
        this.setupSources();
    }

    setupSources() {
        const map = this.mapManager.map;

        // Add line source and layer for distance measurement
        if (!map.getSource(this.lineSourceId)) {
            map.addSource(this.lineSourceId, {
                type: 'geojson',
                data: {
                    type: 'Feature',
                    geometry: {
                        type: 'LineString',
                        coordinates: []
                    }
                }
            });

            map.addLayer({
                id: 'measurement-line-layer',
                type: 'line',
                source: this.lineSourceId,
                paint: {
                    'line-color': '#00d4ff',
                    'line-width': 3,
                    'line-dasharray': [2, 2]
                }
            });
        }

        // Add polygon source and layer for area measurement
        if (!map.getSource(this.polygonSourceId)) {
            map.addSource(this.polygonSourceId, {
                type: 'geojson',
                data: {
                    type: 'Feature',
                    geometry: {
                        type: 'Polygon',
                        coordinates: [[]]
                    }
                }
            });

            map.addLayer({
                id: 'measurement-polygon-layer',
                type: 'fill',
                source: this.polygonSourceId,
                paint: {
                    'fill-color': '#00d4ff',
                    'fill-opacity': 0.2
                }
            });

            map.addLayer({
                id: 'measurement-polygon-outline',
                type: 'line',
                source: this.polygonSourceId,
                paint: {
                    'line-color': '#00d4ff',
                    'line-width': 2
                }
            });
        }
    }

    startDistance() {
        this.clear();
        this.mode = 'distance';
        this.points = [];
        this.enableClickHandler();
    }

    startArea() {
        this.clear();
        this.mode = 'area';
        this.points = [];
        this.enableClickHandler();
    }

    enableClickHandler() {
        const map = this.mapManager.map;
        map.getCanvas().style.cursor = 'crosshair';

        this.clickHandler = (e) => {
            const coords = [e.lngLat.lng, e.lngLat.lat];
            this.addPoint(coords);
        };

        map.on('click', this.clickHandler);
    }

    addPoint(coords) {
        this.points.push(coords);

        // Add marker
        const el = document.createElement('div');
        el.className = 'measurement-marker';
        el.innerHTML = `<div class="measurement-marker-dot">${this.points.length}</div>`;

        const marker = new maplibregl.Marker({ element: el })
            .setLngLat(coords)
            .addTo(this.mapManager.map);

        this.markers.push(marker);

        this.updateMeasurement();
    }

    updateMeasurement() {
        if (this.mode === 'distance') {
            this.updateDistance();
        } else if (this.mode === 'area') {
            this.updateArea();
        }
    }

    updateDistance() {
        const map = this.mapManager.map;
        const source = map.getSource(this.lineSourceId);

        if (source) {
            source.setData({
                type: 'Feature',
                geometry: {
                    type: 'LineString',
                    coordinates: this.points
                }
            });
        }

        if (this.points.length >= 2) {
            const distance = this.calculateTotalDistance();
            return distance;
        }
    }

    updateArea() {
        const map = this.mapManager.map;
        const source = map.getSource(this.polygonSourceId);

        if (source && this.points.length >= 3) {
            // Close the polygon
            const polygonCoords = [...this.points, this.points[0]];

            source.setData({
                type: 'Feature',
                geometry: {
                    type: 'Polygon',
                    coordinates: [polygonCoords]
                }
            });

            const area = this.calculateArea();
            return area;
        }
    }

    calculateTotalDistance() {
        let total = 0;
        for (let i = 0; i < this.points.length - 1; i++) {
            total += this.calculateDistance(this.points[i], this.points[i + 1]);
        }
        return total;
    }

    calculateDistance(coord1, coord2) {
        // Haversine formula
        const R = 6371e3; // Earth's radius in meters
        const φ1 = coord1[1] * Math.PI / 180;
        const φ2 = coord2[1] * Math.PI / 180;
        const Δφ = (coord2[1] - coord1[1]) * Math.PI / 180;
        const Δλ = (coord2[0] - coord1[0]) * Math.PI / 180;

        const a = Math.sin(Δφ / 2) * Math.sin(Δφ / 2) +
                  Math.cos(φ1) * Math.cos(φ2) *
                  Math.sin(Δλ / 2) * Math.sin(Δλ / 2);
        const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

        return R * c; // Distance in meters
    }

    calculateArea() {
        if (this.points.length < 3) return 0;

        // Calculate area using shoelace formula (approximation for small areas)
        const R = 6371e3; // Earth's radius in meters
        let area = 0;

        for (let i = 0; i < this.points.length; i++) {
            const j = (i + 1) % this.points.length;
            const xi = this.points[i][0] * Math.PI / 180;
            const yi = this.points[i][1] * Math.PI / 180;
            const xj = this.points[j][0] * Math.PI / 180;
            const yj = this.points[j][1] * Math.PI / 180;

            area += xi * Math.sin(yj) - xj * Math.sin(yi);
        }

        area = Math.abs(area * R * R / 2);
        return area;
    }

    formatDistance(meters) {
        if (meters < 1000) {
            return `${meters.toFixed(1)} m`;
        } else if (meters < 10000) {
            return `${(meters / 1000).toFixed(2)} km`;
        } else {
            return `${(meters / 1000).toFixed(1)} km`;
        }
    }

    formatArea(sqMeters) {
        if (sqMeters < 10000) {
            return `${sqMeters.toFixed(1)} m²`;
        } else if (sqMeters < 1000000) {
            return `${(sqMeters / 10000).toFixed(2)} hectares`;
        } else {
            return `${(sqMeters / 1000000).toFixed(2)} km²`;
        }
    }

    clear() {
        const map = this.mapManager.map;

        // Remove markers
        this.markers.forEach(marker => marker.remove());
        this.markers = [];

        // Clear points
        this.points = [];

        // Clear line
        const lineSource = map.getSource(this.lineSourceId);
        if (lineSource) {
            lineSource.setData({
                type: 'Feature',
                geometry: {
                    type: 'LineString',
                    coordinates: []
                }
            });
        }

        // Clear polygon
        const polygonSource = map.getSource(this.polygonSourceId);
        if (polygonSource) {
            polygonSource.setData({
                type: 'Feature',
                geometry: {
                    type: 'Polygon',
                    coordinates: [[]]
                }
            });
        }

        // Remove click handler
        if (this.clickHandler) {
            map.off('click', this.clickHandler);
            map.getCanvas().style.cursor = '';
        }

        this.mode = null;
    }

    getResults() {
        if (this.mode === 'distance' && this.points.length >= 2) {
            const distance = this.calculateTotalDistance();
            return {
                type: 'distance',
                value: distance,
                formatted: this.formatDistance(distance),
                points: this.points.length
            };
        } else if (this.mode === 'area' && this.points.length >= 3) {
            const area = this.calculateArea();
            return {
                type: 'area',
                value: area,
                formatted: this.formatArea(area),
                points: this.points.length
            };
        }
        return null;
    }
}
