---
name: rudis-workflow
description: >-
  Use this skill whenever the user asks to run a Rudis command, such as "/rudis.analyze", "/rudis.plan", "/rudis.tasks", "/rudis.ultimate", or any other command starting with "/rudis." or related to Rudis workflows.
---

# Rudis Workflow Executor

This project uses the Rapid Utility & Development Intelligence System (Rudis). The workflows and prompts for Rudis are stored as TOML files in the `.gemini/commands/` directory.

When the user asks you to run ANY Rudis command (for example, typing "/rudis.ultimate", "/rudis.analyze", "/rudis.plan", or saying "jalankan rudis implement"), you must follow this runbook:

## Steps to Execute a Rudis Command

1. **Identify the Command File**: Map the user's requested command to the corresponding TOML file. 
   - Example: "/rudis.ultimate" -> `.gemini/commands/rudis.ultimate.toml`
   - Example: "/rudis.analyze" -> `.gemini/commands/rudis.analyze.toml`

2. **Read the Prompt Template**: Use the `view_file` tool to read the contents of the identified `.toml` file.

3. **Follow the Instructions**: The `prompt` section inside the `.toml` file contains the complete system prompt, execution steps, and operating constraints for that specific workflow. You must adopt this prompt as your instructions for the current turn.
   - Run any prerequisite PowerShell scripts mentioned in the steps (e.g., `.rudis/scripts/powershell/check-prerequisites.ps1`).
   - Parse and load the specified artifacts (like `spec.md`, `plan.md`, `tasks.md`).
   - Respect all constraints (e.g., if a command says "STRICTLY READ-ONLY", do **not** modify any files).

4. **Produce the Output**: Format your response exactly as requested by the "Produce Output" or "Report" sections of the TOML file.

## Available Commands

The following commands are typically available (mapped to `.gemini/commands/rudis.<command>.toml`):
- `analyze`
- `brd`
- `checklist`
- `clarify`
- `constitution`
- `converge`
- `deploy`
- `implement`
- `operate`
- `plan`
- `postmortem`
- `redesign`
- `specify`
- `tasks`
- `taskstoissues`
- `test`
- `ultimate`

Whenever you are unsure of the steps for a Rudis command, always read its corresponding `.toml` file first before taking any action!
