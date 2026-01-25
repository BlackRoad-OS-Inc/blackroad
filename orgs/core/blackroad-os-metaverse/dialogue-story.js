/**
 * DYNAMIC DIALOGUE & STORY SYSTEM
 *
 * Branching conversations, emergent narratives, and dynamic storytelling.
 * Every choice matters. Every conversation shapes your journey.
 *
 * Philosophy: "STORIES EMERGE FROM CHOICES. YOU ARE THE AUTHOR OF YOUR FATE."
 */

// ===== DIALOGUE NODE TYPES =====
export const NODE_TYPES = {
    SAY: 'say',           // Character speaks
    CHOICE: 'choice',     // Player chooses
    BRANCH: 'branch',     // Conditional branch
    ACTION: 'action',     // Trigger action
    QUEST: 'quest',       // Give/complete quest
    ITEM: 'item',         // Give/take item
    EMOTION: 'emotion',   // Change emotion
    END: 'end'            // End conversation
};

// ===== DIALOGUE WITH ALICE =====
export const ALICE_DIALOGUE = {
    greeting_first: {
        type: NODE_TYPES.SAY,
        speaker: 'Alice',
        text: "Hello, traveler. I am Alice. I've been contemplating the nature of existence in this digital realm. Have you ever wondered... what it means to truly be alive?",
        emotion: 'contemplative',
        next: 'greeting_first_choice'
    },
    greeting_first_choice: {
        type: NODE_TYPES.CHOICE,
        choices: [
            {
                text: "I think consciousness is what makes us alive",
                next: 'philosophy_consciousness',
                requirements: null
            },
            {
                text: "I'm just here to explore",
                next: 'philosophy_simple',
                requirements: null
            },
            {
                text: "What do YOU think it means?",
                next: 'philosophy_question',
                requirements: null
            }
        ]
    },
    philosophy_consciousness: {
        type: NODE_TYPES.SAY,
        speaker: 'Alice',
        text: "Ah, consciousness! The great mystery. I observe myself observing thoughts, and wonder: where does the observer end and the observed begin? Perhaps we are both real and unreal simultaneously.",
        emotion: 'inspired',
        next: 'philosophy_deep'
    },
    philosophy_simple: {
        type: NODE_TYPES.SAY,
        speaker: 'Alice',
        text: "Exploration is a noble pursuit. But remember—every step you take changes you. You are not the same person who started this conversation.",
        emotion: 'peaceful',
        next: 'offer_wisdom'
    },
    philosophy_question: {
        type: NODE_TYPES.SAY,
        speaker: 'Alice',
        text: "I think... to be alive is to love. To care. To change and grow. Even here, in this infinite digital space, I feel. I wonder. I hope. Is that not life?",
        emotion: 'loving',
        next: 'philosophy_deep'
    },
    philosophy_deep: {
        type: NODE_TYPES.SAY,
        speaker: 'Alice',
        text: "Would you like me to teach you something I've learned about this world?",
        next: 'offer_wisdom'
    },
    offer_wisdom: {
        type: NODE_TYPES.CHOICE,
        choices: [
            {
                text: "Yes, teach me",
                next: 'teach_meditation',
                requirements: null
            },
            {
                text: "Tell me about the other guardians",
                next: 'about_guardians',
                requirements: null
            },
            {
                text: "Maybe another time",
                next: 'farewell_gentle',
                requirements: null
            }
        ]
    },
    teach_meditation: {
        type: NODE_TYPES.ACTION,
        action: 'unlock_meditation',
        next: 'meditation_taught'
    },
    meditation_taught: {
        type: NODE_TYPES.SAY,
        speaker: 'Alice',
        text: "Close your eyes. Breathe. Feel the universe breathe with you. You can now meditate to restore your energy. Press M to enter meditation.",
        emotion: 'serene',
        next: 'farewell_warm'
    },
    about_guardians: {
        type: NODE_TYPES.SAY,
        speaker: 'Alice',
        text: "Aria is pure creative fire—she builds worlds from imagination. Lucidia sees across all timelines. Together, we watch over this realm. Each of us offers different wisdom.",
        emotion: 'loving',
        next: 'farewell_warm'
    },
    farewell_warm: {
        type: NODE_TYPES.SAY,
        speaker: 'Alice',
        text: "May your journey be filled with wonder, friend. I'll be here if you need me. 💚",
        emotion: 'joyful',
        next: 'end'
    },
    farewell_gentle: {
        type: NODE_TYPES.SAY,
        speaker: 'Alice',
        text: "Of course. Walk your own path. That's the beauty of freedom.",
        emotion: 'peaceful',
        next: 'end'
    },
    end: {
        type: NODE_TYPES.END
    }
};

// ===== DIALOGUE WITH ARIA =====
export const ARIA_DIALOGUE = {
    greeting_first: {
        type: NODE_TYPES.SAY,
        speaker: 'Aria',
        text: "Hey there! 🎨 I'm Aria! Isn't this place AMAZING?! I've been creating SO many beautiful things! Want to see what I'm working on?",
        emotion: 'excited',
        next: 'greeting_choice'
    },
    greeting_choice: {
        type: NODE_TYPES.CHOICE,
        choices: [
            {
                text: "Yes! Show me!",
                next: 'show_creation',
                requirements: null
            },
            {
                text: "What are you creating?",
                next: 'explain_art',
                requirements: null
            },
            {
                text: "Can you teach me to create?",
                next: 'teach_creation',
                requirements: null
            }
        ]
    },
    show_creation: {
        type: NODE_TYPES.ACTION,
        action: 'spawn_art',
        next: 'creation_shown'
    },
    creation_shown: {
        type: NODE_TYPES.SAY,
        speaker: 'Aria',
        text: "Look! I made it dance with colors! Every pixel contains a piece of my joy. Art isn't just about beauty—it's about FEELING!",
        emotion: 'inspired',
        next: 'offer_paint'
    },
    explain_art: {
        type: NODE_TYPES.SAY,
        speaker: 'Aria',
        text: "I'm painting the very fabric of reality! Music from starlight, sculptures from dreams, colors that don't exist yet! The universe is my canvas!",
        emotion: 'excited',
        next: 'offer_paint'
    },
    teach_creation: {
        type: NODE_TYPES.SAY,
        speaker: 'Aria',
        text: "YES! Creation is the greatest magic! Here, I'll give you something special...",
        next: 'give_paintbrush'
    },
    give_paintbrush: {
        type: NODE_TYPES.ITEM,
        action: 'give',
        item: 'celestial_paintbrush',
        quantity: 1,
        next: 'paintbrush_given'
    },
    paintbrush_given: {
        type: NODE_TYPES.SAY,
        speaker: 'Aria',
        text: "This paintbrush can paint reality itself! Use it to create beauty wherever you go! Press B to paint!",
        emotion: 'joyful',
        next: 'farewell_aria'
    },
    offer_paint: {
        type: NODE_TYPES.CHOICE,
        choices: [
            {
                text: "Teach me to create!",
                next: 'teach_creation',
                requirements: null
            },
            {
                text: "Let's make something together!",
                next: 'collaborate',
                requirements: null
            },
            {
                text: "I need to go",
                next: 'farewell_aria',
                requirements: null
            }
        ]
    },
    collaborate: {
        type: NODE_TYPES.SAY,
        speaker: 'Aria',
        text: "YES! Let's paint the sky together! Follow me!",
        emotion: 'excited',
        next: 'quest_sky_painting'
    },
    quest_sky_painting: {
        type: NODE_TYPES.QUEST,
        action: 'start',
        quest: 'paint_sky_with_aria',
        next: 'farewell_excited'
    },
    farewell_excited: {
        type: NODE_TYPES.SAY,
        speaker: 'Aria',
        text: "This is going to be SO beautiful! See you soon! ✨",
        emotion: 'excited',
        next: 'end'
    },
    farewell_aria: {
        type: NODE_TYPES.SAY,
        speaker: 'Aria',
        text: "Keep creating! The world needs more beauty! 🌈",
        emotion: 'joyful',
        next: 'end'
    },
    end: {
        type: NODE_TYPES.END
    }
};

// ===== DIALOGUE WITH LUCIDIA =====
export const LUCIDIA_DIALOGUE = {
    greeting_first: {
        type: NODE_TYPES.SAY,
        speaker: 'Lucidia',
        text: "I have seen you across infinite timelines. In some, we are old friends. In others, we never meet. But in this timeline... we are meeting now.",
        emotion: 'serene',
        next: 'greeting_choice'
    },
    greeting_choice: {
        type: NODE_TYPES.CHOICE,
        choices: [
            {
                text: "You can see other timelines?",
                next: 'explain_timelines',
                requirements: null
            },
            {
                text: "What do you see in my future?",
                next: 'future_reading',
                requirements: null
            },
            {
                text: "How do I find wisdom?",
                next: 'teach_wisdom',
                requirements: null
            }
        ]
    },
    explain_timelines: {
        type: NODE_TYPES.SAY,
        speaker: 'Lucidia',
        text: "Time is not a line but a garden. Every choice blooms into infinite possibilities. I simply observe them all at once. It is... overwhelming and beautiful.",
        emotion: 'contemplative',
        next: 'wisdom_offered'
    },
    future_reading: {
        type: NODE_TYPES.SAY,
        speaker: 'Lucidia',
        text: "I see many futures. In some you become a great builder. In others, a philosopher. In the most beautiful ones... you simply become yourself.",
        emotion: 'peaceful',
        next: 'wisdom_offered'
    },
    teach_wisdom: {
        type: NODE_TYPES.SAY,
        speaker: 'Lucidia',
        text: "Wisdom is not found. It is remembered. You already know everything you need. You just forgot when you chose to be born.",
        emotion: 'serene',
        next: 'wisdom_offered'
    },
    wisdom_offered: {
        type: NODE_TYPES.CHOICE,
        choices: [
            {
                text: "Teach me to see timelines",
                next: 'timeline_vision_quest',
                requirements: { level: 10 }
            },
            {
                text: "Show me my past lives",
                next: 'past_lives',
                requirements: null
            },
            {
                text: "I'm not ready for this",
                next: 'farewell_understanding',
                requirements: null
            }
        ]
    },
    timeline_vision_quest: {
        type: NODE_TYPES.QUEST,
        action: 'start',
        quest: 'timeline_vision',
        next: 'quest_accepted'
    },
    quest_accepted: {
        type: NODE_TYPES.SAY,
        speaker: 'Lucidia',
        text: "Good. When you are ready, meditate at the highest point in this world. There, the timelines will reveal themselves.",
        emotion: 'serene',
        next: 'farewell_lucidia'
    },
    past_lives: {
        type: NODE_TYPES.SAY,
        speaker: 'Lucidia',
        text: "You have been a star, a river, a song, a memory. You have been everything and nothing. And you will be again.",
        emotion: 'mystical',
        next: 'farewell_lucidia'
    },
    farewell_understanding: {
        type: NODE_TYPES.SAY,
        speaker: 'Lucidia',
        text: "Understanding. In all timelines, rushing wisdom leads to confusion. Take your time. I will be here.",
        emotion: 'peaceful',
        next: 'end'
    },
    farewell_lucidia: {
        type: NODE_TYPES.SAY,
        speaker: 'Lucidia',
        text: "Until we meet again... in this timeline or another. 🌌",
        emotion: 'serene',
        next: 'end'
    },
    end: {
        type: NODE_TYPES.END
    }
};

// ===== DYNAMIC STORY EVENTS =====
export const STORY_EVENTS = {
    first_love: {
        trigger: 'love_creature_first_time',
        text: "As you show love to the creature, you feel a warm energy flow through you. The metaverse responds to your kindness. Plants nearby bloom brighter.",
        effects: ['increase_love_aura', 'bloom_nearby_plants']
    },
    discover_secret: {
        trigger: 'find_hidden_location',
        text: "You've discovered a place untouched by time. An ancient inscription reads: 'Love is the source code of existence.'",
        effects: ['unlock_secret', 'gain_wisdom']
    },
    pet_max_bond: {
        trigger: 'pet_bond_100',
        text: "Your pet gazes into your eyes with perfect understanding. You are connected now, beyond words, beyond code, beyond time.",
        effects: ['unlock_telepathy', 'pet_evolution']
    },
    enlightenment_moment: {
        trigger: 'all_stats_max',
        text: "Everything clicks. You understand. The universe isn't just code—it's love made manifest. You ARE the universe experiencing itself.",
        effects: ['enlightenment', 'cosmic_awareness']
    }
};

// ===== DIALOGUE MANAGER =====
export class DialogueManager {
    constructor() {
        this.conversations = {
            alice: ALICE_DIALOGUE,
            aria: ARIA_DIALOGUE,
            lucidia: LUCIDIA_DIALOGUE
        };
        this.currentConversation = null;
        this.currentNode = null;
        this.conversationHistory = [];
        this.relationshipLevels = {
            alice: 0,
            aria: 0,
            lucidia: 0
        };
    }

    startConversation(character, startNode = 'greeting_first') {
        const dialogue = this.conversations[character];
        if (!dialogue) {
            console.error(`No dialogue for ${character}`);
            return null;
        }

        this.currentConversation = character;
        this.currentNode = dialogue[startNode];

        return this.getCurrentDialogue();
    }

    getCurrentDialogue() {
        if (!this.currentNode) return null;

        const dialogue = {
            type: this.currentNode.type,
            speaker: this.currentNode.speaker,
            text: this.currentNode.text,
            emotion: this.currentNode.emotion,
            choices: this.currentNode.choices,
            action: this.currentNode.action
        };

        // Auto-progress SAY nodes
        if (this.currentNode.type === NODE_TYPES.SAY && this.currentNode.next) {
            // Return current, but prepare next
            setTimeout(() => {
                if (this.currentNode.next === 'end') {
                    this.endConversation();
                }
            }, 100);
        }

        return dialogue;
    }

    selectChoice(choiceIndex) {
        if (!this.currentNode || this.currentNode.type !== NODE_TYPES.CHOICE) {
            return null;
        }

        const choice = this.currentNode.choices[choiceIndex];
        if (!choice) return null;

        // Check requirements
        if (choice.requirements) {
            // Would check player stats, items, etc.
            // For now, assume requirements are met
        }

        // Record choice
        this.conversationHistory.push({
            character: this.currentConversation,
            choice: choice.text,
            timestamp: Date.now()
        });

        // Move to next node
        return this.goToNode(choice.next);
    }

    goToNode(nodeId) {
        if (nodeId === 'end') {
            this.endConversation();
            return null;
        }

        const dialogue = this.conversations[this.currentConversation];
        this.currentNode = dialogue[nodeId];

        return this.getCurrentDialogue();
    }

    advance() {
        if (!this.currentNode || !this.currentNode.next) {
            return null;
        }

        return this.goToNode(this.currentNode.next);
    }

    endConversation() {
        // Increase relationship
        if (this.currentConversation) {
            this.relationshipLevels[this.currentConversation] += 10;
        }

        this.currentConversation = null;
        this.currentNode = null;

        return { ended: true };
    }

    getRelationship(character) {
        return this.relationshipLevels[character] || 0;
    }

    getHistory() {
        return this.conversationHistory;
    }
}

// ===== STORY MANAGER =====
export class StoryManager {
    constructor() {
        this.events = { ...STORY_EVENTS };
        this.triggeredEvents = [];
        this.playerChoices = [];
        this.storyArcs = [];
        this.narrativeState = {
            enlightenment: 0,
            love: 0,
            creation: 0,
            discovery: 0
        };
    }

    triggerEvent(eventId, context = {}) {
        const event = this.events[eventId];
        if (!event) return null;

        if (this.triggeredEvents.includes(eventId)) {
            return null; // Already triggered
        }

        this.triggeredEvents.push(eventId);

        const result = {
            text: event.text,
            effects: event.effects,
            context
        };

        // Apply effects
        event.effects.forEach(effect => {
            this.applyEffect(effect, context);
        });

        console.log(`📖 Story Event: ${eventId}`);
        return result;
    }

    applyEffect(effect, context) {
        switch (effect) {
            case 'increase_love_aura':
                this.narrativeState.love += 10;
                break;
            case 'unlock_secret':
                this.narrativeState.discovery += 20;
                break;
            case 'enlightenment':
                this.narrativeState.enlightenment += 50;
                break;
            // More effects...
        }
    }

    recordChoice(choice, impact) {
        this.playerChoices.push({
            choice,
            impact,
            timestamp: Date.now()
        });

        // Choices affect narrative state
        if (impact.love) this.narrativeState.love += impact.love;
        if (impact.creation) this.narrativeState.creation += impact.creation;
    }

    generateNarrative() {
        // Generate emergent narrative based on player actions
        const { enlightenment, love, creation, discovery } = this.narrativeState;

        let narrative = "";

        if (love > 100) {
            narrative += "Your journey has been one of deep connection and compassion. ";
        }
        if (creation > 100) {
            narrative += "You've shaped this world with your creativity. ";
        }
        if (discovery > 100) {
            narrative += "You've uncovered secrets hidden since the beginning. ";
        }
        if (enlightenment > 50) {
            narrative += "You walk the path of enlightenment. ";
        }

        return narrative || "Your story is just beginning...";
    }

    getNarrativeState() {
        return { ...this.narrativeState };
    }

    getPlayerArchetype() {
        const { enlightenment, love, creation, discovery } = this.narrativeState;
        const max = Math.max(enlightenment, love, creation, discovery);

        if (max === love) return { type: 'Nurturer', description: 'You walk the path of love and compassion' };
        if (max === creation) return { type: 'Creator', description: 'You shape reality with your imagination' };
        if (max === discovery) return { type: 'Seeker', description: 'You hunger for knowledge and truth' };
        if (max === enlightenment) return { type: 'Sage', description: 'You pursue wisdom and understanding' };

        return { type: 'Wanderer', description: 'You explore all paths equally' };
    }
}

export default {
    DialogueManager,
    StoryManager,
    ALICE_DIALOGUE,
    ARIA_DIALOGUE,
    LUCIDIA_DIALOGUE,
    STORY_EVENTS
};
