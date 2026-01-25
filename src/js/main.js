import { MapManager } from './mapManager.js';
import { UIController } from './uiController.js';
import { SearchService } from './searchService.js';
import { StorageManager } from './storageManager.js';
import { BuildingsManager } from './buildingsManager.js';
import { MarkerManager } from './markerManager.js';
import { MeasurementTools } from './measurementTools.js';
import { URLManager } from './urlManager.js';
import { GameEngine } from './gameEngine.js';
import { PlayerAvatar } from './playerAvatar.js';
import { CollectiblesRenderer } from './collectiblesRenderer.js';

class RoadWorldApp {
    constructor() {
        this.mapManager = null;
        this.uiController = null;
        this.searchService = null;
        this.storageManager = null;
        this.buildingsManager = null;
        this.markerManager = null;
        this.measurementTools = null;
        this.urlManager = null;

        // Game components
        this.gameEngine = null;
        this.playerAvatar = null;
        this.collectiblesRenderer = null;
        this.gameActive = false;
    }

    async init() {
        // Initialize managers
        this.storageManager = new StorageManager();
        this.mapManager = new MapManager('map');
        await this.mapManager.init();

        this.uiController = new UIController(this.mapManager);
        this.searchService = new SearchService(this.mapManager);
        this.buildingsManager = new BuildingsManager(this.mapManager);
        this.markerManager = new MarkerManager(this.mapManager, this.storageManager);
        this.measurementTools = new MeasurementTools(this.mapManager);
        this.urlManager = new URLManager(this.mapManager);

        // Setup event listeners
        this.setupMapEvents();
        this.setupControls();
        this.setupSearch();
        this.setupLayers();
        this.setupQuickLocations();
        this.setupPanels();
        this.setupTools();

        // Initial UI update
        this.uiController.updateStats();
        this.updateSavedCount();

        // Check URL params first
        const urlParams = this.urlManager.loadFromURL();
        if (urlParams) {
            this.mapManager.map.jumpTo(urlParams);
            if (urlParams.style) {
                // Will be handled by style change
            }
        } else {
            // Load last position if available
            const lastPosition = this.storageManager.getLastPosition();
            if (lastPosition && lastPosition.center) {
                this.mapManager.map.jumpTo(lastPosition);
            }
        }

        // Load saved markers
        this.markerManager.loadMarkersFromStorage();

        // Initialize game engine (but don't activate yet)
        this.gameEngine = new GameEngine(this.mapManager, this.storageManager);
        this.playerAvatar = new PlayerAvatar(this.mapManager, this.gameEngine);
        this.collectiblesRenderer = new CollectiblesRenderer(this.mapManager, this.gameEngine);

        // Setup game toggle
        this.setupGameToggle();

        console.log('RoadWorld initialized');
    }

    setupGameToggle() {
        const toggle = document.getElementById('game-toggle');

        toggle.addEventListener('click', () => {
            this.gameActive = !this.gameActive;

            if (this.gameActive) {
                this.activateGameMode();
                toggle.classList.add('active');
            } else {
                this.deactivateGameMode();
                toggle.classList.remove('active');
            }
        });
    }

    activateGameMode() {
        console.log('🎮 Game Mode Activated!');

        // Initialize game
        this.gameEngine.init();

        // Create player avatar
        this.playerAvatar.create();

        // Show game HUD
        document.getElementById('game-hud').style.display = 'block';

        // Setup map click to move player
        this.mapManager.map.on('click', this.onMapClickGame.bind(this));

        // Setup map movement to generate collectibles
        this.mapManager.map.on('moveend', this.onMapMoveGame.bind(this));

        // Initial HUD update
        this.updateGameHUD();

        // Show collectibles
        this.collectiblesRenderer.renderAll();

        this.showNotification('🎮 Game Mode Activated! Click to move your avatar.');
    }

    deactivateGameMode() {
        console.log('🎮 Game Mode Deactivated');

        // Hide game HUD
        document.getElementById('game-hud').style.display = 'none';

        // Remove player avatar
        this.playerAvatar.remove();

        // Clear collectibles
        this.collectiblesRenderer.clearAll();

        // Remove map click handler (would need to track the handler)
        // For now, game click will just be ignored when not active

        this.showNotification('Game Mode Deactivated');
    }

    onMapClickGame(e) {
        if (!this.gameActive) return;

        const lngLat = [e.lngLat.lng, e.lngLat.lat];

        // Move player
        const distance = this.gameEngine.movePlayer(lngLat);

        // Update avatar position
        this.playerAvatar.updatePosition(lngLat);

        // Award XP for movement (1 XP per 10 meters)
        if (distance > 10) {
            const xp = Math.floor(distance / 10);
            this.gameEngine.addXP(xp, 'movement');
        }

        // Check for level up
        const levelUp = this.gameEngine.checkLevelUp();
        if (levelUp) {
            this.onLevelUp(levelUp);
        }

        // Update HUD
        this.updateGameHUD();

        // Refresh visible collectibles
        this.collectiblesRenderer.refreshVisibleCollectibles();
    }

    onMapMoveGame() {
        if (!this.gameActive) return;

        // Generate new collectibles when map moves
        const zoom = this.mapManager.getZoom();
        if (zoom >= 14) {
            this.gameEngine.generateCollectibles();
            this.collectiblesRenderer.refreshVisibleCollectibles();
        }
    }

    onLevelUp(levelInfo) {
        console.log(`🎉 LEVEL UP! Now level ${levelInfo.level}`);

        // Update avatar
        this.playerAvatar.updateLevel();

        // Show special notification
        const notification = document.createElement('div');
        notification.className = 'notification level-up-notification';
        notification.innerHTML = `
            <div style="font-size: 20px;">🎉 LEVEL UP!</div>
            <div style="font-size: 16px; margin-top: 4px;">Level ${levelInfo.level}</div>
        `;
        notification.style.background = 'linear-gradient(135deg, #FFD700, #FFA500)';
        notification.style.color = '#000';
        notification.style.fontWeight = '700';

        document.body.appendChild(notification);

        setTimeout(() => {
            notification.style.animation = 'slideIn 0.3s ease-out reverse';
            setTimeout(() => {
                document.body.removeChild(notification);
            }, 300);
        }, 3000);
    }

    updateGameHUD() {
        const player = this.gameEngine.player;
        const stats = this.gameEngine.getPlayerStats();
        const inventory = this.gameEngine.getInventorySummary();

        // Level and XP
        document.getElementById('hud-level').textContent = player.level;
        document.getElementById('hud-xp').textContent = player.xp;
        document.getElementById('hud-xp-next').textContent = player.xpToNextLevel;
        document.getElementById('hud-xp-bar').style.width = stats.xpProgress + '%';

        // Inventory
        document.getElementById('hud-stars').textContent = inventory.stars;
        document.getElementById('hud-gems').textContent = inventory.gems;
        document.getElementById('hud-trophies').textContent = inventory.trophies;
        document.getElementById('hud-keys').textContent = inventory.keys;

        // Stats
        const distanceKm = stats.distanceTraveled < 1000 ?
            `${stats.distanceTraveled.toFixed(0)} m` :
            `${(stats.distanceTraveled / 1000).toFixed(2)} km`;
        document.getElementById('hud-distance').textContent = distanceKm;
        document.getElementById('hud-collected').textContent = stats.itemsCollected;
    }

    setupMapEvents() {
        this.mapManager.on('move', () => this.uiController.updateStats());
        this.mapManager.on('zoom', () => this.uiController.updateStats());
        this.mapManager.on('moveend', () => {
            this.uiController.updateStats();
            this.saveCurrentPosition();
        });
    }

    setupControls() {
        // Home button
        document.getElementById('btn-home').addEventListener('click', () => {
            this.mapManager.flyTo({
                center: [0, 20],
                zoom: 1.5,
                pitch: 0,
                bearing: 0,
                duration: 2000
            });
        });

        // North button
        document.getElementById('btn-north').addEventListener('click', () => {
            this.mapManager.easeTo({ bearing: 0, pitch: 0, duration: 500 });
        });

        // Zoom buttons
        document.getElementById('btn-zoom-in').addEventListener('click', () => {
            this.mapManager.zoomIn();
        });

        document.getElementById('btn-zoom-out').addEventListener('click', () => {
            this.mapManager.zoomOut();
        });

        // 3D buildings toggle
        document.getElementById('btn-3d').addEventListener('click', (e) => {
            const isActive = this.buildingsManager.toggle();
            e.target.classList.toggle('active', isActive);

            if (isActive) {
                this.mapManager.easeTo({ pitch: 60, duration: 500 });
            } else {
                this.mapManager.easeTo({ pitch: 0, duration: 500 });
            }
        });

        // Globe view
        document.getElementById('btn-globe').addEventListener('click', () => {
            this.mapManager.flyTo({
                center: [0, 20],
                zoom: 1.5,
                pitch: 0,
                bearing: 0,
                duration: 2000
            });
        });

        // Locate user
        document.getElementById('btn-locate').addEventListener('click', () => {
            this.locateUser();
        });

        // Save location
        document.getElementById('btn-save').addEventListener('click', () => {
            this.saveCurrentLocation();
        });
    }

    setupSearch() {
        const searchInput = document.getElementById('search');
        const searchBtn = document.getElementById('search-btn');

        const doSearch = async () => {
            const query = searchInput.value.trim();
            if (!query) return;

            const result = await this.searchService.search(query);

            if (result.success) {
                this.searchService.flyToResult(result);
                this.uiController.updateElement('location-name', result.name);

                // Add to history
                this.storageManager.addToHistory({
                    type: 'search',
                    query: query,
                    result: result.name
                });
            } else {
                this.uiController.updateElement('location-name', 'Not found');
            }
        };

        searchBtn.addEventListener('click', doSearch);
        searchInput.addEventListener('keypress', (e) => {
            if (e.key === 'Enter') doSearch();
        });
    }

    setupLayers() {
        document.querySelectorAll('.layer-btn').forEach(btn => {
            btn.addEventListener('click', () => {
                const styleName = btn.dataset.style;
                this.mapManager.changeStyle(styleName);

                document.querySelectorAll('.layer-btn').forEach(b => b.classList.remove('active'));
                btn.classList.add('active');

                this.storageManager.updateSettings({ defaultStyle: styleName });
            });
        });
    }

    setupQuickLocations() {
        document.querySelectorAll('.quick-btn').forEach(btn => {
            btn.addEventListener('click', () => {
                const lat = parseFloat(btn.dataset.lat);
                const lng = parseFloat(btn.dataset.lng);
                const zoom = parseFloat(btn.dataset.zoom);

                this.mapManager.flyTo({
                    center: [lng, lat],
                    zoom: zoom,
                    pitch: 60,
                    bearing: Math.random() * 60 - 30,
                    duration: 3000
                });

                const locationName = btn.textContent.split(' ')[0] + ' ' +
                    (btn.textContent.split(' ')[1] || '');
                this.uiController.updateElement('location-name', locationName);

                // Add to history
                this.storageManager.addToHistory({
                    type: 'quick_location',
                    name: locationName,
                    lat,
                    lng
                });
            });
        });
    }

    locateUser() {
        if (navigator.geolocation) {
            navigator.geolocation.getCurrentPosition((pos) => {
                this.mapManager.flyTo({
                    center: [pos.coords.longitude, pos.coords.latitude],
                    zoom: 17,
                    duration: 2000
                });
                this.uiController.updateElement('location-name', 'Your Location');

                // Add marker
                this.mapManager.addMarker([pos.coords.longitude, pos.coords.latitude], {
                    color: '#FF6B00'
                });
            }, (error) => {
                console.error('Geolocation error:', error);
                alert('Unable to get your location. Please check permissions.');
            });
        } else {
            alert('Geolocation is not supported by your browser.');
        }
    }

    saveCurrentLocation() {
        const center = this.mapManager.getCenter();
        const zoom = this.mapManager.getZoom();
        const locationName = document.getElementById('location-name').textContent;

        const saved = this.storageManager.saveLocation({
            name: locationName,
            lat: center.lat,
            lng: center.lng,
            zoom: zoom
        });

        this.updateSavedCount();

        // Visual feedback
        const btn = document.getElementById('btn-save');
        btn.style.background = 'rgba(0, 212, 255, 0.5)';
        setTimeout(() => {
            btn.style.background = '';
        }, 500);

        console.log('Location saved:', saved);
    }

    saveCurrentPosition() {
        const center = this.mapManager.getCenter();
        const zoom = this.mapManager.getZoom();
        const pitch = this.mapManager.getPitch();
        const bearing = this.mapManager.getBearing();

        this.storageManager.savePosition({
            center: [center.lng, center.lat],
            zoom,
            pitch,
            bearing
        });
    }

    updateSavedCount() {
        const count = this.storageManager.getSavedLocations().length;
        this.uiController.updateElement('saved-count', count.toString());
    }

    setupPanels() {
        // Tools panel
        document.getElementById('btn-tools').addEventListener('click', () => {
            this.togglePanel('tools-panel');
        });

        document.getElementById('tools-close').addEventListener('click', () => {
            this.closePanel('tools-panel');
        });

        // Marker add panel
        document.getElementById('marker-add-close').addEventListener('click', () => {
            this.closePanel('marker-add-panel');
        });

        // Saved locations panel
        document.getElementById('saved-close').addEventListener('click', () => {
            this.closePanel('saved-panel');
        });

        document.getElementById('btn-save').addEventListener('click', () => {
            this.openSavedPanel();
        });
    }

    setupTools() {
        // Share button
        document.getElementById('btn-share').addEventListener('click', async () => {
            const result = await this.urlManager.copyToClipboard();
            if (result.success) {
                this.showNotification('Share link copied to clipboard!');
            } else {
                this.showNotification('Failed to copy link');
            }
        });

        // Marker button
        document.getElementById('btn-marker').addEventListener('click', () => {
            this.openMarkerPanel();
        });

        // Measure button
        document.getElementById('btn-measure').addEventListener('click', () => {
            this.togglePanel('tools-panel');
        });

        // Measurement tools
        document.getElementById('measure-distance').addEventListener('click', () => {
            this.measurementTools.startDistance();
            this.showNotification('Click on map to measure distance');
            this.setupMeasurementListener();
        });

        document.getElementById('measure-area').addEventListener('click', () => {
            this.measurementTools.startArea();
            this.showNotification('Click on map to measure area');
            this.setupMeasurementListener();
        });

        document.getElementById('measure-clear').addEventListener('click', () => {
            this.measurementTools.clear();
            document.getElementById('measurement-result').innerHTML = '';
        });

        // Copy URL
        document.getElementById('copy-url').addEventListener('click', async () => {
            const result = await this.urlManager.copyToClipboard();
            if (result.success) {
                this.showNotification('Share link copied!');
            }
        });

        // Add marker from tools
        document.getElementById('add-marker-custom').addEventListener('click', () => {
            this.openMarkerPanel();
        });

        // View markers
        document.getElementById('view-markers').addEventListener('click', () => {
            const markers = this.markerManager.getMarkers();
            console.log('Markers:', markers);
            this.showNotification(`${markers.length} markers on map`);
        });

        // Clear markers
        document.getElementById('clear-markers').addEventListener('click', () => {
            if (confirm('Clear all markers?')) {
                this.markerManager.clearAllMarkers();
                this.showNotification('All markers cleared');
            }
        });

        // Save marker
        document.getElementById('marker-save').addEventListener('click', () => {
            const name = document.getElementById('marker-name').value;
            const category = document.getElementById('marker-category').value;
            const description = document.getElementById('marker-description').value;

            if (!name) {
                alert('Please enter a marker name');
                return;
            }

            const center = this.mapManager.getCenter();
            this.markerManager.addMarker([center.lng, center.lat], {
                name,
                category,
                description
            });

            this.showNotification('Marker added!');
            this.closePanel('marker-add-panel');

            // Clear form
            document.getElementById('marker-name').value = '';
            document.getElementById('marker-description').value = '';
        });
    }

    setupMeasurementListener() {
        const updateResults = () => {
            const results = this.measurementTools.getResults();
            if (results) {
                document.getElementById('measurement-result').innerHTML = `
                    <strong>${results.type === 'distance' ? 'Distance' : 'Area'}:</strong><br>
                    ${results.formatted}<br>
                    <small>${results.points} points</small>
                `;
            }
        };

        // Update on map click
        const clickHandler = () => {
            setTimeout(updateResults, 100);
        };

        this.mapManager.map.on('click', clickHandler);
    }

    openMarkerPanel() {
        const center = this.mapManager.getCenter();
        document.getElementById('marker-name').placeholder = `Marker at ${center.lat.toFixed(4)}, ${center.lng.toFixed(4)}`;
        this.openPanel('marker-add-panel');
        this.closePanel('tools-panel');
    }

    openSavedPanel() {
        const savedLocations = this.storageManager.getSavedLocations();
        const listEl = document.getElementById('saved-locations-list');

        if (savedLocations.length === 0) {
            listEl.innerHTML = '<p style="opacity: 0.5; text-align: center; padding: 20px;">No saved locations</p>';
        } else {
            listEl.innerHTML = savedLocations.map(loc => `
                <div class="saved-item" data-lat="${loc.lat}" data-lng="${loc.lng}" data-zoom="${loc.zoom}" data-id="${loc.id}">
                    <div class="saved-item-name">${loc.name}</div>
                    <div class="saved-item-coords">${loc.lat.toFixed(4)}, ${loc.lng.toFixed(4)}</div>
                </div>
            `).join('');

            // Add click handlers
            listEl.querySelectorAll('.saved-item').forEach(item => {
                item.addEventListener('click', () => {
                    const lat = parseFloat(item.dataset.lat);
                    const lng = parseFloat(item.dataset.lng);
                    const zoom = parseFloat(item.dataset.zoom);

                    this.mapManager.flyTo({
                        center: [lng, lat],
                        zoom: zoom,
                        duration: 2000
                    });

                    this.closePanel('saved-panel');
                });
            });
        }

        this.openPanel('saved-panel');
    }

    togglePanel(panelId) {
        const panel = document.getElementById(panelId);
        if (panel.style.display === 'none' || !panel.style.display) {
            this.openPanel(panelId);
        } else {
            this.closePanel(panelId);
        }
    }

    openPanel(panelId) {
        document.getElementById(panelId).style.display = 'block';
    }

    closePanel(panelId) {
        document.getElementById(panelId).style.display = 'none';
    }

    showNotification(message, duration = 3000) {
        const notification = document.createElement('div');
        notification.className = 'notification';
        notification.textContent = message;
        document.body.appendChild(notification);

        setTimeout(() => {
            notification.style.animation = 'slideIn 0.3s ease-out reverse';
            setTimeout(() => {
                document.body.removeChild(notification);
            }, 300);
        }, duration);
    }
}

// Initialize app when DOM is ready
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => {
        const app = new RoadWorldApp();
        app.init();
    });
} else {
    const app = new RoadWorldApp();
    app.init();
}
