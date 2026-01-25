export class CollectiblesRenderer {
    constructor(mapManager, gameEngine) {
        this.mapManager = mapManager;
        this.gameEngine = gameEngine;
        this.markers = new Map();
    }

    renderAll() {
        // Clear existing markers
        this.clearAll();

        // Render all uncollected collectibles
        this.gameEngine.collectibles.forEach((collectible, id) => {
            if (!collectible.collected) {
                this.renderCollectible(collectible);
            }
        });
    }

    renderCollectible(collectible) {
        // Create collectible element
        const el = document.createElement('div');
        el.className = `collectible collectible-${collectible.rarity}`;
        el.innerHTML = `
            <div class="collectible-glow"></div>
            <div class="collectible-icon">${collectible.icon}</div>
            <div class="collectible-rarity ${collectible.rarity}">${collectible.rarity}</div>
        `;

        // Animate entrance
        setTimeout(() => {
            el.classList.add('collectible-appear');
        }, 10);

        // Create marker
        const marker = new maplibregl.Marker({
            element: el,
            anchor: 'center'
        })
            .setLngLat(collectible.position)
            .addTo(this.mapManager.map);

        // Add click handler
        el.addEventListener('click', () => {
            this.onCollectibleClick(collectible);
        });

        this.markers.set(collectible.id, { marker, element: el });
    }

    onCollectibleClick(collectible) {
        // Collect the item
        this.gameEngine.collectItem(collectible);

        // Animate collection
        this.animateCollection(collectible);

        // Show notification
        this.showCollectionNotification(collectible);
    }

    animateCollection(collectible) {
        const markerObj = this.markers.get(collectible.id);
        if (!markerObj) return;

        const el = markerObj.element;

        // Collection animation
        el.classList.add('collected');

        setTimeout(() => {
            markerObj.marker.remove();
            this.markers.delete(collectible.id);
        }, 500);
    }

    showCollectionNotification(collectible) {
        const notification = document.createElement('div');
        notification.className = `collection-notification ${collectible.rarity}`;
        notification.innerHTML = `
            <div class="collection-icon">${collectible.icon}</div>
            <div class="collection-text">
                <div class="collection-name">${collectible.type.toUpperCase()}</div>
                <div class="collection-xp">+${collectible.xp} XP</div>
            </div>
        `;

        document.body.appendChild(notification);

        // Animate in
        setTimeout(() => {
            notification.classList.add('show');
        }, 10);

        // Remove after delay
        setTimeout(() => {
            notification.classList.remove('show');
            setTimeout(() => {
                document.body.removeChild(notification);
            }, 300);
        }, 2000);
    }

    clearAll() {
        this.markers.forEach((markerObj) => {
            markerObj.marker.remove();
        });
        this.markers.clear();
    }

    refreshVisibleCollectibles() {
        const bounds = this.mapManager.map.getBounds();
        const zoom = this.mapManager.getZoom();

        // Only show collectibles if zoomed in enough
        if (zoom < 14) {
            this.clearAll();
            return;
        }

        // Remove markers outside view
        this.markers.forEach((markerObj, id) => {
            const collectible = this.gameEngine.collectibles.get(id);
            if (!collectible || collectible.collected) {
                markerObj.marker.remove();
                this.markers.delete(id);
                return;
            }

            const pos = collectible.position;
            if (!bounds.contains(pos)) {
                markerObj.marker.remove();
                this.markers.delete(id);
            }
        });

        // Add markers in view
        this.gameEngine.collectibles.forEach((collectible, id) => {
            if (collectible.collected) return;
            if (this.markers.has(id)) return;

            const pos = collectible.position;
            if (bounds.contains(pos)) {
                this.renderCollectible(collectible);
            }
        });
    }
}
