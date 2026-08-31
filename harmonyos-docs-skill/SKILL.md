---
name: harmonyos-docs
description: Search and fetch the latest HarmonyOS developer documentation from Huawei's developer portal. Use when building, debugging, or answering questions about HarmonyOS, ArkTS, ArkUI, Stage Model, or any HarmonyOS SDK API.
---

# HarmonyOS Developer Docs

Access the full HarmonyOS NEXT developer documentation from Huawei's portal. Two catalogs are indexed locally: development guides (~4700 pages) and API references (~4000 pages).

## Finding a Document

1. Read `references/catalog-guides.md` or `references/catalog-references.md` depending on whether you need a how-to guide or an API reference.
2. Each line has the format `- [Title](category/slug)`. The `slug` is what you pass to the fetch script.
3. Use Ctrl+F or `Select-String` to search by keyword in the catalog files.

## Fetching Document Content

Run:

```powershell
.\scripts\fetch-doc.ps1 <slug>
```

This downloads the markdown content and returns a local file path. Read that file for the full document.

Example - fetch the ArkTS getting-started guide:

```powershell
.\scripts\fetch-doc.ps1 harmonyos-guides/arkts-get-started
```

## Pre-fetched Core References

The following high-frequency topics are already saved in `references/` for offline use:

- `ref-arkts-syntax.md` - ArkTS language syntax and constraints
- `ref-state-mgmt.md` - State management (@State, @Prop, @Link, @Observed, etc.)
- `ref-ui-components.md` - Core ArkUI components overview
- `ref-navigation.md` - Page routing and navigation patterns
- `ref-app-lifecycle.md` - Application and ability lifecycle

Read these directly without fetching when the question matches.

## URL Pattern

To construct a browser link for the user: `https://developer.huawei.com/consumer/cn/doc/{slug}`
