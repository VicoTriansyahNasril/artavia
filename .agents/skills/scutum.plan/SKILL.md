---
name: scutum.plan
description: >-
  Execute the implementation planning workflow using the plan template to generate design artifacts. handoffs: - label: Create Tasks agent: scutum.tasks prompt: Break the plan into tasks send: true - label: Create Checklist agent: scutum.checklist prompt: Create a checklist for the following domain...
---

# Scutum Plan (`/scutum.plan`)

This skill executes the Scutum `/scutum.plan` workflow.

## Reference Workflow
Read and follow the authoritative command specification in:
- [scutum.plan.md](../../commands/scutum.plan.md)

## Execution Guidelines
1. Read the command instructions in `.agents/commands/scutum.plan.md`.
2. Review the project constitution in `.scutum/memory/constitution.md`.
3. Check and use relevant templates in `.scutum/templates/`.
4. Adhere to security and quality standards in `.scutum/templates/security-standard.md`.
