# 8. Compromis et limites

| Décision | Bénéfice | Limite |
|---|---|---|
| Docker Compose | Démarrage rapide | Pas de haute disponibilité |
| Ollama | Souveraineté | Dépendance GPU |
| LiteLLM | Découplage | Composant supplémentaire |
| Open WebUI | Interface rapide | API interne peu documentée |
| Langfuse | Observabilité | Dépendances PostgreSQL / ClickHouse / MinIO |
| Cloudflare | Accès simple | Hors périmètre souverain |

<div class="architect-note mt-8">
Un bon POC doit aussi montrer ce qui manque pour la production : HA, SSO, RBAC, sauvegardes, supervision et politiques réseau.
</div>

<!--
Cette slide est importante pour le jury : elle montre que l'architecture est assumée, avec ses limites et sa trajectoire de transformation.
-->
