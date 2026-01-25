import assert from 'node:assert/strict';
import test from 'node:test';

import {
    QUESTS,
    QUEST_TYPES,
    ACHIEVEMENTS,
    QuestManager
} from '../quest-system.js';

test('quest definitions are consistent', () => {
    const questTypes = new Set(Object.values(QUEST_TYPES));

    for (const [questId, quest] of Object.entries(QUESTS)) {
        assert.equal(quest.id, questId);
        assert.ok(questTypes.has(quest.type));
        assert.ok(Array.isArray(quest.objectives));
        assert.ok(quest.objectives.length > 0);
        assert.equal(quest.completed, false);
        assert.ok(quest.rewards && Object.keys(quest.rewards).length > 0);

        quest.objectives.forEach(objective => {
            assert.equal(typeof objective.target, 'number');
            assert.equal(typeof objective.current, 'number');
            assert.ok(objective.current <= objective.target);
        });
    }
});

test('QuestManager completes quests and grants rewards', () => {
    const manager = new QuestManager();

    const quest = manager.startQuest('first_steps');
    assert.ok(quest);
    assert.equal(manager.activeQuests.length, 1);

    manager.updateQuestProgress('first_steps', 'move', 1);
    assert.ok(manager.completedQuests.includes('first_steps'));
    assert.equal(manager.activeQuests.length, 0);
    assert.equal(manager.experience, 10);

    assert.equal(QUESTS.first_steps.objectives[0].current, 0);
});

test('QuestManager unlocks achievements and reports progress', () => {
    const manager = new QuestManager();

    assert.equal(manager.unlockAchievement('first_flight'), true);
    assert.equal(manager.unlockAchievement('first_flight'), false);

    const progress = manager.getAchievementProgress();
    assert.equal(progress.unlocked, 1);
    assert.equal(progress.total, Object.keys(ACHIEVEMENTS).length);
});

test('QuestManager save and load preserves state', () => {
    const manager = new QuestManager();
    manager.startQuest('first_steps');
    manager.updateQuestProgress('first_steps', 'move', 1);

    const saved = manager.save();
    const restored = new QuestManager();
    restored.load(saved);

    assert.deepEqual(restored.completedQuests, manager.completedQuests);
    assert.equal(restored.experience, manager.experience);
    assert.equal(restored.level, manager.level);
});
