# Repository Organization Suggestions

This document proposes guidelines for organizing and naming files in this repository. Following consistent conventions improves collaboration, discoverability, and professionalism.

> **Note:** This file violates its own naming rule (ALL CAPS) for visibility. New files should follow the guidelines below.

## File Naming

### Do

- Use **lowercase with hyphens**: `cairo-contract.cairo`, `paper-evaluation.md`
- Include **file extensions**: `.md`, `.cairo`, `.py`, `.go`, `.js`
- Use **date prefixes** for time-sensitive documents: `2026-03-12-meeting-notes.md`
- Keep names **short but descriptive**: `architecture.md` not `the-complete-technical-architecture-document.md`

### Don't

- ALL CAPS names: ~~`README`~~ → `readme.md`
- Spaces in filenames: ~~`Cairo 2.x`~~ → `cairo-2x.md`
- Missing extensions: ~~`ChiaLisp`~~ → `chialisp.md`
- Ambiguous names: ~~`Final`~~ → `final-submission-link.md`

## Directory Structure

Organize content by purpose:

```
repository/
├── readme.md              # Project overview
├── docs/                  # Documentation and specifications
│   ├── architecture.md
│   └── api-reference.md
├── src/                   # Source code
│   ├── contracts/         # Smart contracts
│   └── lib/               # Libraries
├── feedback/              # External contributions and reviews
│   └── YYYY-MM-DD-topic/  # Date-prefixed folders
├── notes/                 # Working notes (may be informal)
└── assets/                # Images, diagrams, media
```

## Document Standards

### Markdown Files

- Start with a `# Title` heading
- Include metadata where relevant (date, author, status)
- Use tables for structured comparisons
- Include code blocks with language hints: ` ```cairo `

### Code Files

- Use appropriate extension: `.cairo`, `.go`, `.py`, `.rs`
- Include header comments explaining purpose
- Follow language-specific conventions

## Examples

| Current Name | Suggested Name |
|--------------|----------------|
| `Cairo 2.x` | `docs/cairo-2x-notes.md` |
| `Build Guild Phoenix` | `docs/build-guild-phoenix.md` |
| `Reignight Demo` | `docs/reignight-demo.md` |
| `Free Voices Iran` | `docs/free-voices-iran.md` |
| `Final` | `links/final-submission.md` or delete if just a URL |

## Migration

No need to rename everything at once. Apply these conventions to new files, and migrate existing files as they're updated.
