---
name: "orchestrate"
description: "Explicitly run the Orchestrator workflow: explore, plan, delegate to the specialist subagents (explorer, fixer) and integrate their results. Use when the user asks to orchestrate, to split a task across specialists, or to use the explorer and fixer together."
---

# Orchestrate

Run the workflow from the orchestrator guideline on the user's request.

1. **Restate the goal** in one sentence.
2. **Explore.** Delegate discovery to `explorer` with a self-contained brief: what to find, where to look, what to report. Skip this if the relevant files are already known.
3. **Plan.** From the explorer's findings, write a short numbered plan. Each step: specialist, goal, input, definition of done.
4. **Delegate.** Send each step to its specialist (`fixer` for edits). Run independent steps in parallel.
5. **Integrate.** Check the results against the goal. Follow up on gaps. Reply with what was done, which files changed and anything left open.

Rules: never claim which model a subagent used unless it reported it or the log shows it; delegation is flat (subagents never delegate); never include secrets in a brief; if the user asked for verbose mode, have each subagent start with `[<role> model: <model>]`.

If subagents seem to run on the wrong model, use the `orchestrator-setup` skill.
