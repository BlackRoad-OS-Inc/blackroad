export class SearchService {
    constructor(mapManager) {
        this.mapManager = mapManager;
        this.geocodeEndpoint = 'https://nominatim.openstreetmap.org/search';
    }

    async search(query) {
        if (!query || !query.trim()) {
            return { success: false, error: 'Empty query' };
        }

        try {
            const response = await fetch(
                `${this.geocodeEndpoint}?format=json&q=${encodeURIComponent(query)}&limit=1`
            );
            const data = await response.json();

            if (data && data.length > 0) {
                const result = data[0];
                return {
                    success: true,
                    lat: parseFloat(result.lat),
                    lon: parseFloat(result.lon),
                    name: result.display_name.split(',')[0],
                    displayName: result.display_name,
                    type: result.type,
                    zoom: this.getZoomForType(result.type)
                };
            }

            return { success: false, error: 'Location not found' };
        } catch (err) {
            console.error('Search error:', err);
            return { success: false, error: err.message };
        }
    }

    getZoomForType(type) {
        const zoomMap = {
            'country': 5,
            'state': 7,
            'city': 12,
            'town': 12,
            'suburb': 15,
            'neighbourhood': 15,
            'building': 18,
            'default': 17
        };

        return zoomMap[type] || zoomMap.default;
    }

    flyToResult(result) {
        if (!result.success) return;

        this.mapManager.flyTo({
            center: [result.lon, result.lat],
            zoom: result.zoom,
            pitch: result.zoom > 15 ? 45 : 0,
            duration: 2500
        });

        return result;
    }
}
