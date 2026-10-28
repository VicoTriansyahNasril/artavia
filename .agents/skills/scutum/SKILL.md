---
name: scutum
description: >-
  Scutum Spec-Driven Development (SDD) framework and AI governance workflows.
  Use this skill whenever the user invokes any /scutum command (such as /scutum.specify,
  /scutum.plan, /scutum.tasks, /scutum.implement, /scutum.constitution, /scutum.test,
  /scutum.converge, /scutum.scutum, etc.) or requests to execute Scutum workflows.
---

# Scutum SDD Governance Skill

This skill guides the agent through executing Scutum Spec-Driven Development workflows within Antigravity IDE.

## Available Commands

All command definitions reside in `.agents/commands/`:

- `/scutum.scutum` (`.agents/commands/scutum.scutum.md`): Concierge & router entrypoint
- `/scutum.constitution` (`.agents/commands/scutum.constitution.md`): Establish or amend project constitution
- `/scutum.specify` (`.agents/commands/scutum.specify.md`): Requirements specification (`spec.md`)
- `/scutum.clarify` (`.agents/commands/scutum.clarify.md`): Requirements clarification
- `/scutum.checklist` (`.agents/commands/scutum.checklist.md`): Quality and review checklists
- `/scutum.plan` (`.agents/commands/scutum.plan.md`): Technical architecture & implementation plan (`plan.md`)
- `/scutum.tasks` (`.agents/commands/scutum.tasks.md`): Actionable task decomposition (`tasks.md`)
- `/scutum.implement` (`.agents/commands/scutum.implement.md`): Phased code implementation
- `/scutum.converge` (`.agents/commands/scutum.converge.md`): Verify implementation completeness
- `/scutum.test` (`.agents/commands/scutum.test.md`): Comprehensive test suite execution
- `/scutum.analyze` (`.agents/commands/scutum.analyze.md`): Structural analysis & health check
- `/scutum.redesign` (`.agents/commands/scutum.redesign.md`): Rework an isolated UI component or endpoint
- `/scutum.revamp` (`.agents/commands/scutum.revamp.md`): Cross-module phased revamp
- `/scutum.upgrade` (`.agents/commands/scutum.upgrade.md`): Dependency & framework version upgrade
- `/scutum.tracer` (`.agents/commands/scutum.tracer.md`): Issue/root-cause tracing
- `/scutum.prototype` (`.agents/commands/scutum.prototype.md`): Lightweight throwaway PoC
- `/scutum.deploy` (`.agents/commands/scutum.deploy.md`): Containerization & deployment pipeline setup
- `/scutum.operate` (`.agents/commands/scutum.operate.md`): Production telemetry & observability
- `/scutum.postmortem` (`.agents/commands/scutum.postmortem.md`): Incident post-mortem & learnings
- `/scutum.brd` (`.agents/commands/scutum.brd.md`): Business Requirements Document for existing code

## Execution Protocol

1. **If user runs `/scutum` without arguments**:
   - Immediately display an interactive menu of the Scutum SDD phases (Specify, Plan, Tasks, Implement, Converge, Test, etc.) with brief explanations of what each does and how to run them.
   - Ask the user what they would like to do: start a new feature, plan an existing one, audit code, or run tests.

2. **If user runs `/scutum` with an intent or specific feature request**:
   - Classify the intent into the appropriate Scutum phase and route to it.
   - For light commands (`specify`, `plan`, `tasks`), proceed with the instructions in `.agents/commands/scutum.<command>.md`.
   - For heavy commands that modify repositories (`implement`, `redesign`, `revamp`, `upgrade`, `deploy`), confirm with the user before proceeding.

