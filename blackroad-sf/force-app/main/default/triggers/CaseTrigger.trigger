/**
 * BlackRoad OS — Case Trigger
 * Cases = Pull Requests. Closed/Approved Cases = Merged PRs.
 * Triggers agent training flows, task creation, and Pi deployments.
 */
trigger CaseTrigger on Case (after insert, after update) {
    CaseTriggerHandler.handle(Trigger.new, Trigger.oldMap);
}
