# Diagrams

> Mermaid diagrams for the AI Technical Assessment.
>
> These diagrams are intentionally simple and presentation-oriented.

---

## 1. C4 — System Context

```mermaid
flowchart LR
    user["👤 Internal user / consultant"]
    dpo["🛡️ DPO / Security team"]
    platform["Sovereign AI PoC<br/>Open WebUI + LiteLLM + Ollama + Langfuse"]
    docs["Enterprise documents<br/>CV, job descriptions, HR documents"]
    optional["Optional external providers<br/>OpenAI / Azure OpenAI / Anthropic<br/>(disabled in sovereign mode)"]

    user -->|"Ask questions<br/>HTTPS"| platform
    dpo -->|"Audit traces<br/>Governance"| platform
    docs -->|"Imported into RAG<br/>local processing"| platform
    platform -.->|"Future optional routing<br/>only if explicitly enabled"| optional
```

---

## 2. C4 — Container Diagram

```mermaid
flowchart TB
    subgraph user_zone["User Zone"]
        browser["Browser"]
    end

    subgraph docker_network["Docker Internal Network"]
        openwebui["Open WebUI<br/>Chat UI + assistants + RAG"]
        litellm["LiteLLM<br/>LLM gateway / routing / tracing"]
        ollama["Ollama<br/>Local LLM inference"]
        langfuse["Langfuse Web + Worker<br/>LLM observability"]
        postgres["PostgreSQL<br/>metadata"]
        clickhouse["ClickHouse<br/>analytics / traces"]
        redis["Redis<br/>queues / cache"]
        minio["MinIO<br/>object storage"]
        vectordb["Vector store<br/>Open WebUI retrieval DB"]
    end

    browser -->|"HTTPS / HTTP<br/>published port"| openwebui
    openwebui -->|"OpenAI-compatible API<br/>HTTP"| litellm
    litellm -->|"Ollama API<br/>HTTP"| ollama
    litellm -->|"OTEL / Langfuse callback<br/>HTTP"| langfuse
    openwebui -->|"semantic retrieval"| vectordb
    langfuse --> postgres
    langfuse --> clickhouse
    langfuse --> redis
    langfuse --> minio
```

---

## 3. Request Sequence — RAG Answer

```mermaid
sequenceDiagram
    autonumber
    actor User
    participant OW as Open WebUI
    participant VS as Vector Store
    participant LL as LiteLLM
    participant OL as Ollama
    participant LF as Langfuse

    User->>OW: Ask a question
    OW->>VS: Retrieve relevant chunks
    VS-->>OW: Top-k document chunks
    OW->>LL: Prompt + retrieved context
    LL->>LF: Start trace / metadata
    LL->>OL: Chat completion request
    OL-->>LL: Model response
    LL->>LF: Tokens, latency, output, user/session metadata
    LL-->>OW: Final answer
    OW-->>User: Answer with citations
```

---

## 4. Data Sovereignty Boundary

```mermaid
flowchart LR
    subgraph private["Private / controlled perimeter"]
        user["User"]
        openwebui["Open WebUI"]
        litellm["LiteLLM"]
        ollama["Ollama"]
        langfuse["Langfuse"]
        storage["PostgreSQL / ClickHouse / Redis / MinIO"]
        knowledge["Knowledge Base / Vector Store"]
    end

    subgraph outside["Outside perimeter"]
        cloudllm["External LLM providers"]
        internet["Internet"]
    end

    user --> openwebui
    openwebui --> litellm
    litellm --> ollama
    openwebui --> knowledge
    litellm --> langfuse
    langfuse --> storage

    litellm -. disabled by default .-> cloudllm
    openwebui -. restricted / optional .-> internet
```

---

## 5. Deployment View — Docker Compose

```mermaid
flowchart TB
    host["Host machine / workstation"]

    subgraph compose["Docker Compose project"]
        openwebui["open-webui"]
        litellm["litellm"]
        ollama["ollama<br/>GPU enabled"]
        langfuseweb["langfuse-web"]
        langfuseworker["langfuse-worker"]
        postgres["postgres"]
        clickhouse["clickhouse"]
        redis["redis"]
        minio["minio"]
    end

    subgraph volumes["Persistent Docker volumes"]
        v_owui["open-webui data"]
        v_ollama["ollama models"]
        v_pg["postgres data"]
        v_ch["clickhouse data/logs"]
        v_minio["minio data"]
        v_redis["redis data"]
    end

    host --> compose
    openwebui --> v_owui
    ollama --> v_ollama
    postgres --> v_pg
    clickhouse --> v_ch
    minio --> v_minio
    redis --> v_redis
```

---

## 6. Observability Flow

```mermaid
flowchart LR
    request["User request"]
    openwebui["Open WebUI"]
    litellm["LiteLLM"]
    ollama["Ollama"]
    langfuse["Langfuse"]
    score["Session / trace scores"]
    export["Batch export / S3"]

    request --> openwebui
    openwebui --> litellm
    litellm --> ollama
    litellm -->|"trace + user headers"| langfuse
    langfuse --> score
    langfuse --> export
```

---

## 7. RAG Ingestion Flow

```mermaid
flowchart LR
    pdf["PDF files<br/>CV + job description"]
    upload["Open WebUI upload"]
    parser["Document parser"]
    chunks["Chunking"]
    embedding["Embedding model<br/>OpenAI-compatible or local"]
    vector["Vector store"]
    assistant["Assistant Knowledge"]

    pdf --> upload
    upload --> parser
    parser --> chunks
    chunks --> embedding
    embedding --> vector
    vector --> assistant
```

---

## 8. Future AKS Target Architecture

```mermaid
flowchart TB
    users["Users"]

    subgraph azure["Azure / AKS target"]
        ingress["Ingress Controller"]
        keycloak["Keycloak / OIDC"]
        openwebui["Open WebUI"]
        litellm["LiteLLM"]
        ollama["Ollama or vLLM GPU pool"]
        langfuse["Langfuse"]
        postgres["Managed PostgreSQL"]
        clickhouse["ClickHouse"]
        redis["Redis"]
        objectstore["Object Storage"]
        gitops["ArgoCD / GitOps"]
        vault["Vault / Secret Store"]
    end

    users --> ingress
    ingress --> keycloak
    ingress --> openwebui
    openwebui --> litellm
    litellm --> ollama
    litellm --> langfuse
    langfuse --> postgres
    langfuse --> clickhouse
    langfuse --> redis
    langfuse --> objectstore
    gitops --> openwebui
    vault --> openwebui
    vault --> litellm
    vault --> langfuse
```
