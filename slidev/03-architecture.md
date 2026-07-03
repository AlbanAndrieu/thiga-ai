# 2. Vue d'architecture

<div class="grid grid-cols-2 gap-6 items-start">

<div class="scale-75 origin-top-left">

```mermaid
flowchart TB
  U[Utilisateurs] --> CF[Cloudflare Tunnel]
  CF --> OW[Open WebUI]

  subgraph S[Périmètre souverain]
    OW --> LL[LiteLLM]
    OW --> KB[Knowledge Base / RAG]
    LL --> OL[Ollama]
    LL --> LF[Langfuse]
    LL -. TCP .-> PG[(PostgreSQL)]
    LF --> CH[(ClickHouse)]
    LF --> MI[(MinIO)]
    LF --> RD[(Redis)]
  end
```

</div>

<div class="text-sm">

## Composants clés

<div class="grid grid-cols-1 gap-1 mt-2 text-xs">

<div class="border-l-8 border-blue-500 rounded-lg shadow p-4">
<h2>🌐 User Experience</h2>
Open WebUI • Cloudflare Access
</div>

<div class="border-l-8 border-green-500 rounded-lg shadow p-4">
<h2>🧠 AI Platform</h2>
LiteLLM • Ollama • RAG • Prompt Templates
</div>

<div class="border-l-8 border-purple-500 rounded-lg shadow p-4">
<h2>📊 Observability</h2>
Langfuse • Tracing • Scores • Sessions
</div>

<div class="border-l-8 border-orange-500 rounded-lg shadow p-4">
<h2>🗄 Infrastructure</h2>
PostgreSQL • ClickHouse • Redis • MinIO
</div>

</div>

</div>

</div>

<div class="architect-note">
Cloudflare est volontairement placé hors périmètre souverain ; les traitements IA et les données restent internes.
</div>

<!--
Je distingue le périmètre non souverain, limité à Cloudflare, du périmètre souverain où se trouvent les données, les modèles, les traces et les bases. Le flux principal est utilisateur vers Open WebUI, puis LiteLLM vers Ollama et Langfuse.
-->
