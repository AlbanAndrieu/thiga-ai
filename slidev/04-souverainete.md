# 3. Réponse à la contrainte de souveraineté

<div class="grid grid-cols-2 gap-10 mt-8">

<div>

## Ce qui reste interne

- Prompts
- Documents
- Embeddings
- Réponses
- Traces / Sessions / Scores
- Modèles locaux

</div>

<div>

## Ce qui sort

- Accès HTTPS via Cloudflare uniquement
- Pas d'appel LLM externe en mode souverain
- Pas d'exposition directe d'Ollama
- Pas d'exposition directe des bases

</div>

</div>

```mermaid
flowchart LR
  subgraph OUT[Hors périmètre souverain]
    CF[Cloudflare Tunnel]
  end

  subgraph IN[Périmètre souverain]
    OW[Open WebUI]
    LL[LiteLLM]
    OL[Ollama]
    LF[Langfuse]
    DB[(Bases internes)]
  end

  CF --> OW
  OW --> LL
  LL --> OL
  LL --> LF
  LF --> DB
```

<!--
La souveraineté vient principalement de l'inférence locale avec Ollama, du stockage interne des documents et des traces, et du fait que LiteLLM peut bloquer ou contrôler tout routage externe.
-->
