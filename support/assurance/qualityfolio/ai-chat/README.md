# QualityFolio Chat

A full-stack AI-powered chat application combining **SQLPage**, **LiteLLM**, and a **React-based Assistant UI**, designed to query a Resource Surveillance State Database (RSSD) using natural language.

## Overview

QualityFolio Chat allows users to ask natural language questions about quality data. It uses LiteLLM as an LLM proxy (supporting OpenAI-compatible models including local Ollama models), SQLPage to serve a web UI from SQL, and a React chat widget for the frontend.

---

## Requirements

### System

| Requirement | Version / Notes |
|---|---|
| **Node.js** | v18+ |
| **Python** | 3.10+ |
| **npm** | v9+ |
| **SQLPage** | Latest (binary in PATH) |
| **Spry CLI** | Installed and in PATH |
| **Ollama** *(optional)* | Required if using local models (e.g. `oss-20b-32K:latest`) |

### Python Packages

Install via pip:

```bash
pip install 'litellm[proxy]'
```

Or if using a virtual environment (recommended):

```bash
python -m venv litellm-venv
source litellm-venv/bin/activate
pip install 'litellm[proxy]'
```

### Node Packages (Frontend)

Installed automatically via `npm install` inside `assistant-ui-chat/`.

---

## Project Structure

```
qualityfolio-chat/
├── assistant-ui-chat/        # React frontend (Assistant UI)
│   └── ...
├── sqlpage/
│   └── sqlpage.js            # SQLPage configuration
├── dev-src.auto/             # Auto-generated SQLPage sources
├── litellm_config.yaml       # LiteLLM model & routing config
├── qualityfolio.md           # Spry source definition
├── chat-widget-react.js      # Compiled React chat widget
├── chat-widget-react-index.css
├── .env                      # Environment variables (API keys, etc.)
├── .env.example              # Example environment file
└── poly.sql                  # SQL definitions
```

---

## Setup & Running

Follow these steps **in order**. Each step should be run in a separate terminal if running concurrently.

### Step 1 — Run Spry Commands

Generate the SQLPage sources from the markdown definition:

```bash
spry rb run qualityfolio.md
spry sp spc --fs dev-src.auto --destroy-first --conf sqlpage/sqlpage.js --md qualityfolio.md
```

### Step 2 — Start SQLPage

Serve the SQLPage web interface:

```bash
sqlpage
```

SQLPage will serve from the `dev-src.auto/` directory. Visit `http://localhost:9227` (or the configured port) in your browser.

### Step 4 — Start LiteLLM

Load environment variables and start the LiteLLM proxy:

```bash
source .env && litellm --config litellm_config.yaml
```

> **Note:** Ensure `.env` contains all required API keys or model endpoint URLs. See `.env.example` for reference.

### Step 5 — Start the Frontend

Install dependencies and run the React dev server:

```bash
cd assistant-ui-chat
npm install
npm run dev
```

The frontend will be available at `http://localhost:3000` (or as configured).

---

## Environment Variables

Copy `.env.example` to `.env` and fill in your values:

```bash
cp .env.example .env
```

Key variables to configure:

| Variable | Description |
|---|---|
| `OPENAI_API_KEY` | OpenAI API key (if using OpenAI models) |
| `OLLAMA_BASE_URL` | Ollama base URL (default: `http://localhost:11434`) |
| `DATABASE_URL` | Path or connection string for the RSSD database |

---

## Troubleshooting

### `UnboundLocalError: cannot access local variable 'completion_output'`

This is a known bug in some versions of LiteLLM when using tool-calling models with streaming. It is non-blocking but can be resolved by upgrading LiteLLM:

```bash
pip install --upgrade 'litellm[proxy]'
```

### LiteLLM: "upstream model provider is currently experiencing high demand"

This is a transient error from the model provider. Wait a moment and retry, or switch to a different model in `litellm_config.yaml`.

### SQLPage not serving updated files

Re-run Steps 1 and 2 to regenerate `dev-src.auto/`, then restart SQLPage.

### Frontend not connecting to chat API

Ensure LiteLLM is running (Step 4) and that the API endpoint in `assistant-ui-chat` matches the LiteLLM proxy address (typically `http://localhost:4000`).