export class PlayerAvatar {
    constructor(mapManager, gameEngine) {
        this.mapManager = mapManager;
        this.gameEngine = gameEngine;
        this.marker = null;
        this.element = null;
    }

    create() {
        const player = this.gameEngine.player;

        // Create avatar element
        this.element = document.createElement('div');
        this.element.className = 'player-avatar';
        this.element.innerHTML = `
            <div class="avatar-container">
                <div class="avatar-sprite" style="background: ${player.avatar.color};">
                    <div class="avatar-icon">👤</div>
                </div>
                <div class="avatar-label">${player.username}</div>
                <div class="avatar-level">Lv ${player.level}</div>
            </div>
        `;

        // Create marker
        this.marker = new maplibregl.Marker({
            element: this.element,
            anchor: 'bottom'
        })
            .setLngLat(player.position || [0, 0])
            .addTo(this.mapManager.map);

        // Add click handler
        this.element.addEventListener('click', () => {
            this.showPlayerInfo();
        });

        return this.marker;
    }

    updatePosition(lngLat) {
        if (this.marker) {
            this.marker.setLngLat(lngLat);

            // Animate movement
            this.element.classList.add('moving');
            setTimeout(() => {
                this.element.classList.remove('moving');
            }, 300);
        }
    }

    updateLevel() {
        const player = this.gameEngine.player;
        const levelEl = this.element.querySelector('.avatar-level');
        if (levelEl) {
            levelEl.textContent = `Lv ${player.level}`;

            // Level up animation
            this.element.classList.add('level-up');
            setTimeout(() => {
                this.element.classList.remove('level-up');
            }, 1000);
        }
    }

    showPlayerInfo() {
        const player = this.gameEngine.player;
        const stats = this.gameEngine.getPlayerStats();
        const inventory = this.gameEngine.getInventorySummary();

        const popup = new maplibregl.Popup({ offset: 25 })
            .setLngLat(player.position)
            .setHTML(`
                <div class="player-info-popup">
                    <div class="popup-header">
                        <div class="avatar-small" style="background: ${player.avatar.color};">👤</div>
                        <div>
                            <div class="popup-name">${player.username}</div>
                            <div class="popup-level">Level ${player.level}</div>
                        </div>
                    </div>

                    <div class="popup-xp">
                        <div class="xp-bar-bg">
                            <div class="xp-bar-fill" style="width: ${stats.xpProgress}%"></div>
                        </div>
                        <div class="xp-text">${player.xp} / ${player.xpToNextLevel} XP</div>
                    </div>

                    <div class="popup-stats">
                        <div class="stat-row">
                            <span>🚶 Distance:</span>
                            <span>${this.formatDistance(stats.distanceTraveled)}</span>
                        </div>
                        <div class="stat-row">
                            <span>📍 Discovered:</span>
                            <span>${stats.locationsDiscovered}</span>
                        </div>
                        <div class="stat-row">
                            <span>✨ Collected:</span>
                            <span>${stats.itemsCollected}</span>
                        </div>
                        <div class="stat-row">
                            <span>🎯 Missions:</span>
                            <span>${stats.missionsCompleted}</span>
                        </div>
                    </div>

                    <div class="popup-inventory">
                        <div class="inventory-title">Inventory</div>
                        <div class="inventory-items">
                            <span>⭐ ${inventory.stars}</span>
                            <span>💎 ${inventory.gems}</span>
                            <span>🏆 ${inventory.trophies}</span>
                            <span>🗝️ ${inventory.keys}</span>
                        </div>
                    </div>
                </div>
            `)
            .addTo(this.mapManager.map);
    }

    formatDistance(meters) {
        if (meters < 1000) {
            return `${meters.toFixed(0)} m`;
        } else if (meters < 10000) {
            return `${(meters / 1000).toFixed(2)} km`;
        } else {
            return `${(meters / 1000).toFixed(1)} km`;
        }
    }

    remove() {
        if (this.marker) {
            this.marker.remove();
            this.marker = null;
        }
    }
}
