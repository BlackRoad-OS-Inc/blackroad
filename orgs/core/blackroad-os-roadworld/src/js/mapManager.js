import { STYLES, MAP_CONFIG, FOG_CONFIG } from './config.js';

export class MapManager {
    constructor(containerId) {
        this.map = null;
        this.containerId = containerId;
        this.currentStyle = 'satellite';
        this.show3DBuildings = false;
        this.markers = [];
    }

    async init() {
        this.map = new maplibregl.Map({
            container: this.containerId,
            style: STYLES.satellite,
            ...MAP_CONFIG
        });

        this.map.on('style.load', () => {
            this.setFog('default');
        });

        return new Promise((resolve) => {
            this.map.on('load', () => {
                resolve(this.map);
            });
        });
    }

    setFog(type = 'default') {
        const fogConfig = FOG_CONFIG[type] || FOG_CONFIG.default;
        this.map.setFog(fogConfig);
    }

    changeStyle(styleName) {
        if (!STYLES[styleName]) return;

        // Save current position
        const center = this.map.getCenter();
        const zoom = this.map.getZoom();
        const pitch = this.map.getPitch();
        const bearing = this.map.getBearing();

        this.map.setStyle(STYLES[styleName]);

        // Restore position after style loads
        this.map.once('style.load', () => {
            this.map.jumpTo({ center, zoom, pitch, bearing });
            this.setFog(styleName === 'dark' ? 'dark' : 'default');
        });

        this.currentStyle = styleName;
    }

    flyTo(options) {
        this.map.flyTo(options);
    }

    easeTo(options) {
        this.map.easeTo(options);
    }

    zoomIn(duration = 300) {
        this.map.zoomIn({ duration });
    }

    zoomOut(duration = 300) {
        this.map.zoomOut({ duration });
    }

    getZoom() {
        return this.map.getZoom();
    }

    getCenter() {
        return this.map.getCenter();
    }

    getPitch() {
        return this.map.getPitch();
    }

    getBearing() {
        return this.map.getBearing();
    }

    on(event, handler) {
        this.map.on(event, handler);
    }

    addMarker(lngLat, options = {}) {
        const marker = new maplibregl.Marker(options)
            .setLngLat(lngLat)
            .addTo(this.map);

        this.markers.push(marker);
        return marker;
    }

    clearMarkers() {
        this.markers.forEach(marker => marker.remove());
        this.markers = [];
    }

    addPopup(lngLat, html) {
        return new maplibregl.Popup()
            .setLngLat(lngLat)
            .setHTML(html)
            .addTo(this.map);
    }
}
