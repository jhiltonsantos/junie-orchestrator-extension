# Provider reference

Junie custom model profile fields: `id`, `baseUrl` (full endpoint, Junie appends nothing), `apiType`, `apiKey` (supports `${VAR}`), optional `displayName`, `providerName`, `extraHeaders`, `extraBody`, `temperature`, `maxContextLength`.

| Provider | `apiType` | `baseUrl` | Suggested env var | Status |
|---|---|---|---|---|
| OpenRouter | `OpenAICompletion` | `https://openrouter.ai/api/v1/chat/completions` | `OPENROUTER_API_KEY` | Verified with Junie 26.10.27 |
| OpenAI | `OpenAICompletion` | `https://api.openai.com/v1/chat/completions` | `OPENAI_API_KEY` | Follows Junie's documented `/v1/chat/completions` form; not yet tested |
| OpenAI (Responses) | `OpenAIResponses` | `https://api.openai.com/v1/responses` | `OPENAI_API_KEY` | Follows the documented `/v1/responses` form; not yet tested |
| Anthropic | `Anthropic` | `https://api.anthropic.com/v1/messages` | `ANTHROPIC_API_KEY` | Not documented by Junie and not yet tested; confirm the URL form before relying on it |
| Google (Gemini) | `Google` | see Google's Gemini API docs | `GEMINI_API_KEY` | Not documented by Junie and not yet tested |
| Local (Ollama, etc.) | `OpenAICompletion` | `http://localhost:11434/v1/chat/completions` | none (omit `apiKey`) | Documented example |

## Model IDs

Use the ID the provider's API expects. On OpenRouter it is `vendor/model` (for example `anthropic/claude-sonnet-5.5`); OpenRouter's public catalog is at `https://openrouter.ai/api/v1/models`. Junie's built-in model list uses different spellings, so do not copy IDs from it.

## Project scope

Profiles can also live in a project's `.junie/models/` directory instead of `~/.junie/models/`. Keep keys out of version control: use `${VAR}` references only.
