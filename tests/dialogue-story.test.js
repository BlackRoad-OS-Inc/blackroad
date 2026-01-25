import assert from 'node:assert/strict';
import test from 'node:test';

import {
    NODE_TYPES,
    ALICE_DIALOGUE,
    ARIA_DIALOGUE,
    LUCIDIA_DIALOGUE,
    STORY_EVENTS,
    DialogueManager,
    StoryManager
} from '../dialogue-story.js';

const NODE_TYPE_VALUES = new Set(Object.values(NODE_TYPES));

function validateDialogue(dialogue) {
    const keys = new Set(Object.keys(dialogue));
    assert.ok(keys.has('greeting_first'));
    assert.ok(keys.has('end'));
    assert.equal(dialogue.end.type, NODE_TYPES.END);

    for (const [nodeId, node] of Object.entries(dialogue)) {
        assert.ok(NODE_TYPE_VALUES.has(node.type), `Unknown type for ${nodeId}`);

        if (node.type === NODE_TYPES.SAY) {
            assert.equal(typeof node.text, 'string');
        }

        if (node.next) {
            assert.ok(node.next === 'end' || keys.has(node.next));
        }

        if (node.type === NODE_TYPES.CHOICE) {
            assert.ok(Array.isArray(node.choices));
            assert.ok(node.choices.length > 0);
            for (const choice of node.choices) {
                assert.ok(choice.next === 'end' || keys.has(choice.next));
            }
        }
    }
}

test('dialogue graphs reference valid nodes and types', () => {
    validateDialogue(ALICE_DIALOGUE);
    validateDialogue(ARIA_DIALOGUE);
    validateDialogue(LUCIDIA_DIALOGUE);

    for (const [eventId, event] of Object.entries(STORY_EVENTS)) {
        assert.equal(typeof event.trigger, 'string', `Missing trigger for ${eventId}`);
        assert.ok(Array.isArray(event.effects));
        assert.ok(event.effects.length > 0);
    }
});

test('DialogueManager advances and records choices', () => {
    const manager = new DialogueManager();

    const first = manager.startConversation('alice');
    assert.equal(first.type, NODE_TYPES.SAY);

    const choiceNode = manager.advance();
    assert.equal(choiceNode.type, NODE_TYPES.CHOICE);

    const nextNode = manager.selectChoice(0);
    assert.equal(nextNode.type, NODE_TYPES.SAY);

    assert.equal(manager.getHistory().length, 1);

    manager.endConversation();
    assert.equal(manager.getRelationship('alice'), 10);
});

test('StoryManager triggers events and builds narrative', () => {
    const story = new StoryManager();

    const result = story.triggerEvent('first_love', { source: 'test' });
    assert.ok(result);

    const stateAfterEvent = story.getNarrativeState();
    assert.equal(stateAfterEvent.love, 10);

    assert.equal(story.triggerEvent('first_love'), null);

    story.recordChoice('test', { love: 150, creation: 5 });
    const narrative = story.generateNarrative();
    assert.notEqual(narrative, 'Your story is just beginning...');
    assert.ok(narrative.includes('compassion'));

    const archetype = story.getPlayerArchetype();
    assert.equal(archetype.type, 'Nurturer');
});
