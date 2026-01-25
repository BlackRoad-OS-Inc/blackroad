export class MarkerManager {
    constructor(mapManager, storageManager) {
        this.mapManager = mapManager;
        this.storageManager = storageManager;
        this.markers = new Map();
        this.markerCategories = {
            favorite: { color: '#FF6B00', icon: '⭐' },
            work: { color: '#0066FF', icon: '💼' },
            home: { color: '#FF0066', icon: '🏠' },
            travel: { color: '#7700FF', icon: '✈️' },
            food: { color: '#FF9D00', icon: '🍴' },
            custom: { color: '#00d4ff', icon: '📍' }
        };
    }

    addMarker(lngLat, options = {}) {
        const {
            category = 'custom',
            name = 'Unnamed Location',
            description = '',
            draggable = false
        } = options;

        const markerId = `marker_${Date.now()}`;
        const categoryInfo = this.markerCategories[category] || this.markerCategories.custom;

        // Create marker element
        const el = document.createElement('div');
        el.className = 'custom-marker';
        el.innerHTML = `
            <div class="marker-icon" style="background: ${categoryInfo.color};">
                ${categoryInfo.icon}
            </div>
        `;
        el.style.cursor = 'pointer';

        // Create popup
        const popup = new maplibregl.Popup({ offset: 25 }).setHTML(`
            <div class="marker-popup">
                <div class="marker-popup-header">${name}</div>
                <div class="marker-popup-category">${category}</div>
                ${description ? `<div class="marker-popup-desc">${description}</div>` : ''}
                <div class="marker-popup-coords">${lngLat[1].toFixed(6)}, ${lngLat[0].toFixed(6)}</div>
                <button class="marker-delete-btn" data-marker-id="${markerId}">Delete</button>
            </div>
        `);

        // Create marker
        const marker = new maplibregl.Marker({
            element: el,
            draggable: draggable
        })
            .setLngLat(lngLat)
            .setPopup(popup)
            .addTo(this.mapManager.map);

        // Store marker data
        this.markers.set(markerId, {
            marker,
            data: {
                id: markerId,
                lngLat,
                category,
                name,
                description,
                createdAt: new Date().toISOString()
            }
        });

        // Save to storage
        this.saveMarkersToStorage();

        // Setup delete handler
        popup.on('open', () => {
            const deleteBtn = document.querySelector(`[data-marker-id="${markerId}"]`);
            if (deleteBtn) {
                deleteBtn.addEventListener('click', () => {
                    this.removeMarker(markerId);
                    popup.remove();
                });
            }
        });

        return markerId;
    }

    removeMarker(markerId) {
        const markerObj = this.markers.get(markerId);
        if (markerObj) {
            markerObj.marker.remove();
            this.markers.delete(markerId);
            this.saveMarkersToStorage();
        }
    }

    clearAllMarkers() {
        this.markers.forEach((markerObj) => {
            markerObj.marker.remove();
        });
        this.markers.clear();
        this.saveMarkersToStorage();
    }

    getMarkers() {
        const markerData = [];
        this.markers.forEach((markerObj) => {
            markerData.push(markerObj.data);
        });
        return markerData;
    }

    saveMarkersToStorage() {
        const markersData = this.getMarkers();
        this.storageManager.data.markers = markersData;
        this.storageManager.save();
    }

    loadMarkersFromStorage() {
        const markersData = this.storageManager.data.markers || [];
        markersData.forEach((markerData) => {
            this.addMarker(markerData.lngLat, {
                category: markerData.category,
                name: markerData.name,
                description: markerData.description
            });
        });
    }

    getMarkersByCategory(category) {
        const markers = [];
        this.markers.forEach((markerObj) => {
            if (markerObj.data.category === category) {
                markers.push(markerObj.data);
            }
        });
        return markers;
    }
}
