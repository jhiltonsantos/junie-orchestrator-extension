---
name: "orchestrator-setup"
description: "Guided setup and health check for the orchestrator extension: creates the custom model profiles the specialist subagents need (orch-explorer, orch-fixer) from the provider and model the user chooses, and runs a doctor that detects missing profiles or unset API key variables. Use when the user asks to set up, configure or check the orchestrator, or when subagents seem to run on the wrong model."
---

# Orchestrator setup

Each specialist subagent runs on a Junie custom model profile named `orch-<role>`. If a profile is missing, Junie does not show an error: it silently runs that subagent on the main agent's model. This skill creates the profiles and checks them.

The extension ships **no default models and no keys**. The user chooses the provider and the model for each role.

## 0. The key must be in Junie's environment

Profiles read the API key from an environment variable, and Junie reads it from **its own process environment**. If the variable was not exported in the shell that started Junie, every profile fails to load and the subagents silently run on the main agent's model. Ask the user whether they exported the key in a terminal and started Junie from that terminal (see "Set up your models" in the repository README). If not, tell them how and stop: they must restart Junie first.

## 1. Run the doctor

Run `bash <this skill's directory>/scripts/doctor.sh` (the skill directory is the one containing this file). It reports, for every subagent, whether its profile exists, is valid JSON, and whether the environment variable named in `apiKey` is set. If the command is denied or cannot run, ask the user to run it in their own terminal and paste the output (it contains no secrets). If everything passes, stop here and report it.

## 2. Ask the user

For each role that failed the doctor (`explorer`, `fixer`), ask:

- **Provider:** OpenRouter, OpenAI, Anthropic, or another endpoint (see `references/providers.md`).
- **Model ID** exactly as that provider's API expects it. Do not suggest a default; if the user is unsure, point them to the provider's model catalog.
- **Environment variable** that holds their API key. Suggest the name from `references/providers.md`; the user may pick another.

Different roles may use different providers and models. That is the point.

## 3. Write the profiles

Create `~/.junie/models/orch-<role>.json` (user scope, shared by all projects) with the fields from `references/providers.md`:

```json
{
  "id": "<model id from the user>",
  "displayName": "orch-<role>",
  "apiType": "<from providers.md>",
  "baseUrl": "<from providers.md>",
  "apiKey": "${<ENV_VAR_NAME>}"
}
```

Rules:
- `apiKey` must be the `${VAR}` reference. **Never write a literal key**, and never ask the user to paste a key into the chat.
- Do not overwrite an existing profile without asking.
- Tell the user to export the variable in the shell that starts Junie (for example `export OPENROUTER_API_KEY=...` in `~/.bashrc`) and to restart Junie, because profiles are read at startup. A profile whose variable is unset fails to load.

## 4. Restart, then verify

Setup is **not complete** until the user has restarted Junie from a shell where the key variable is exported and the doctor passes. Tell them so explicitly, and **do not test the specialists in this same session**: the profiles you just wrote are not loaded yet, so a test here would run on the main agent's model and prove nothing.

After the restart, suggest a real check: ask the main agent to use the explorer and the fixer in verbose mode, and confirm in the provider's usage dashboard or in Junie's log under `~/.junie/logs/` (lines `Executing agent custom_agent_<role> ... model=...`) that each ran on the chosen model. Never report that a specialist used a given model unless the subagent itself reported it or the log shows it.
