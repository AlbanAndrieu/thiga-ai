# Thiga AI Technical Assessment

> Proof of Concept developed as part of the Senior Solution Architect technical assessment test.

---

# Executive Summary

This repository contains a Proof of Concept (PoC) demonstrating the design of a modern private AI platform capable of:

- interacting with multiple Large Language Models (LLMs);
- tracing and evaluating LLM interactions;
- exposing the architecture in a way that can easily evolve towards a production deployment.
- performing Retrieval-Augmented Generation (RAG) over custom (My CV and Thigo opening position) documents;

The objective of this project was **not** to build a production-ready platform, but rather to demonstrate architectural thinking, technical decision making and integration capabilities within the limited time available for the assessment.

I cheat a bit and used ChatGPT to create scripts `openwebui-bootstrap-thiga.sh` and `langfuse-score-openwebui-sessions.py` because I wanted to finalize the test and have a real working exemple able to answer who is Alban Andrieu ?

---

# Architecture Philosophy

Rather than connecting Open WebUI directly to Ollama, I intentionally introduced **LiteLLM** as an intermediary layer.

Although Open WebUI can communicate directly with Ollama, LiteLLM provides several architectural advantages while significantly simplifying the development process.

## Why LiteLLM first?

The decision was driven by several practical reasons:

- I was already familiar with LiteLLM and could therefore iterate much faster.
- It completely decouples the User Interface from the inference providers (and I did not know which one will work on my workstation).
- It allowed me to validate that Ollama and the selected models (working with my RTX 2060 GPU) were working correctly before introducing Open WebUI.
- It offers a stable OpenAI-compatible API regardless of the underlying model provider.
- It makes model switching almost instantaneous (Ollama today, vLLM or others tomorrow).
- It provided an ideal place to integrate tracing, logging and observability through Langfuse.

This incremental approach considerably reduced debugging complexity during development.

---

# Why not implement MCP?

Model Context Protocol (MCP) was intentionally left outside of the initial PoC.
Too much time consuming... And I found out that Open Web UI could have a simple RAG, called Knowledge + Assistant

The available time was primarily invested in:

- document ingestion;
- Retrieval-Augmented Generation;
- observability;
- architecture documentation.

However, I already have an MCP server implementation that could naturally extend this platform.

Repository:

https://gitlab.com/AlbanAndrieu/fastapi-sample

This project already contains most of the building blocks required to expose enterprise APIs and business services through MCP, and would have been my next integration step.

---

# Design Priorities

The priorities during this assessment were:

1. Establish a clean architecture.
2. Validate every integration independently.
3. Keep components loosely coupled.
4. Make every service observable and debugable.
5. Build a platform that can easily evolve.

---

# Current Scope

The current PoC demonstrates:

- Open WebUI as conversational interface;
- LiteLLM as LLM gateway;
- Ollama for local inference;
- Langfuse tracing;
- Knowledge base ingestion (simple RAG);
- Architecture documentation.

---

# Conclusion

I spend I think 10 hours on this POC, I know more than I should, but the tools exactly (except open Web UI) match the one I used to work on my company and it is part of my goal to create an home lab with them.

This was a perfect fit to deisgn my Futur Home Lab and I will integrate this on my stack.

🚀 Start with the 📦 [docs/01-deployment.md](docs/01-deployment.md) to start the PoC.

 🏗️ [Architecture Overview](docs/02-architecture.md) for architecture diagrams. And drawio link [here](https://drawio.albandrieu.com/)

 📊 [RAG is working](docs/03-prompt.md) to see the prompt outcome (in case of the demo effect).

Start the slides

```bash
cd slidev
npm install
npm run dev
```

Good presentation [here](http://localhost:3030/presenter/)
