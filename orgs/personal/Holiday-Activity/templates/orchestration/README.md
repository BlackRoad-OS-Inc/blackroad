# Traffic Light Orchestration System

A template-based orchestration system using the traffic light metaphor (RedLight, YellowLight, GreenLight) for managing activities, priorities, and workflows.

## Overview

This orchestration system provides a clear, visual way to manage activity states using familiar traffic light signals:

- 🔴 **RedLight**: Critical issues requiring immediate attention (STOP)
- 🟡 **YellowLight**: Warnings requiring caution and monitoring (CAUTION)
- 🟢 **GreenLight**: Success states and approval to proceed (GO)

## Templates

### RedLight Template
**Status**: Critical | **Priority**: High

Use when:
- Critical errors occur
- Security issues are detected
- Blockers prevent progress
- Emergency situations arise

Actions:
- Stop all current activity
- Alert team immediately
- Create incident report
- Escalate if necessary

### YellowLight Template
**Status**: Warning | **Priority**: Medium

Use when:
- Warnings are detected
- Potential issues identified
- Review is required
- Caution is needed

Actions:
- Assess the situation
- Monitor metrics closely
- Notify relevant team
- Document concerns
- Prepare contingency plans

### GreenLight Template
**Status**: Success | **Priority**: Normal

Use when:
- Approvals are granted
- Success is achieved
- Ready to proceed
- Completion is confirmed

Actions:
- Proceed with activity
- Deploy changes (if applicable)
- Notify success to team
- Document learnings
- Schedule next steps

## Orchestration Flow

```
┌─────────────┐
│  GreenLight │ ◄──────────────┐
│   (Ready)   │                │
└──────┬──────┘                │
       │                       │
       │ Warning               │ All Clear
       ▼                       │
┌─────────────┐                │
│ YellowLight │                │
│  (Caution)  │ ───────────────┘
└──────┬──────┘
       │
       │ Escalates
       ▼
┌─────────────┐
│  RedLight   │
│ (Critical)  │
└──────┬──────┘
       │
       │ Mitigated
       └──────────► YellowLight
```

## Usage

### 1. Assess Current State
Determine which signal applies to your current activity:
- Is there a critical blocker? → RedLight
- Are there concerns or warnings? → YellowLight
- Is everything ready to proceed? → GreenLight

### 2. Apply Template
Use the appropriate template file:
- `redlight.yml` - For critical issues
- `yellowlight.yml` - For warnings
- `greenlight.yml` - For success/ready states

### 3. Follow Actions
Execute the actions defined in the template based on priority and requirements.

### 4. Monitor Transitions
Track signal changes and ensure proper workflow progression.

## Configuration

The `orchestrator.yml` file defines:
- Template workflow sequences
- Transition rules between signals
- Priority override rules
- Monitoring and metrics
- Integration settings

## Integration

### GitHub Integration
- Labels are automatically applied based on signal
- Notifications are sent through configured channels
- Status is reflected in activity overview

### Notifications
Supported channels:
- Slack
- Email
- GitHub notifications
- Pager (RedLight only)

## Best Practices

1. **Always Start with Assessment**: Determine the correct signal before taking action
2. **Follow the Flow**: Use proper transitions (don't skip from Red to Green)
3. **Document Everything**: Each signal requires documentation of state and actions
4. **Monitor Metrics**: Track signal distribution and transition times
5. **Regular Reviews**: Ensure signals are accurate and up-to-date

## Examples

### Example 1: Critical Bug Detection
```yaml
Signal: RedLight
Trigger: Critical security vulnerability detected
Actions:
  - Stop deployment pipeline
  - Alert security team
  - Create incident report
  - Begin remediation
```

### Example 2: Code Review Warning
```yaml
Signal: YellowLight
Trigger: Potential performance issue in code review
Actions:
  - Request additional review
  - Monitor performance metrics
  - Document concerns
  - Prepare optimization plan
```

### Example 3: Successful Deployment
```yaml
Signal: GreenLight
Trigger: All tests passing, review approved
Actions:
  - Proceed with deployment
  - Notify team of success
  - Document deployment
  - Schedule post-deployment review
```

## Files

- `redlight.yml` - RedLight template definition
- `yellowlight.yml` - YellowLight template definition
- `greenlight.yml` - GreenLight template definition
- `orchestrator.yml` - Orchestration configuration

## License

This orchestration system is part of the Holiday-Activity repository and follows the same license terms.
