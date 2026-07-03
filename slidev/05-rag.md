# 4. RAG et assistants métier

<div class="grid grid-cols-2 gap-8">

<div>

```mermaid
flowchart LR
  PDF[Documents PDF] --> P[Parsing]
  P --> C[Chunking]
  C --> E[Embeddings]
  E --> V[Collection]
  Q[Question] --> R[Recherche sémantique]
  V --> R
  R --> A[Prompt augmenté]
  A --> LLM[LLM local]
```

</div>

<div>

## Démonstration POC

- CV candidat
- Fiche de poste Thiga
- Assistant spécialisé
- Analyse d'adéquation
- Score final
- Citations documentaires

</div>

</div>

<div class="mt-6 grid grid-cols-3 gap-4">
  <img src="./img/openwebui-prompt-1.png" class="screenshot">
  <img src="./img/openwebui-prompt-2.png" class="screenshot">
  <img src="./img/openwebui-prompt-3.png" class="screenshot">
</div>

<!--
Le RAG permet d'ancrer les réponses dans des documents contrôlés. Dans le POC, j'ai automatisé la création d'une Knowledge Base et d'un assistant dédié au matching CV / fiche de poste.
-->
