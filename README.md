# OpenCode Telegram Bot

Telegram bridge to a headless opencode server, using
[@grinev/opencode-telegram-bot](https://www.npmjs.com/package/@grinev/opencode-telegram-bot).

Bot: **@SalarOCHetznerBot**

## Architecture

```
Telegram (@SalarOCHetznerBot)
   │
   ▼
opencode-telegram-bot  (node, systemd service, runs as root)
   │  Basic auth (OPENCODE_SERVER_USERNAME / _PASSWORD from /etc/opencode.env)
   ▼
opencode server  (opencode.service, runs as salar on 127.0.0.1:4096)
```

The bot connects to the already-running local opencode server. It does not
manage or restart that server (`OPENCODE_AUTO_RESTART_ENABLED=false`).

## Config

| Variable | Location | Purpose |
| --- | --- | --- |
| `TELEGRAM_BOT_TOKEN` | project `.env` | Bot token |
| `TELEGRAM_ALLOWED_USER_ID` | project `.env` | Only this Telegram user may use the bot |
| `OPENCODE_API_URL` | project `.env` | opencode server URL (`http://127.0.0.1:4096`) |
| `OPENCODE_MODEL_PROVIDER` / `OPENCODE_MODEL_ID` | project `.env` | Default model |
| `OPENCODE_SERVER_USERNAME` / `OPENCODE_SERVER_PASSWORD` | `/etc/opencode.env` | Basic auth for the opencode server |

The project `.env` is gitignored; `.env.example` documents the keys. The
server credentials stay in `/etc/opencode.env` (root-only) and are injected by
systemd via `EnvironmentFile`.

## Install

Only needed once; already done on this host:

```bash
export PATH="$HOME/.local/bin:$PATH"
npm install -g @grinev/opencode-telegram-bot@latest
ln -sf ../lib/nodejs/bin/opencode-telegram ~/.local/bin/opencode-telegram
```

## Services

### opencode-telegram-bot.service

Unit file in this repo. Runs the bot as root with `EnvironmentFile` for both
the project `.env` and `/etc/opencode.env`.

```bash
sudo cp opencode-telegram-bot.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now opencode-telegram-bot
sudo systemctl status opencode-telegram-bot
journalctl -u opencode-telegram-bot -f
```

### opencode.service (preexisting)

Runs `opencode web` for user `salar` on `127.0.0.1:4096`. Config:
`/etc/opencode.env`. Managed under `/etc/systemd/system/opencode.service`.

## Usage

Message the bot on Telegram:

- `/help` — available commands
- select a directory/session via the bot UI
- send prompts; tool calls and model output stream back to you

## Files

- `.env` — real token/config (gitignored)
- `.env.example` — documented template
- `opencode-telegram-bot.service` — systemd unit