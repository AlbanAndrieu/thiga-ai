# Annexe — Questions probables

---

## Pourquoi ne pas connecter directement Open WebUI à Ollama ?

Parce que LiteLLM découple l'interface des modèles, facilite le routage, les fallbacks, l'observabilité et prépare l'évolution vers d'autres providers.

---

## Pourquoi Langfuse ?

Pour apporter une observabilité IA : traces, sessions, prompts, tokens, latence, coûts et scores.

---

## Pourquoi Cloudflare hors périmètre souverain ?

Cloudflare apporte l'accès sécurisé, mais il reste un tiers externe. Les données IA et les traitements restent dans l'infrastructure interne.

---

## Que manque-t-il pour la production ?

SSO, RBAC, Vault, sauvegardes, HA, monitoring, politiques réseau, durcissement conteneurs, tests de charge, scoring automatisé.
