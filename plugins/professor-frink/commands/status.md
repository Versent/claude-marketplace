# /professor-frink:status - Show Execution Status

Display the current state of Professor Frink execution.

## Status Display

Read `.frink/state.json` and display:

### Overall Progress

```
Professor Frink Status

Project: Blu Platform
Spec: Phase 1 - Foundation & Core Platform

Progress: 12/85 tasks (14.1%)
████░░░░░░░░░░░░░░░░░░░░░ 14%

Current State: RUNNING
Current Task: 1.3 Set up .nvmrc with Node 20 LTS
Task Group: Repository Foundation (3 of 10 tasks)
```

### Task Group Breakdown

```
Task Groups:
┌─────────────────────────────────────────────────────────┐
│ Group 1: Repository Foundation         [████████░░] 8/10│
│ Group 2: Infrastructure - Terraform    [░░░░░░░░░░] 0/12│
│ Group 3: Local Development             [░░░░░░░░░░] 0/8 │
│ Group 4: Serverless Backend            [░░░░░░░░░░] 0/15│
│ ...                                                     │
└─────────────────────────────────────────────────────────┘
```

### Recent Activity

```
Recent Sessions:
┌──────────┬────────────┬──────────┬──────────┬─────────┐
│ Task     │ Type       │ Status   │ Duration │ Time    │
├──────────┼────────────┼──────────┼──────────┼─────────┤
│ 1.1      │ Executor   │ COMPLETE │ 2m 15s   │ 10:15am │
│ 1.1      │ Validator  │ PASS     │ 45s      │ 10:17am │
│ 1.2      │ Executor   │ COMPLETE │ 3m 02s   │ 10:18am │
│ 1.2      │ Validator  │ PASS     │ 52s      │ 10:21am │
│ 1.3      │ Executor   │ RUNNING  │ 1m 30s   │ 10:22am │
└──────────┴────────────┴──────────┴──────────┴─────────┘
```

### HITL Checkpoints

```
HITL Checkpoints:
┌─────────────────────┬─────────────┬──────────┬──────────┐
│ Checkpoint          │ Trigger     │ Status   │ Decision │
├─────────────────────┼─────────────┼──────────┼──────────┤
│ post_initialization │ after_grp_1 │ PENDING  │ -        │
│ pre_credentials     │ before_grp4 │ UPCOMING │ -        │
│ pre_deployment      │ before_end  │ UPCOMING │ -        │
└─────────────────────┴─────────────┴──────────┴──────────┘
```

### Validation Summary

```
Validation History (Last 5):
┌──────┬─────────────────────┬────────┬──────────────────────┐
│ Task │ Checks              │ Result │ Issues Fixed         │
├──────┼─────────────────────┼────────┼──────────────────────┤
│ 1.1  │ AC, Spec, Tests     │ PASS   │ -                    │
│ 1.2  │ AC, Spec, Tests     │ PASS   │ 2 lint errors fixed  │
│ 1.3  │ Pending...          │ -      │ -                    │
└──────┴─────────────────────┴────────┴──────────────────────┘
```

### Session Statistics

```
Session Statistics:
- Total Sessions Spawned: 24
- Executor Sessions: 12
- Validator Sessions: 12
- Self-Healing Fixes: 3
- Average Task Duration: 4m 12s
- Estimated Time Remaining: ~5h 30m
```

## State File Location

All state is stored in `.frink/`:
- `state.json` - Main execution state
- `checkpoint-history.json` - HITL decisions log
- `validation-history.json` - Validation results log
- `progress.txt` - Session handoff notes
- `logs/` - Individual session logs
