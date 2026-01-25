// Achievements System for RoadWorld
// Tracks player accomplishments and unlocks badges

export class AchievementsManager {
    constructor(gameEngine, storageManager) {
        this.gameEngine = gameEngine;
        this.storageManager = storageManager;

        // Define all achievements
        this.achievements = this.defineAchievements();

        // Load unlocked achievements
        this.unlockedAchievements = this.loadUnlocked();
    }

    defineAchievements() {
        return {
            // Explorer Achievements
            first_steps: {
                id: 'first_steps',
                name: 'First Steps',
                description: 'Move for the first time',
                icon: '🚶',
                category: 'explorer',
                rarity: 'common',
                condition: (player) => player.stats.distanceTraveled > 0,
                xpReward: 10
            },
            marathon_runner: {
                id: 'marathon_runner',
                name: 'Marathon Runner',
                description: 'Travel 42.195 kilometers',
                icon: '🏃',
                category: 'explorer',
                rarity: 'epic',
                condition: (player) => player.stats.distanceTraveled >= 42195,
                xpReward: 500
            },
            world_traveler: {
                id: 'world_traveler',
                name: 'World Traveler',
                description: 'Travel 100 kilometers',
                icon: '🌍',
                category: 'explorer',
                rarity: 'legendary',
                condition: (player) => player.stats.distanceTraveled >= 100000,
                xpReward: 1000
            },
            globe_trotter: {
                id: 'globe_trotter',
                name: 'Globe Trotter',
                description: 'Travel 1000 kilometers',
                icon: '✈️',
                category: 'explorer',
                rarity: 'legendary',
                condition: (player) => player.stats.distanceTraveled >= 1000000,
                xpReward: 5000
            },

            // Collector Achievements
            first_find: {
                id: 'first_find',
                name: 'First Find',
                description: 'Collect your first item',
                icon: '✨',
                category: 'collector',
                rarity: 'common',
                condition: (player) => player.stats.itemsCollected >= 1,
                xpReward: 10
            },
            treasure_hunter: {
                id: 'treasure_hunter',
                name: 'Treasure Hunter',
                description: 'Collect 50 items',
                icon: '🔍',
                category: 'collector',
                rarity: 'rare',
                condition: (player) => player.stats.itemsCollected >= 50,
                xpReward: 100
            },
            hoarder: {
                id: 'hoarder',
                name: 'Hoarder',
                description: 'Collect 500 items',
                icon: '💰',
                category: 'collector',
                rarity: 'epic',
                condition: (player) => player.stats.itemsCollected >= 500,
                xpReward: 500
            },
            star_collector: {
                id: 'star_collector',
                name: 'Star Collector',
                description: 'Collect 100 stars',
                icon: '⭐',
                category: 'collector',
                rarity: 'rare',
                condition: (player) => (player.inventory.stars || 0) >= 100,
                xpReward: 200
            },
            gem_enthusiast: {
                id: 'gem_enthusiast',
                name: 'Gem Enthusiast',
                description: 'Collect 50 gems',
                icon: '💎',
                category: 'collector',
                rarity: 'epic',
                condition: (player) => (player.inventory.gems || 0) >= 50,
                xpReward: 300
            },
            trophy_master: {
                id: 'trophy_master',
                name: 'Trophy Master',
                description: 'Collect 25 trophies',
                icon: '🏆',
                category: 'collector',
                rarity: 'epic',
                condition: (player) => (player.inventory.trophies || 0) >= 25,
                xpReward: 400
            },
            key_keeper: {
                id: 'key_keeper',
                name: 'Key Keeper',
                description: 'Collect 10 legendary keys',
                icon: '🗝️',
                category: 'collector',
                rarity: 'legendary',
                condition: (player) => (player.inventory.keys || 0) >= 10,
                xpReward: 1000
            },

            // Level Achievements
            level_5: {
                id: 'level_5',
                name: 'Rising Star',
                description: 'Reach level 5',
                icon: '🌟',
                category: 'level',
                rarity: 'common',
                condition: (player) => player.level >= 5,
                xpReward: 50
            },
            level_10: {
                id: 'level_10',
                name: 'Seasoned Explorer',
                description: 'Reach level 10',
                icon: '🎖️',
                category: 'level',
                rarity: 'rare',
                condition: (player) => player.level >= 10,
                xpReward: 100
            },
            level_25: {
                id: 'level_25',
                name: 'Elite Adventurer',
                description: 'Reach level 25',
                icon: '🏅',
                category: 'level',
                rarity: 'epic',
                condition: (player) => player.level >= 25,
                xpReward: 500
            },
            level_50: {
                id: 'level_50',
                name: 'Master Explorer',
                description: 'Reach level 50',
                icon: '👑',
                category: 'level',
                rarity: 'legendary',
                condition: (player) => player.level >= 50,
                xpReward: 1000
            },
            level_100: {
                id: 'level_100',
                name: 'Legend',
                description: 'Reach level 100',
                icon: '🌠',
                category: 'level',
                rarity: 'legendary',
                condition: (player) => player.level >= 100,
                xpReward: 5000
            },

            // Time Achievements
            dedicated_player: {
                id: 'dedicated_player',
                name: 'Dedicated Player',
                description: 'Play for 1 hour total',
                icon: '⏰',
                category: 'time',
                rarity: 'common',
                condition: (player) => player.stats.playTime >= 3600000,
                xpReward: 50
            },
            time_traveler: {
                id: 'time_traveler',
                name: 'Time Traveler',
                description: 'Play for 10 hours total',
                icon: '⌛',
                category: 'time',
                rarity: 'rare',
                condition: (player) => player.stats.playTime >= 36000000,
                xpReward: 200
            },
            eternal_explorer: {
                id: 'eternal_explorer',
                name: 'Eternal Explorer',
                description: 'Play for 100 hours total',
                icon: '🕰️',
                category: 'time',
                rarity: 'legendary',
                condition: (player) => player.stats.playTime >= 360000000,
                xpReward: 1000
            },

            // Special Achievements
            night_owl: {
                id: 'night_owl',
                name: 'Night Owl',
                description: 'Play between midnight and 5 AM',
                icon: '🦉',
                category: 'special',
                rarity: 'rare',
                condition: () => {
                    const hour = new Date().getHours();
                    return hour >= 0 && hour < 5;
                },
                xpReward: 100
            },
            early_bird: {
                id: 'early_bird',
                name: 'Early Bird',
                description: 'Play between 5 AM and 7 AM',
                icon: '🐦',
                category: 'special',
                rarity: 'rare',
                condition: () => {
                    const hour = new Date().getHours();
                    return hour >= 5 && hour < 7;
                },
                xpReward: 100
            },
            speed_demon: {
                id: 'speed_demon',
                name: 'Speed Demon',
                description: 'Travel 1km in under 2 minutes',
                icon: '💨',
                category: 'special',
                rarity: 'epic',
                condition: (player) => player.stats.fastestKm && player.stats.fastestKm < 120000,
                xpReward: 300
            }
        };
    }

    loadUnlocked() {
        const saved = this.storageManager.data.achievements || [];
        return new Set(saved);
    }

    saveUnlocked() {
        this.storageManager.data.achievements = Array.from(this.unlockedAchievements);
        this.storageManager.save();
    }

    checkAchievements(player) {
        const newlyUnlocked = [];

        for (const [id, achievement] of Object.entries(this.achievements)) {
            if (this.unlockedAchievements.has(id)) continue;

            try {
                if (achievement.condition(player)) {
                    this.unlockAchievement(id, achievement);
                    newlyUnlocked.push(achievement);
                }
            } catch (e) {
                // Condition failed, skip
            }
        }

        return newlyUnlocked;
    }

    unlockAchievement(id, achievement) {
        this.unlockedAchievements.add(id);
        this.saveUnlocked();

        // Award XP
        if (this.gameEngine && achievement.xpReward) {
            this.gameEngine.addXP(achievement.xpReward, `achievement: ${achievement.name}`);
        }

        console.log(`🏆 Achievement Unlocked: ${achievement.name}`);
    }

    getAchievementProgress() {
        const total = Object.keys(this.achievements).length;
        const unlocked = this.unlockedAchievements.size;
        return {
            unlocked,
            total,
            percentage: Math.round((unlocked / total) * 100)
        };
    }

    getAllAchievements() {
        return Object.entries(this.achievements).map(([id, achievement]) => ({
            ...achievement,
            unlocked: this.unlockedAchievements.has(id)
        }));
    }

    getAchievementsByCategory(category) {
        return this.getAllAchievements().filter(a => a.category === category);
    }

    getRecentUnlocks(count = 5) {
        // Get recently unlocked achievements
        const unlocked = this.getAllAchievements().filter(a => a.unlocked);
        return unlocked.slice(-count);
    }

    getRarityColor(rarity) {
        const colors = {
            common: '#FFFFFF',
            rare: '#00d4ff',
            epic: '#7b2ff7',
            legendary: '#FFD700'
        };
        return colors[rarity] || colors.common;
    }
}
