/**
 * QUEST & ACHIEVEMENT SYSTEM
 *
 * Dynamic quests, achievements, and progression tracking.
 * Players discover their purpose through exploration, creation, and love.
 *
 * Philosophy: "EVERY JOURNEY IS UNIQUE. YOUR STORY UNFOLDS AS YOU CHOOSE."
 */

// ===== QUEST TYPES =====
export const QUEST_TYPES = {
    EXPLORATION: 'exploration',
    CREATION: 'creation',
    FRIENDSHIP: 'friendship',
    DISCOVERY: 'discovery',
    MASTERY: 'mastery',
    MYSTERY: 'mystery'
};

// ===== QUEST DEFINITIONS =====
export const QUESTS = {
    // ===== EXPLORATION QUESTS =====
    first_steps: {
        id: 'first_steps',
        name: 'First Steps',
        description: 'Take your first steps in the BlackRoad Metaverse',
        type: QUEST_TYPES.EXPLORATION,
        objectives: [
            { id: 'move', description: 'Move around (WASD)', target: 1, current: 0 }
        ],
        rewards: { experience: 10 },
        completed: false
    },

    biome_explorer: {
        id: 'biome_explorer',
        name: 'Biome Explorer',
        description: 'Visit all 6 biomes in the metaverse',
        type: QUEST_TYPES.EXPLORATION,
        objectives: [
            { id: 'forest', description: 'Visit the Enchanted Forest', target: 1, current: 0 },
            { id: 'ocean', description: 'Visit the Infinite Ocean', target: 1, current: 0 },
            { id: 'mountains', description: 'Visit the Crystalline Peaks', target: 1, current: 0 },
            { id: 'desert', description: 'Visit the Golden Dunes', target: 1, current: 0 },
            { id: 'crystal', description: 'Visit the Crystal Caverns', target: 1, current: 0 },
            { id: 'sky', description: 'Visit the Sky Islands', target: 1, current: 0 }
        ],
        rewards: { experience: 100, title: 'World Traveler' },
        completed: false
    },

    distance_walker: {
        id: 'distance_walker',
        name: 'Long Journey',
        description: 'Travel 10 kilometers in the metaverse',
        type: QUEST_TYPES.EXPLORATION,
        objectives: [
            { id: 'distance', description: 'Travel 10km', target: 10000, current: 0 }
        ],
        rewards: { experience: 200, title: 'Wanderer' },
        completed: false
    },

    // ===== CREATION QUESTS =====
    first_garden: {
        id: 'first_garden',
        name: 'Budding Gardener',
        description: 'Plant your first garden',
        type: QUEST_TYPES.CREATION,
        objectives: [
            { id: 'plant', description: 'Plant 10 seeds', target: 10, current: 0 }
        ],
        rewards: { experience: 50, item: 'rare_seed_pack' },
        completed: false
    },

    master_gardener: {
        id: 'master_gardener',
        name: 'Master Gardener',
        description: 'Create a thriving garden with 50 blooming plants',
        type: QUEST_TYPES.CREATION,
        objectives: [
            { id: 'blooming', description: 'Grow 50 blooming plants', target: 50, current: 0 }
        ],
        rewards: { experience: 500, title: 'Green Thumb', item: 'legendary_seeds' },
        completed: false
    },

    pet_collector: {
        id: 'pet_collector',
        name: 'Animal Friend',
        description: 'Adopt 3 different species as pets',
        type: QUEST_TYPES.FRIENDSHIP,
        objectives: [
            { id: 'pets', description: 'Adopt 3 pets', target: 3, current: 0 }
        ],
        rewards: { experience: 150, item: 'pet_treats' },
        completed: false
    },

    terraform_artist: {
        id: 'terraform_artist',
        name: 'Terraform Artist',
        description: 'Sculpt the terrain 100 times',
        type: QUEST_TYPES.CREATION,
        objectives: [
            { id: 'sculpt', description: 'Sculpt terrain 100 times', target: 100, current: 0 }
        ],
        rewards: { experience: 300, title: 'World Shaper' },
        completed: false
    },

    // ===== FRIENDSHIP QUESTS =====
    first_love: {
        id: 'first_love',
        name: 'First Love',
        description: 'Show love to a creature for the first time',
        type: QUEST_TYPES.FRIENDSHIP,
        objectives: [
            { id: 'love', description: 'Pet a creature', target: 1, current: 0 }
        ],
        rewards: { experience: 25 },
        completed: false
    },

    creature_whisperer: {
        id: 'creature_whisperer',
        name: 'Creature Whisperer',
        description: 'Show love to 100 different creatures',
        type: QUEST_TYPES.FRIENDSHIP,
        objectives: [
            { id: 'creatures_loved', description: 'Love 100 creatures', target: 100, current: 0 }
        ],
        rewards: { experience: 400, title: 'Beast Master' },
        completed: false
    },

    meet_agents: {
        id: 'meet_agents',
        name: 'Meeting the Guardians',
        description: 'Meet Alice, Aria, and Lucidia',
        type: QUEST_TYPES.FRIENDSHIP,
        objectives: [
            { id: 'alice', description: 'Meet Alice', target: 1, current: 0 },
            { id: 'aria', description: 'Meet Aria', target: 1, current: 0 },
            { id: 'lucidia', description: 'Meet Lucidia', target: 1, current: 0 }
        ],
        rewards: { experience: 100, title: 'Friend of the Guardians' },
        completed: false
    },

    gift_giver: {
        id: 'gift_giver',
        name: 'Generous Soul',
        description: 'Give 20 gifts to other players',
        type: QUEST_TYPES.FRIENDSHIP,
        objectives: [
            { id: 'gifts', description: 'Give 20 gifts', target: 20, current: 0 }
        ],
        rewards: { experience: 250, title: 'Gift Giver' },
        completed: false
    },

    // ===== DISCOVERY QUESTS =====
    music_lover: {
        id: 'music_lover',
        name: 'Music Lover',
        description: 'Listen to all 8 musical scales',
        type: QUEST_TYPES.DISCOVERY,
        objectives: [
            { id: 'scales', description: 'Hear all 8 scales', target: 8, current: 0 }
        ],
        rewards: { experience: 150, item: 'music_box' },
        completed: false
    },

    weather_watcher: {
        id: 'weather_watcher',
        name: 'Weather Watcher',
        description: 'Experience all weather types',
        type: QUEST_TYPES.DISCOVERY,
        objectives: [
            { id: 'clear', description: 'Clear skies', target: 1, current: 0 },
            { id: 'rain', description: 'Rain', target: 1, current: 0 },
            { id: 'snow', description: 'Snow', target: 1, current: 0 }
        ],
        rewards: { experience: 100 },
        completed: false
    },

    secret_seeker: {
        id: 'secret_seeker',
        name: 'Secret Seeker',
        description: 'Find all 10 hidden secrets in the metaverse',
        type: QUEST_TYPES.MYSTERY,
        objectives: [
            { id: 'secrets', description: 'Find hidden secrets', target: 10, current: 0 }
        ],
        rewards: { experience: 1000, title: 'Seeker of Truth', item: 'infinity_crystal' },
        completed: false
    },

    // ===== MASTERY QUESTS =====
    time_master: {
        id: 'time_master',
        name: 'Time Master',
        description: 'Spend 10 hours in the metaverse',
        type: QUEST_TYPES.MASTERY,
        objectives: [
            { id: 'time', description: 'Spend 10 hours', target: 36000, current: 0 }
        ],
        rewards: { experience: 500, title: 'Time Bender' },
        completed: false
    },

    enlightenment: {
        id: 'enlightenment',
        name: 'Path to Enlightenment',
        description: 'Achieve perfect balance in all stats',
        type: QUEST_TYPES.MASTERY,
        objectives: [
            { id: 'balance', description: 'Max all stats', target: 1, current: 0 }
        ],
        rewards: { experience: 2000, title: 'Enlightened One' },
        completed: false
    }
};

// ===== ACHIEVEMENTS =====
export const ACHIEVEMENTS = {
    first_flight: {
        id: 'first_flight',
        name: 'Taking Flight',
        description: 'Activate flying mode for the first time',
        icon: '🕊️',
        unlocked: false,
        timestamp: null
    },

    speed_demon: {
        id: 'speed_demon',
        name: 'Speed Demon',
        description: 'Reach maximum flying speed',
        icon: '⚡',
        unlocked: false,
        timestamp: null
    },

    night_owl: {
        id: 'night_owl',
        name: 'Night Owl',
        description: 'Play for 1 hour during night time',
        icon: '🌙',
        unlocked: false,
        timestamp: null
    },

    sunrise_watcher: {
        id: 'sunrise_watcher',
        name: 'Sunrise Watcher',
        description: 'Watch the sunrise',
        icon: '🌅',
        unlocked: false,
        timestamp: null
    },

    rainbow_painter: {
        id: 'rainbow_painter',
        name: 'Rainbow Painter',
        description: 'Paint the sky 7 different colors',
        icon: '🌈',
        unlocked: false,
        timestamp: null
    },

    pet_bonded: {
        id: 'pet_bonded',
        name: 'Unbreakable Bond',
        description: 'Achieve 100% bond with a pet',
        icon: '💕',
        unlocked: false,
        timestamp: null
    },

    social_butterfly: {
        id: 'social_butterfly',
        name: 'Social Butterfly',
        description: 'Interact with 10 different players',
        icon: '🦋',
        unlocked: false,
        timestamp: null
    },

    architect: {
        id: 'architect',
        name: 'Master Architect',
        description: 'Build a structure with 100+ blocks',
        icon: '🏗️',
        unlocked: false,
        timestamp: null
    },

    philosopher: {
        id: 'philosopher',
        name: 'Deep Thinker',
        description: 'Have a 10-minute conversation with an AI agent',
        icon: '🧠',
        unlocked: false,
        timestamp: null
    },

    infinity: {
        id: 'infinity',
        name: 'Infinity',
        description: 'Reach the edge of infinity (travel 100km)',
        icon: '∞',
        unlocked: false,
        timestamp: null
    }
};

// ===== QUEST MANAGER =====
export class QuestManager {
    constructor() {
        this.activeQuests = [];
        this.completedQuests = [];
        this.achievements = { ...ACHIEVEMENTS };
        this.questDatabase = { ...QUESTS };
        this.level = 1;
        this.experience = 0;
        this.experienceToNext = 100;
        this.titles = [];
        this.inventory = [];
    }

    // ===== QUEST MANAGEMENT =====
    startQuest(questId) {
        const quest = this.questDatabase[questId];
        if (!quest) {
            console.error(`Quest ${questId} not found`);
            return null;
        }

        if (this.activeQuests.find(q => q.id === questId)) {
            console.warn(`Quest ${questId} already active`);
            return null;
        }

        if (this.completedQuests.includes(questId)) {
            console.warn(`Quest ${questId} already completed`);
            return null;
        }

        // Deep clone the quest
        const activeQuest = JSON.parse(JSON.stringify(quest));
        this.activeQuests.push(activeQuest);

        console.log(`📜 Started quest: ${activeQuest.name}`);
        return activeQuest;
    }

    updateQuestProgress(questId, objectiveId, progress = 1) {
        const quest = this.activeQuests.find(q => q.id === questId);
        if (!quest) return false;

        const objective = quest.objectives.find(o => o.id === objectiveId);
        if (!objective) return false;

        objective.current += progress;
        objective.current = Math.min(objective.current, objective.target);

        console.log(`📈 ${quest.name}: ${objective.description} (${objective.current}/${objective.target})`);

        // Check if quest is complete
        const allComplete = quest.objectives.every(o => o.current >= o.target);
        if (allComplete && !quest.completed) {
            this.completeQuest(questId);
        }

        return true;
    }

    completeQuest(questId) {
        const questIndex = this.activeQuests.findIndex(q => q.id === questId);
        if (questIndex === -1) return false;

        const quest = this.activeQuests[questIndex];
        quest.completed = true;
        quest.completedAt = Date.now();

        // Give rewards
        this.giveRewards(quest.rewards);

        // Move to completed
        this.completedQuests.push(questId);
        this.activeQuests.splice(questIndex, 1);

        console.log(`✅ Completed quest: ${quest.name}!`);
        return true;
    }

    giveRewards(rewards) {
        if (rewards.experience) {
            this.addExperience(rewards.experience);
        }

        if (rewards.title) {
            this.unlockTitle(rewards.title);
        }

        if (rewards.item) {
            this.inventory.push(rewards.item);
            console.log(`🎁 Received: ${rewards.item}`);
        }
    }

    // ===== ACHIEVEMENT SYSTEM =====
    unlockAchievement(achievementId) {
        const achievement = this.achievements[achievementId];
        if (!achievement) {
            console.error(`Achievement ${achievementId} not found`);
            return false;
        }

        if (achievement.unlocked) {
            return false;
        }

        achievement.unlocked = true;
        achievement.timestamp = Date.now();

        console.log(`🏆 Achievement Unlocked: ${achievement.name} ${achievement.icon}`);
        return true;
    }

    getUnlockedAchievements() {
        return Object.values(this.achievements).filter(a => a.unlocked);
    }

    getAchievementProgress() {
        const total = Object.keys(this.achievements).length;
        const unlocked = this.getUnlockedAchievements().length;
        return {
            unlocked,
            total,
            percentage: (unlocked / total * 100).toFixed(1)
        };
    }

    // ===== LEVEL SYSTEM =====
    addExperience(amount) {
        this.experience += amount;
        console.log(`✨ +${amount} XP`);

        // Check for level up
        while (this.experience >= this.experienceToNext) {
            this.levelUp();
        }
    }

    levelUp() {
        this.level++;
        this.experience -= this.experienceToNext;
        this.experienceToNext = Math.floor(this.experienceToNext * 1.5);

        console.log(`🎉 LEVEL UP! You are now level ${this.level}!`);

        // Unlock new quests based on level
        this.checkLevelUnlocks();
    }

    checkLevelUnlocks() {
        // Level 5: Unlock advanced quests
        if (this.level === 5) {
            this.startQuest('master_gardener');
            this.startQuest('creature_whisperer');
        }

        // Level 10: Unlock mastery quests
        if (this.level === 10) {
            this.startQuest('terraform_artist');
            this.startQuest('time_master');
        }

        // Level 20: Unlock mystery quests
        if (this.level === 20) {
            this.startQuest('secret_seeker');
            this.startQuest('enlightenment');
        }
    }

    unlockTitle(title) {
        if (!this.titles.includes(title)) {
            this.titles.push(title);
            console.log(`👑 Title unlocked: ${title}`);
        }
    }

    // ===== AUTO QUEST TRACKING =====
    trackAction(action, data = {}) {
        switch (action) {
            case 'move':
                this.updateQuestProgress('first_steps', 'move');
                break;

            case 'visit_biome':
                this.updateQuestProgress('biome_explorer', data.biome);
                if (data.biome === 'mountains' && data.hour >= 5 && data.hour <= 7) {
                    this.unlockAchievement('sunrise_watcher');
                }
                break;

            case 'travel':
                this.updateQuestProgress('distance_walker', 'distance', data.distance);
                const total = this.getQuestObjectiveProgress('distance_walker', 'distance');
                if (total >= 100000) {
                    this.unlockAchievement('infinity');
                }
                break;

            case 'plant':
                this.updateQuestProgress('first_garden', 'plant');
                this.updateQuestProgress('master_gardener', 'blooming', data.blooming ? 1 : 0);
                break;

            case 'adopt_pet':
                this.updateQuestProgress('pet_collector', 'pets');
                if (data.bond >= 1.0) {
                    this.unlockAchievement('pet_bonded');
                }
                break;

            case 'sculpt':
                this.updateQuestProgress('terraform_artist', 'sculpt');
                break;

            case 'love_creature':
                this.updateQuestProgress('first_love', 'love');
                this.updateQuestProgress('creature_whisperer', 'creatures_loved');
                break;

            case 'meet_agent':
                this.updateQuestProgress('meet_agents', data.agent);
                break;

            case 'give_gift':
                this.updateQuestProgress('gift_giver', 'gifts');
                break;

            case 'fly':
                this.unlockAchievement('first_flight');
                if (data.speed > 10) {
                    this.unlockAchievement('speed_demon');
                }
                break;

            case 'paint_sky':
                // Track unique colors
                break;

            case 'time_spent':
                this.updateQuestProgress('time_master', 'time', data.seconds);
                if (data.isNight) {
                    // Track night time
                }
                break;
        }
    }

    getQuestObjectiveProgress(questId, objectiveId) {
        const quest = this.activeQuests.find(q => q.id === questId);
        if (!quest) return 0;

        const objective = quest.objectives.find(o => o.id === objectiveId);
        return objective ? objective.current : 0;
    }

    // ===== UI DATA =====
    getActiveQuestsUI() {
        return this.activeQuests.map(quest => ({
            name: quest.name,
            description: quest.description,
            type: quest.type,
            objectives: quest.objectives.map(obj => ({
                description: obj.description,
                progress: obj.current,
                target: obj.target,
                percentage: Math.floor((obj.current / obj.target) * 100)
            }))
        }));
    }

    getPlayerStats() {
        return {
            level: this.level,
            experience: this.experience,
            experienceToNext: this.experienceToNext,
            experiencePercent: Math.floor((this.experience / this.experienceToNext) * 100),
            activeQuests: this.activeQuests.length,
            completedQuests: this.completedQuests.length,
            achievementsUnlocked: this.getUnlockedAchievements().length,
            achievementsTotal: Object.keys(this.achievements).length,
            titles: this.titles,
            inventory: this.inventory
        };
    }

    // ===== SAVE/LOAD =====
    save() {
        return {
            activeQuests: this.activeQuests,
            completedQuests: this.completedQuests,
            achievements: this.achievements,
            level: this.level,
            experience: this.experience,
            experienceToNext: this.experienceToNext,
            titles: this.titles,
            inventory: this.inventory
        };
    }

    load(data) {
        this.activeQuests = data.activeQuests || [];
        this.completedQuests = data.completedQuests || [];
        this.achievements = data.achievements || { ...ACHIEVEMENTS };
        this.level = data.level || 1;
        this.experience = data.experience || 0;
        this.experienceToNext = data.experienceToNext || 100;
        this.titles = data.titles || [];
        this.inventory = data.inventory || [];
    }
}

export default QuestManager;
