# AGENTS.md

## Scutum Framework Context for Antigravity & AI Agents

This repository uses the **Scutum Spec-Driven Development (SDD)** framework and AI governance system.

### Available Commands
All Scutum commands are defined under `.agents/commands/` (and `.claude/commands/`):
- `/scutum.constitution` (`.agents/commands/scutum.constitution.md`): Establish or amend project constitution
- `/scutum.specify` (`.agents/commands/scutum.specify.md`): Create or update feature specification (`spec.md`)
- `/scutum.clarify` (`.agents/commands/scutum.clarify.md`): Clarify ambiguous requirements
- `/scutum.checklist` (`.agents/commands/scutum.checklist.md`): Generate review and quality checklists
- `/scutum.plan` (`.agents/commands/scutum.plan.md`): Technical implementation planning (`plan.md`)
- `/scutum.tasks` (`.agents/commands/scutum.tasks.md`): Generate dependency-ordered actionable task list (`tasks.md`)
- `/scutum.implement` (`.agents/commands/scutum.implement.md`): Implement code according to plan and tasks
- `/scutum.converge` (`.agents/commands/scutum.converge.md`): Verify implementation against spec/plan/tasks
- `/scutum.test` (`.agents/commands/scutum.test.md`): Test execution and coverage verification
- `/scutum.analyze` (`.agents/commands/scutum.analyze.md`): Codebase analysis and consistency check
- `/scutum.redesign` (`.agents/commands/scutum.redesign.md`): Rework an isolated component/screen
- `/scutum.revamp` (`.agents/commands/scutum.revamp.md`): Multi-module phased overhaul
- `/scutum.upgrade` (`.agents/commands/scutum.upgrade.md`): Safe dependency/framework version upgrades
- `/scutum.tracer` (`.agents/commands/scutum.tracer.md`): Deep symptom/bug tracing
- `/scutum.prototype` (`.agents/commands/scutum.prototype.md`): Standalone throwaway PoC
- `/scutum.deploy` (`.agents/commands/scutum.deploy.md`): Deployment automation & CI/CD setup
- `/scutum.operate` (`.agents/commands/scutum.operate.md`): Production telemetry, observability & incident investigation
- `/scutum.postmortem` (`.agents/commands/scutum.postmortem.md`): Turn incident learnings into spec & constitution updates
- `/scutum.brd` (`.agents/commands/scutum.brd.md`): Brownfield requirements reverse engineering
- `/scutum.fan` (`.agents/commands/scutum.fan.md`): Fan-out parallel subtasks
- `/scutum.scutum` (`.agents/commands/scutum.scutum.md`): Concierge & router entrypoint

### Workflow Rule
When the user invokes `/scutum.*` or asks for a Scutum workflow:
1. Locate and read the relevant command markdown file in `.agents/commands/<command>.md`.
2. Follow its specific gates, templates (`.scutum/templates/`), and instructions strictly.
3. Adhere to the core project constitution in `.scutum/memory/constitution.md`.
