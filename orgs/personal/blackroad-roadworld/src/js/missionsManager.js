// Daily Missions System for RoadWorld
// Generates daily challenges with XP rewards

export class MissionsManager {
    constructor(gameEngine, storageManager) {
        this.gameEngine = gameEngine;
        this.storageManager = storageManager;

        // Mission templates
        this.missionTemplates = this.defineMissionTemplates();

        // Load current missions
        this.activeMissions = this.loadMissions();

        // Check if we need new daily missions
        this.checkDailyReset();
    }

    defineMissionTemplates() {
        return {
            // Distance missions
            walk_distance: {
                type: 'distance',
                name: 'Take a Walk',
                description: 'Travel {target} meters',
                icon: '🚶',
                targets: [100, 250, 500, 1000, 2000],
                xpRewards: [20, 40, 80, 150, 300],
                getProgress: (player) => player.stats.distanceTraveled
            },
            run_distance: {
                type: 'distance',
                name: 'Go the Distance',
                description: 'Travel {target} kilometers',
                icon: '🏃',
                targets: [1, 2, 5, 10, 25],
                xpRewards: [50, 100, 200, 400, 1000],
                getProgress: (player) => player.stats.distanceTraveled / 1000
            },

            // Collection missions
            collect_stars: {
                type: 'collect',
                name: 'Star Gazer',
                description: 'Collect {target} stars today',
                icon: '⭐',
                targets: [3, 5, 10, 20, 50],
                xpRewards: [30, 50, 100, 200, 500],
                trackKey: 'dailyStars'
            },
            collect_gems: {
                type: 'collect',
                name: 'Gem Hunter',
                description: 'Collect {target} gems today',
                icon: '💎',
                targets: [1, 2, 5, 10, 20],
                xpRewards: [50, 100, 250, 500, 1000],
                trackKey: 'dailyGems'
            },
            collect_any: {
                type: 'collect',
                name: 'Treasure Seeker',
                description: 'Collect {target} items today',
                icon: '✨',
                targets: [5, 10, 20, 50, 100],
                xpRewards: [25, 50, 100, 250, 500],
                trackKey: 'dailyItems'
            },

            // Rare collection missions
            collect_trophy: {
                type: 'collect',
                name: 'Trophy Hunter',
                description: 'Collect a trophy today',
                icon: '🏆',
                targets: [1],
                xpRewards: [200],
                trackKey: 'dailyTrophies'
            },
            collect_key: {
                type: 'collect',
                name: 'Key Quest',
                description: 'Find a legendary key',
                icon: '🗝️',
                targets: [1],
                xpRewards: [500],
                trackKey: 'dailyKeys'
            },

            // XP missions
            earn_xp: {
                type: 'xp',
                name: 'XP Grinder',
                description: 'Earn {target} XP today',
                icon: '📈',
                targets: [50, 100, 250, 500, 1000],
                xpRewards: [25, 50, 125, 250, 500],
                trackKey: 'dailyXP'
            },

            // Exploration missions
            explore_locations: {
                type: 'explore',
                name: 'Explorer',
                description: 'Visit {target} different locations',
                icon: '🗺️',
                targets: [3, 5, 10, 20],
                xpRewards: [50, 100, 200, 500],
                trackKey: 'dailyLocations'
            }
        };
    }

    loadMissions() {
        return this.storageManager.data.dailyMissions || {
            missions: [],
            lastReset: null,
            dailyProgress: {}
        };
    }

    saveMissions() {
        this.storageManager.data.dailyMissions = this.activeMissions;
        this.storageManager.save();
    }

    checkDailyReset() {
        const now = new Date();
        const today = now.toDateString();

        if (this.activeMissions.lastReset !== today) {
            this.generateDailyMissions();
        }
    }

    generateDailyMissions() {
        const now = new Date();

        // Reset daily progress
        this.activeMissions.dailyProgress = {
            dailyStars: 0,
            dailyGems: 0,
            dailyTrophies: 0,
            dailyKeys: 0,
            dailyItems: 0,
            dailyXP: 0,
            dailyLocations: 0,
            startDistance: this.gameEngine?.player?.stats?.distanceTraveled || 0
        };

        // Generate 3 random missions of varying difficulty
        const templates = Object.entries(this.missionTemplates);
        const shuffled = templates.sort(() => Math.random() - 0.5);
        const selected = shuffled.slice(0, 3);

        this.activeMissions.missions = selected.map(([key, template], index) => {
            // Vary difficulty: easy, medium, hard
            const difficultyIndex = Math.min(index, template.targets.length - 1);
            const target = template.targets[difficultyIndex];
            const xpReward = template.xpRewards[difficultyIndex];

            return {
                id: `daily_${key}_${Date.now()}`,
                templateKey: key,
                name: template.name,
                description: template.description.replace('{target}', target),
                icon: template.icon,
                type: template.type,
                target: target,
                xpReward: xpReward,
                progress: 0,
                completed: false,
                claimed: false,
                trackKey: template.trackKey
            };
        });

        this.activeMissions.lastReset = now.toDateString();
        this.saveMissions();

        console.log('🎯 New daily missions generated!');
        return this.activeMissions.missions;
    }

    updateProgress(type, amount = 1) {
        // Update daily progress tracking
        const progressKeys = {
            star: 'dailyStars',
            gem: 'dailyGems',
            trophy: 'dailyTrophies',
            key: 'dailyKeys',
            item: 'dailyItems',
            xp: 'dailyXP',
            location: 'dailyLocations'
        };

        const key = progressKeys[type];
        if (key && this.activeMissions.dailyProgress) {
            this.activeMissions.dailyProgress[key] =
                (this.activeMissions.dailyProgress[key] || 0) + amount;
        }

        // Check mission completion
        this.checkMissionProgress();
        this.saveMissions();
    }

    checkMissionProgress() {
        if (!this.activeMissions.missions) return;

        this.activeMissions.missions.forEach(mission => {
            if (mission.completed) return;

            let currentProgress = 0;

            switch (mission.type) {
                case 'distance':
                    const startDist = this.activeMissions.dailyProgress.startDistance || 0;
                    const currentDist = this.gameEngine?.player?.stats?.distanceTraveled || 0;
                    currentProgress = currentDist - startDist;
                    if (mission.target >= 1 && mission.target <= 100) {
                        // Target is in km, convert progress
                        currentProgress = currentProgress / 1000;
                    }
                    break;
                case 'collect':
                case 'xp':
                case 'explore':
                    currentProgress = this.activeMissions.dailyProgress[mission.trackKey] || 0;
                    break;
            }

            mission.progress = Math.min(currentProgress, mission.target);

            if (mission.progress >= mission.target && !mission.completed) {
                mission.completed = true;
                console.log(`🎯 Mission Complete: ${mission.name}!`);
            }
        });
    }

    claimMissionReward(missionId) {
        const mission = this.activeMissions.missions.find(m => m.id === missionId);
        if (!mission || !mission.completed || mission.claimed) return null;

        mission.claimed = true;
        this.saveMissions();

        // Award XP
        if (this.gameEngine) {
            this.gameEngine.addXP(mission.xpReward, `mission: ${mission.name}`);
        }

        console.log(`💰 Claimed ${mission.xpReward} XP from ${mission.name}!`);
        return mission;
    }

    getMissions() {
        this.checkMissionProgress();
        return this.activeMissions.missions || [];
    }

    getCompletedCount() {
        return (this.activeMissions.missions || []).filter(m => m.completed).length;
    }

    getClaimableCount() {
        return (this.activeMissions.missions || []).filter(m => m.completed && !m.claimed).length;
    }

    getTimeUntilReset() {
        const now = new Date();
        const tomorrow = new Date(now);
        tomorrow.setDate(tomorrow.getDate() + 1);
        tomorrow.setHours(0, 0, 0, 0);

        const diff = tomorrow - now;
        const hours = Math.floor(diff / (1000 * 60 * 60));
        const minutes = Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60));

        return { hours, minutes, formatted: `${hours}h ${minutes}m` };
    }
}
