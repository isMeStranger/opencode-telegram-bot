# OpenCode Telegram Bot

A Telegram bridge to a headless [opencode](https://opencode.ai) server, packaged
as a systemd service. Run opencode on a remote box with no display, and drive it
entirely from Telegram: pick a project folder, send prompts, and watch tool
calls and model output stream back in the chat.

This project wires up the [@grinev/opencode-telegram-bot](https://www.npmjs.com/package/@grinev/opencode-telegram-bot) npm package into a
secure, self-hosted setup: bot token kept out of the repo, streaming through an
already-running local opencode server, and permission-scoped to a single Telegram user.

## Features

- Control a headless opencode server from Telegram (`you → bot → opencode`)
- Real-time streaming of tool calls and model output
- Only one allow-listed Telegram user can talk to the bot
- Secrets stored in root-only env files, never committed
- Managed as an independent systemd service with auto-restart

## Requirements

- A Linux server with systemd (Ubuntu/Debian tested)
- Node.js 18+ and npm
- An opencode server already running locally (e.g. `opencode web`) with basic auth
- A Telegram bot token from [@BotFather](https://t.me/BotFather)
- A Telegram user ID (the only person allowed to use the bot)

## Architecture

```text
Telegram
   │
   ▼
opencode-telegram-bot  (systemd service)
   │  Basic auth (OPENCODE_SERVER_USERNAME / _PASSWORD)
   ▼
opencode server  (separate systemd service, localhost only)
```

The bot connects to an already-running opencode server. It does not manage or
restart that server (`OPENCODE_AUTO_RESTART_ENABLED=false`), keeping the two
services independently observable.

## Install

Install the bot globally:

```bash
npm install -g @grinev/opencode-telegram-bot@latest
```

Create the local `.env` from the template and fill in your values:

```bash
cp .env.example .env
```

## Configuration

| Variable | Purpose |
| --- | --- |
| `TELEGRAM_BOT_TOKEN` | Telegram bot token (from BotFather) |
| `TELEGRAM_ALLOWED_USER_ID` | Only this Telegram user may use the bot |
| `OPENCODE_API_URL` | URL of the local opencode server (e.g. `http://127.0.0.1:4096`) |
| `OPENCODE_MODEL_PROVIDER` / `OPENCODE_MODEL_ID` | Default model the bot uses |
| `OPENCODE_SERVER_USERNAME` / `OPENCODE_SERVER_PASSWORD` | Basic auth credentials for the opencode server |
| `OPENCODE_AUTO_RESTART_ENABLED` | Keep `false` when the server runs as its own service |
| `BOT_LOCALE` / `LOG_LEVEL` | Locale and logging verbosity |

Secrets are split across two files:

- `./.env` — bot token and general config (gitignored)
- an environment file for the opencode server credentials (e.g. `/etc/opencode.env`, root-only) injected by systemd

## Run as a service

Install the unit file and start the bot:

```bash
sudo cp opencode-telegram-bot.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now opencode-telegram-bot
sudo systemctl status opencode-telegram-bot
```

Follow its output:

```bash
journalctl -u opencode-telegram-bot -f
```

### Notes on the unit file

The bundled `opencode-telegram-bot.service` uses `EnvironmentFile` for both the
project `.env` and the server-credentials env file. Adjust the `WorkingDirectory`
and `Path` values to match your own install locations.

## Usage

Message the bot on Telegram:

- `/help` — available commands
- pick a directory/session through the bot UI
- send a prompt; tools run and results stream back to you

## Repository layout

- `README.md` — this file
- `.env.example` — documented configuration template (real secrets are gitignored)
- `opencode-telegram-bot.service` — example systemd unit
- `.gitignore` — keeps secrets and runtime state out of the repo