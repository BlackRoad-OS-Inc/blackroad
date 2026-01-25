export class GameEngine {
    constructor(mapManager, storageManager) {
        this.mapManager = mapManager;
        this.storageManager = storageManager;

        this.player = null;
        this.collectibles = new Map();
        this.missions = [];
        this.nearbyPlayers = new Map();

        this.gameState = {
            isActive: false,
            mode: 'free-roam', // 'free-roam', 'mission', 'competitive'
            lastUpdate: Date.now()
        };
    }

    init() {
        // Load or create player
        this.player = this.loadPlayer();

        // Start game loop
        this.startGameLoop();

        // Generate initial collectibles
        this.generateCollectibles();

        console.log('Game Engine initialized', this.player);
    }

    loadPlayer() {
        const saved = this.storageManager.data.player;

        if (saved) {
            return saved;
        }

        // Create new player
        return {
            id: this.generatePlayerId(),
            username: `Player${Math.floor(Math.random() * 10000)}`,
            avatar: {
                type: 'default',
                color: this.getRandomColor(),
                skin: 'default'
            },
            position: [0, 0],
            level: 1,
            xp: 0,
            xpToNextLevel: 100,
            stats: {
                distanceTraveled: 0,
                locationsDiscovered: 0,
                itemsCollected: 0,
                missionsCompleted: 0,
                playTime: 0,
                loginDays: 1
            },
            inventory: {
                stars: 0,
                gems: 0,
                trophies: 0,
                keys: 0,
                items: []
            },
            achievements: [],
            territory: [],
            settings: {
                movementMode: 'click', // 'click' or 'wasd'
                speed: 'walk', // 'walk', 'run', 'vehicle'
                showOtherPlayers: true
            },
            createdAt: new Date().toISOString(),
            lastActive: new Date().toISOString()
        };
    }

    savePlayer() {
        this.player.lastActive = new Date().toISOString();
        this.storageManager.data.player = this.player;
        this.storageManager.save();
    }

    generatePlayerId() {
        return `player_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    }

    getRandomColor() {
        const colors = ['#FF6B00', '#FF0066', '#7700FF', '#0066FF', '#00d4ff', '#FF9D00'];
        return colors[Math.floor(Math.random() * colors.length)];
    }

    startGameLoop() {
        this.gameState.isActive = true;
        this.gameLoop();
    }

    gameLoop() {
        if (!this.gameState.isActive) return;

        const now = Date.now();
        const delta = now - this.gameState.lastUpdate;
        this.gameState.lastUpdate = now;

        // Update player stats
        this.player.stats.playTime += delta;

        // Check for nearby collectibles
        this.checkCollectibles();

        // Update missions
        this.updateMissions();

        // Auto-save every 10 seconds
        if (delta > 10000) {
            this.savePlayer();
        }

        // Continue loop
        requestAnimationFrame(() => this.gameLoop());
    }

    movePlayer(lngLat) {
        if (!this.player.position) {
            this.player.position = lngLat;
        }

        const oldPos = this.player.position;
        const newPos = lngLat;

        // Calculate distance traveled
        const distance = this.calculateDistance(oldPos, newPos);
        this.player.stats.distanceTraveled += distance;

        // Update position
        this.player.position = newPos;

        // Check for level up
        this.checkLevelUp();

        // Save
        this.savePlayer();

        return distance;
    }

    calculateDistance(pos1, pos2) {
        // Haversine formula
        const R = 6371e3; // Earth's radius in meters
        const φ1 = pos1[1] * Math.PI / 180;
        const φ2 = pos2[1] * Math.PI / 180;
        const Δφ = (pos2[1] - pos1[1]) * Math.PI / 180;
        const Δλ = (pos2[0] - pos1[0]) * Math.PI / 180;

        const a = Math.sin(Δφ / 2) * Math.sin(Δφ / 2) +
                  Math.cos(φ1) * Math.cos(φ2) *
                  Math.sin(Δλ / 2) * Math.sin(Δλ / 2);
        const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

        return R * c; // Distance in meters
    }

    addXP(amount, source = 'unknown') {
        this.player.xp += amount;

        console.log(`+${amount} XP from ${source}`);

        // Check for level up
        while (this.player.xp >= this.player.xpToNextLevel) {
            this.levelUp();
        }

        this.savePlayer();
        return this.player.xp;
    }

    levelUp() {
        this.player.level += 1;
        this.player.xp -= this.player.xpToNextLevel;
        this.player.xpToNextLevel = Math.floor(this.player.xpToNextLevel * 1.5);

        console.log(`🎉 Level Up! Now level ${this.player.level}`);

        return {
            level: this.player.level,
            nextLevel: this.player.xpToNextLevel
        };
    }

    checkLevelUp() {
        if (this.player.xp >= this.player.xpToNextLevel) {
            return this.levelUp();
        }
        return null;
    }

    generateCollectibles() {
        // Generate collectibles around current position
        const center = this.mapManager.getCenter();
        const zoom = this.mapManager.getZoom();

        // Generate more items at higher zoom
        const count = Math.min(50, Math.max(5, Math.floor(zoom * 3)));

        for (let i = 0; i < count; i++) {
            this.createCollectible(center, zoom);
        }
    }

    createCollectible(center, zoom) {
        // Random offset based on zoom
        const radius = 0.1 / zoom;
        const angle = Math.random() * Math.PI * 2;
        const distance = Math.random() * radius;

        const lng = center.lng + distance * Math.cos(angle);
        const lat = center.lat + distance * Math.sin(angle);

        const types = [
            { type: 'star', icon: '⭐', rarity: 'common', xp: 10, weight: 60 },
            { type: 'gem', icon: '💎', rarity: 'rare', xp: 50, weight: 25 },
            { type: 'trophy', icon: '🏆', rarity: 'epic', xp: 100, weight: 10 },
            { type: 'key', icon: '🗝️', rarity: 'legendary', xp: 500, weight: 5 }
        ];

        // Weighted random selection
        const totalWeight = types.reduce((sum, t) => sum + t.weight, 0);
        let random = Math.random() * totalWeight;
        let selectedType = types[0];

        for (const type of types) {
            if (random < type.weight) {
                selectedType = type;
                break;
            }
            random -= type.weight;
        }

        const collectible = {
            id: `collectible_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
            type: selectedType.type,
            icon: selectedType.icon,
            rarity: selectedType.rarity,
            xp: selectedType.xp,
            position: [lng, lat],
            collected: false,
            createdAt: Date.now()
        };

        this.collectibles.set(collectible.id, collectible);
        return collectible;
    }

    checkCollectibles() {
        if (!this.player.position) return;

        const playerPos = this.player.position;
        const collectRadius = 0.0001; // ~10 meters

        this.collectibles.forEach((collectible, id) => {
            if (collectible.collected) return;

            const distance = this.calculateDistance(playerPos, collectible.position);

            // Auto-collect if within radius
            if (distance < collectRadius * 111000) { // Convert to meters
                this.collectItem(collectible);
            }
        });
    }

    collectItem(collectible) {
        collectible.collected = true;

        // Add to inventory
        this.player.inventory[collectible.type + 's'] =
            (this.player.inventory[collectible.type + 's'] || 0) + 1;

        this.player.inventory.items.push({
            ...collectible,
            collectedAt: new Date().toISOString()
        });

        // Add XP
        this.addXP(collectible.xp, `collecting ${collectible.type}`);

        // Update stats
        this.player.stats.itemsCollected += 1;

        console.log(`✨ Collected ${collectible.icon} ${collectible.type}! +${collectible.xp} XP`);

        this.savePlayer();
        return collectible;
    }

    updateMissions() {
        // Update active missions
        this.missions.forEach(mission => {
            if (mission.completed) return;

            // Check mission conditions
            this.checkMissionProgress(mission);
        });
    }

    checkMissionProgress(mission) {
        // Mission progress checking logic
        // Will be expanded later
        return mission;
    }

    getPlayerStats() {
        return {
            ...this.player.stats,
            level: this.player.level,
            xp: this.player.xp,
            xpToNext: this.player.xpToNextLevel,
            xpProgress: (this.player.xp / this.player.xpToNextLevel) * 100
        };
    }

    getInventorySummary() {
        return {
            stars: this.player.inventory.stars || 0,
            gems: this.player.inventory.gems || 0,
            trophies: this.player.inventory.trophies || 0,
            keys: this.player.inventory.keys || 0,
            total: this.player.inventory.items.length
        };
    }
}
