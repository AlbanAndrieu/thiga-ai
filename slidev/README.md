# Kit de soutenance Slidev — AI

Ce dossier contient une proposition de présentation **Slidev** en français pour la restitution du test technique IA & Architecture.

## Objectif

Présenter en 10 minutes une architecture de plateforme IA souveraine, auto-hébergée, observable et réutilisable.

## Démarrage

Depuis la racine de ton dépôt :

```bashx
cd slidev
npm install
npm run dev
# npm run dev:debug
```

- visit <http://localhost:3030>

Edit the [slides.md](./slides.md) to see the changes.

Learn more about Slidev at the [documentation](https://sli.dev/).

## Export PDF

```bash
npx slidev export slides/slides.md --format pdf
```

## Structure

```text
slides/
├── slides.md
├── 01-cover.md
├── 02-contexte-business.md
├── 03-architecture.md
├── 04-souverainete.md
├── 05-rag.md
├── 06-litellm.md
├── 07-observabilite.md
├── 08-securite.md
├── 09-compromis.md
├── 10-roadmap.md
├── 11-conclusion.md
├── appendix.md
├── speaker-notes.md
└── theme/
    └── styles.css
```
