// Mini-map Controller for RoadWorld
// Provides a navigation overview in the corner of the screen

export class Minimap {
    constructor(mapManager) {
        this.mapManager = mapManager;
        this.minimapElement = null;
        this.minimapMap = null;
        this.playerMarker = null;
        this.isVisible = true;
        this.isExpanded = false;
    }

    init() {
        this.createMinimapContainer();
        this.initMinimapMap();
        this.setupEventListeners();
        this.startSync();

        console.log('🗺️ Minimap initialized');
    }

    createMinimapContainer() {
        this.minimapElement = document.createElement('div');
        this.minimapElement.className = 'minimap-container';
        this.minimapElement.innerHTML = `
            <div class="minimap-header">
                <span class="minimap-title">MINIMAP</span>
                <div class="minimap-controls">
                    <button class="minimap-btn" id="minimap-expand" title="Expand">⤢</button>
                    <button class="minimap-btn" id="minimap-toggle" title="Toggle">−</button>
                </div>
            </div>
            <div class="minimap-wrapper">
                <div id="minimap" class="minimap"></div>
                <div class="minimap-compass">
                    <div class="compass-needle" id="compass-needle"></div>
                    <span class="compass-label north">N</span>
                    <span class="compass-label east">E</span>
                    <span class="compass-label south">S</span>
                    <span class="compass-label west">W</span>
                </div>
                <div class="minimap-player-indicator"></div>
            </div>
            <div class="minimap-coords" id="minimap-coords">0°, 0°</div>
        `;
        document.body.appendChild(this.minimapElement);
    }

    initMinimapMap() {
        // Create a simplified map for the minimap
        const mainCenter = this.mapManager.getCenter();
        const mainZoom = this.mapManager.getZoom();

        this.minimapMap = new maplibregl.Map({
            container: 'minimap',
            style: {
                version: 8,
                sources: {
                    'carto-dark': {
                        type: 'raster',
                        tiles: ['https://a.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png'],
                        tileSize: 256
                    }
                },
                layers: [{
                    id: 'carto-dark',
                    type: 'raster',
                    source: 'carto-dark',
                    minzoom: 0,
                    maxzoom: 18
                }]
            },
            center: [mainCenter.lng, mainCenter.lat],
            zoom: Math.max(0, mainZoom - 4),
            interactive: false,
            attributionControl: false
        });

        // Add player marker
        this.createPlayerMarker();
    }

    createPlayerMarker() {
        const el = document.createElement('div');
        el.className = 'minimap-player-marker';
        el.innerHTML = `
            <div class="player-dot"></div>
            <div class="player-direction"></div>
        `;

        const mainCenter = this.mapManager.getCenter();
        this.playerMarker = new maplibregl.Marker({
            element: el,
            anchor: 'center'
        })
            .setLngLat([mainCenter.lng, mainCenter.lat])
            .addTo(this.minimapMap);
    }

    setupEventListeners() {
        // Toggle button
        document.getElementById('minimap-toggle').addEventListener('click', () => {
            this.toggle();
        });

        // Expand button
        document.getElementById('minimap-expand').addEventListener('click', () => {
            this.toggleExpand();
        });

        // Click on minimap to navigate
        this.minimapMap.on('click', (e) => {
            const { lng, lat } = e.lngLat;
            this.mapManager.flyTo({
                center: [lng, lat],
                duration: 1000
            });
        });
    }

    startSync() {
        // Sync minimap with main map
        this.mapManager.on('move', () => this.syncPosition());
        this.mapManager.on('zoom', () => this.syncPosition());
        this.mapManager.on('rotate', () => this.syncRotation());
    }

    syncPosition() {
        if (!this.minimapMap || !this.isVisible) return;

        const center = this.mapManager.getCenter();
        const zoom = this.mapManager.getZoom();

        this.minimapMap.setCenter([center.lng, center.lat]);
        this.minimapMap.setZoom(Math.max(0, zoom - 4));

        // Update player marker
        if (this.playerMarker) {
            this.playerMarker.setLngLat([center.lng, center.lat]);
        }

        // Update coordinates display
        const coordsEl = document.getElementById('minimap-coords');
        if (coordsEl) {
            coordsEl.textContent = `${center.lat.toFixed(4)}°, ${center.lng.toFixed(4)}°`;
        }
    }

    syncRotation() {
        const bearing = this.mapManager.getBearing();

        // Update compass needle
        const needle = document.getElementById('compass-needle');
        if (needle) {
            needle.style.transform = `rotate(${-bearing}deg)`;
        }

        // Update player direction indicator
        const directionEl = document.querySelector('.player-direction');
        if (directionEl) {
            directionEl.style.transform = `rotate(${bearing}deg)`;
        }
    }

    toggle() {
        this.isVisible = !this.isVisible;

        const wrapper = this.minimapElement.querySelector('.minimap-wrapper');
        const coords = this.minimapElement.querySelector('.minimap-coords');
        const toggleBtn = document.getElementById('minimap-toggle');

        if (this.isVisible) {
            wrapper.style.display = 'block';
            coords.style.display = 'block';
            toggleBtn.textContent = '−';
            this.syncPosition();
        } else {
            wrapper.style.display = 'none';
            coords.style.display = 'none';
            toggleBtn.textContent = '+';
        }
    }

    toggleExpand() {
        this.isExpanded = !this.isExpanded;
        this.minimapElement.classList.toggle('expanded', this.isExpanded);

        const expandBtn = document.getElementById('minimap-expand');
        expandBtn.textContent = this.isExpanded ? '⤡' : '⤢';

        // Resize the minimap
        setTimeout(() => {
            this.minimapMap.resize();
            this.syncPosition();
        }, 300);
    }

    updatePlayerPosition(position) {
        if (this.playerMarker && position) {
            this.playerMarker.setLngLat(position);
        }
    }

    setStyle(styleUrl) {
        if (this.minimapMap) {
            // Keep dark theme for minimap for visibility
            this.minimapMap.setStyle({
                version: 8,
                sources: {
                    'carto-dark': {
                        type: 'raster',
                        tiles: ['https://a.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png'],
                        tileSize: 256
                    }
                },
                layers: [{
                    id: 'carto-dark',
                    type: 'raster',
                    source: 'carto-dark',
                    minzoom: 0,
                    maxzoom: 18
                }]
            });
        }
    }

    show() {
        this.minimapElement.style.display = 'block';
        this.isVisible = true;
        this.syncPosition();
    }

    hide() {
        this.minimapElement.style.display = 'none';
        this.isVisible = false;
    }

    destroy() {
        if (this.minimapMap) {
            this.minimapMap.remove();
        }
        if (this.minimapElement) {
            this.minimapElement.remove();
        }
    }
}
