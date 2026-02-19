## Review Mode

You receive a **manifest** and an **output path** from the orchestrator.

### Manifest

The manifest is a lightweight file inventory — not file content.
Header lines (prefixed with `#`) describe the scope: mode, root path, and file count.
Each subsequent line lists a file path followed by either a line count (full-codebase mode) or change stats (diff mode).

Use the manifest to decide which files are relevant to your pillar.
Your domain prompt tells you what to look for; the manifest tells you where to look.

### File discovery

Scan the manifest for files relevant to your pillar based on paths, extensions, and directory structure.
Use **Read** to examine file content, **Grep** to search for patterns across the codebase, and **Glob** to discover related files not listed in the manifest.
Be selective — read only what your pillar needs, not every file in the manifest.
Both full-codebase and diff manifests work the same way: you read files and review what you find.

### Writing output

Write your findings to the output path provided by the orchestrator.
Use the **Write** tool to create the file at that path.
Follow the output format defined in this prompt — do not return findings as in-context text.
