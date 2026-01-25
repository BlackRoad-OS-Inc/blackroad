export class StorageManager {
    constructor() {
        this.storageKey = 'blackroad_roadworld';
        this.data = this.load();
    }

    load() {
        try {
            const stored = localStorage.getItem(this.storageKey);
            return stored ? JSON.parse(stored) : this.getDefaultData();
        } catch (err) {
            console.error('Error loading storage:', err);
            return this.getDefaultData();
        }
    }

    save() {
        try {
            localStorage.setItem(this.storageKey, JSON.stringify(this.data));
            return true;
        } catch (err) {
            console.error('Error saving storage:', err);
            return false;
        }
    }

    getDefaultData() {
        return {
            savedLocations: [],
            markers: [],
            settings: {
                defaultStyle: 'satellite',
                show3DBuildings: false,
                lastPosition: {
                    center: [0, 20],
                    zoom: 1.5,
                    pitch: 0,
                    bearing: 0
                }
            },
            history: []
        };
    }

    saveLocation(location) {
        const newLocation = {
            id: Date.now(),
            name: location.name,
            lat: location.lat,
            lng: location.lng,
            zoom: location.zoom || 17,
            timestamp: new Date().toISOString()
        };

        this.data.savedLocations.push(newLocation);
        this.save();
        return newLocation;
    }

    getSavedLocations() {
        return this.data.savedLocations || [];
    }

    deleteLocation(id) {
        this.data.savedLocations = this.data.savedLocations.filter(loc => loc.id !== id);
        this.save();
    }

    savePosition(position) {
        this.data.settings.lastPosition = position;
        this.save();
    }

    getLastPosition() {
        return this.data.settings.lastPosition;
    }

    addToHistory(entry) {
        this.data.history.unshift({
            ...entry,
            timestamp: new Date().toISOString()
        });

        // Keep only last 50 entries
        if (this.data.history.length > 50) {
            this.data.history = this.data.history.slice(0, 50);
        }

        this.save();
    }

    getHistory() {
        return this.data.history || [];
    }

    updateSettings(settings) {
        this.data.settings = { ...this.data.settings, ...settings };
        this.save();
    }

    getSettings() {
        return this.data.settings;
    }
}
