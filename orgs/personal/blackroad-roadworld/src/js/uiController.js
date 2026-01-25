export class UIController {
    constructor(mapManager) {
        this.mapManager = mapManager;
    }

    updateStats() {
        const zoom = this.mapManager.getZoom();
        const center = this.mapManager.getCenter();

        // Update zoom display
        this.updateElement('zoom-level', zoom.toFixed(1));

        // Update zoom bar
        const zoomPercent = Math.min(100, (zoom / 22) * 100);
        this.updateElement('zoom-fill', null, { width: zoomPercent + '%' });

        // Update altitude estimate
        const altitude = this.getAltitudeFromZoom(zoom);
        this.updateElement('altitude', this.formatAltitude(altitude));

        // Update resolution
        const resolution = this.getResolutionFromZoom(zoom);
        this.updateElement('resolution', resolution);

        // Update coordinates
        this.updateElement('coordinates',
            `${center.lat.toFixed(2)}°, ${center.lng.toFixed(2)}°`);
        this.updateElement('lat',
            `${Math.abs(center.lat).toFixed(6)}° ${center.lat >= 0 ? 'N' : 'S'}`);
        this.updateElement('lng',
            `${Math.abs(center.lng).toFixed(6)}° ${center.lng >= 0 ? 'E' : 'W'}`);

        // Update tile coords
        const tileX = Math.floor((center.lng + 180) / 360 * Math.pow(2, Math.floor(zoom)));
        const tileY = Math.floor((1 - Math.log(Math.tan(center.lat * Math.PI / 180) +
            1 / Math.cos(center.lat * Math.PI / 180)) / Math.PI) / 2 * Math.pow(2, Math.floor(zoom)));
        this.updateElement('tile-coords',
            `z${Math.floor(zoom)} / x${tileX} / y${tileY}`);

        // Update scale indicators
        this.updateScaleIndicators(zoom);

        // Update view mode
        this.updateElement('view-mode',
            zoom < 5 ? 'GLOBE VIEW' : zoom < 14 ? 'MAP VIEW' : 'STREET VIEW');
    }

    updateElement(id, text = null, styles = null) {
        const element = document.getElementById(id);
        if (!element) return;

        if (text !== null) {
            element.textContent = text;
        }

        if (styles) {
            Object.assign(element.style, styles);
        }
    }

    updateScaleIndicators(zoom) {
        document.querySelectorAll('.scale-item').forEach(item => {
            const min = parseFloat(item.dataset.min);
            const max = parseFloat(item.dataset.max);
            item.classList.toggle('active', zoom >= min && zoom < max);
        });
    }

    getAltitudeFromZoom(zoom) {
        // Approximate altitude in meters based on zoom level
        return 40075000 / Math.pow(2, zoom);
    }

    formatAltitude(meters) {
        if (meters > 1000000) return (meters / 1000000).toFixed(1) + ' Mm';
        if (meters > 1000) return (meters / 1000).toFixed(1) + ' km';
        if (meters > 1) return meters.toFixed(0) + ' m';
        return (meters * 100).toFixed(0) + ' cm';
    }

    getResolutionFromZoom(zoom) {
        const center = this.mapManager.getCenter();
        const metersPerPixel = 40075000 * Math.cos(center.lat * Math.PI / 180) /
            (Math.pow(2, zoom) * 256);

        if (metersPerPixel > 1000) return `~${(metersPerPixel/1000).toFixed(0)} km/px`;
        if (metersPerPixel > 1) return `~${metersPerPixel.toFixed(1)} m/px`;
        return `~${(metersPerPixel * 100).toFixed(0)} cm/px`;
    }
}
