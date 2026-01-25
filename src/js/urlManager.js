export class URLManager {
    constructor(mapManager) {
        this.mapManager = mapManager;
    }

    generateShareURL(options = {}) {
        const center = this.mapManager.getCenter();
        const zoom = this.mapManager.getZoom();
        const bearing = this.mapManager.getBearing();
        const pitch = this.mapManager.getPitch();

        const params = new URLSearchParams();
        params.set('lat', center.lat.toFixed(6));
        params.set('lng', center.lng.toFixed(6));
        params.set('zoom', zoom.toFixed(2));

        if (bearing !== 0) {
            params.set('bearing', bearing.toFixed(2));
        }

        if (pitch !== 0) {
            params.set('pitch', pitch.toFixed(2));
        }

        if (options.style) {
            params.set('style', options.style);
        }

        if (options.marker) {
            params.set('marker', '1');
        }

        const baseURL = window.location.origin + window.location.pathname;
        return `${baseURL}?${params.toString()}`;
    }

    loadFromURL() {
        const params = new URLSearchParams(window.location.search);

        const lat = parseFloat(params.get('lat'));
        const lng = parseFloat(params.get('lng'));
        const zoom = parseFloat(params.get('zoom'));
        const bearing = parseFloat(params.get('bearing')) || 0;
        const pitch = parseFloat(params.get('pitch')) || 0;
        const style = params.get('style');
        const hasMarker = params.get('marker') === '1';

        if (!isNaN(lat) && !isNaN(lng) && !isNaN(zoom)) {
            return {
                center: [lng, lat],
                zoom,
                bearing,
                pitch,
                style,
                hasMarker
            };
        }

        return null;
    }

    updateURL(silent = true) {
        const url = this.generateShareURL();

        if (silent) {
            window.history.replaceState({}, '', url);
        } else {
            window.history.pushState({}, '', url);
        }
    }

    copyToClipboard() {
        const url = this.generateShareURL();

        if (navigator.clipboard && navigator.clipboard.writeText) {
            return navigator.clipboard.writeText(url)
                .then(() => ({ success: true, url }))
                .catch(() => ({ success: false, url }));
        } else {
            // Fallback for older browsers
            const textArea = document.createElement('textarea');
            textArea.value = url;
            textArea.style.position = 'fixed';
            textArea.style.left = '-999999px';
            document.body.appendChild(textArea);
            textArea.select();

            try {
                document.execCommand('copy');
                document.body.removeChild(textArea);
                return Promise.resolve({ success: true, url });
            } catch (err) {
                document.body.removeChild(textArea);
                return Promise.resolve({ success: false, url });
            }
        }
    }

    generateEmbedCode(width = '100%', height = '600px') {
        const url = this.generateShareURL();
        return `<iframe src="${url}" width="${width}" height="${height}" style="border:0;" allowfullscreen="" loading="lazy"></iframe>`;
    }
}
