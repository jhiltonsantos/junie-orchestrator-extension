# junie-orchestrator-extension

Multi-agent orchestration for [Junie CLI](https://junie.jetbrains.com/). The main agent acts as an **Orchestrator**: it plans, delegates to specialist subagents and integrates the results in the same reply. Each specialist runs on its own model, **chosen by you**, from any provider Junie can use as a custom model.

> Status: v0.1, early. Two specialists (`explorer`, `fixer`). Tested with Junie CLI 26.10.27 and OpenRouter.

## What you get

| Piece | What it does |
|---|---|
| Guideline `orchestrator` | Turns the main agent into the Orchestrator: when to delegate, how to write briefs, flat delegation rules |
| Skill `orchestrate` | Explicit entry point: explore, plan, delegate, integrate |
| Subagent `explorer` | Read-only discovery (Read, Glob, Grep) |
| Subagent `fixer` | Focused code edits, verified |
| Skill `orchestrator-setup` | Guided setup of model profiles, plus a doctor script |

No models and no API keys are included. You pick them.

## Install

In Junie CLI:

```
/extensions marketplace add jhiltonsantos/junie-orchestrator-extension
/extensions install orchestrator
```

Choose project scope (`.junie/extensions.json`) or user scope. Extensions are available in the running session without a restart.

## Set up your models

Each specialist uses a custom model profile named `orch-<role>` (`orch-explorer`, `orch-fixer`). Profiles live in `~/.junie/models/`, outside this extension, because extensions cannot carry model profiles or keys. Follow the steps in order.

### 1. Export your API key in a terminal, and start Junie from that terminal

Profiles reference your key as `${ENV_VAR}`. Junie reads the variable from **its own process environment**, so it must be exported in the shell that starts Junie.

```bash
# bash (use ~/.zshrc for zsh)
echo 'export OPENROUTER_API_KEY="<your key>"' >> ~/.bashrc
source ~/.bashrc
echo ${OPENROUTER_API_KEY:+set}      # must print: set
```

Then launch Junie **from that same terminal**. A desktop launcher or an already-open Junie does not see the variable. The variable name depends on your provider (`OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, ...); the setup tells you which one it expects. Never paste your key into the Junie chat or into a file in a repository.

### 2. Check the current state (optional)

```bash
bash <extension dir>/skills/orchestrator-setup/scripts/doctor.sh
```

The doctor reports, for each specialist, whether its profile exists, is valid JSON and whether the key variable is set. Installed extensions live under `~/.junie/extensions/`.

### 3. Create the profiles

Start Junie and ask: *"Set up the orchestrator"*. The `orchestrator-setup` skill asks for a provider and a model per role and writes the profiles using `${YOUR_ENV_VAR}` references. It never writes your key into a file.

You can also create them by hand. See `extensions/orchestrator/skills/orchestrator-setup/references/providers.md` for the fields and provider endpoints, for example:

```json
{
  "id": "your-model-id",
  "displayName": "orch-explorer",
  "apiType": "OpenAICompletion",
  "baseUrl": "https://openrouter.ai/api/v1/chat/completions",
  "apiKey": "${OPENROUTER_API_KEY}"
}
```

### 4. Restart Junie, then check again

Profiles are read when Junie starts. **Quit Junie and start it again from the terminal where the key is exported**, then run the doctor once more. Do not test the specialists in the session where you created the profiles.

> **Why this matters:** if a profile is missing or fails to load, Junie does not show an error. The subagent silently runs on the main agent's model, so everything can look like it works with the wrong model.

### 5. Verify the models

Ask Junie for verbose mode (for example: *"use the explorer and the fixer, verbose"*): each subagent starts its reply with `[<role> model: <model>]`. For a check that does not depend on the model's own words, look at Junie's log in `~/.junie/logs/` (the lines `Executing agent custom_agent_<role> ... model=...`) or at your provider's usage dashboard.

## Use it

Just describe a task that has an exploration part and an editing part, or say *"use the orchestrate skill to ..."*. To see which model each subagent used, ask for verbose mode: each subagent then starts its reply with `[<role> model: <model>]`.

## How it works and limitations

- The Orchestrator is the **main agent**, guided by the guideline. Specialists are Junie custom subagents.
- Subagent model selection: the `model` field of a subagent overrides the main agent's model under Junie's default `Auto` subagent policy. If you set the policy to `SameModelOnly`, this may not hold.
- Delegation is **flat**. In our tests a subagent did not call another subagent, so the Orchestrator does all delegating.
- Subagent profiles are read when Junie starts. Restart after changing them.
- Provider status: OpenRouter is verified. OpenAI, Anthropic and Google profiles follow Junie's documentation but are not yet tested.
- Only the Junie CLI is targeted. The JetBrains IDE plugin is untested.

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| Subagents answer with the main agent's model | The profile failed to load or does not exist; Junie falls back silently | Run the doctor, then check the log (below) |
| Junie says a specialist "worked" with a model, but the provider dashboard shows nothing | The main agent can misreport; only the subagent's own `[<role> model: ...]` line or the log is reliable | Use verbose mode or the log |
| Log has `CustomModelProfileLoader ... Environment variable 'X' ... is not set` | Junie was started without the variable | Export it in the shell and start Junie from that shell (step 1) |
| Log has `Invalid 'model' value 'custom:orch-<role>'` | No loadable profile with that name | Create the profile (step 3) and restart |
| You changed a profile and nothing changed | Profiles are read at startup | Restart Junie |

Look for problems in the newest log:

```bash
grep -E "CustomModelProfileLoader|Invalid 'model'|Executing agent" "$(ls -t ~/.junie/logs/log-*.log | head -1)" | cut -c1-220
```

To see whether a running Junie has the variable (Linux):

```bash
tr '\0' '\n' < /proc/$(pgrep -nx junie)/environ | grep -c '^OPENROUTER_API_KEY='   # 1 = present, 0 = missing
```

## Privacy and keys

This repo contains no keys. Profiles reference environment variables. Do not commit your `~/.junie/models/` files if they contain literal keys, and do not paste keys into a chat.

## License

MIT. See [LICENSE](LICENSE).
