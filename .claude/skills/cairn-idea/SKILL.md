---
name: cairn-idea
description: "Manage the Cairn ideas backlog, GitHub issue #20 - add an idea under the right theme, start one as an OpenSpec change, or tick one off once shipped. Use when the user has a feature idea, asks what is in the backlog, wants to start an idea, or after archiving a change that came from it."
---

# Cairn ideas backlog (issue #20)

Answer in French, write the issue in French (keep technical terms in English). Every `gh` call:
`export GH_TOKEN=$(gh auth token --user guillaume5th)`.

The issue body is a checklist grouped by `## <theme>` (Lecture, Liste et navigation, Recherche et filtres, Flux,
Cairn et organisation, IA locale, Podcasts, Intégration macOS). `**(prioritaire)**` marks the cheap, valuable ones.

Always edit from the live body, never from memory (the user may have edited it on GitHub):
```sh
gh issue view 20 --json body -q .body > $S/ideas.md     # $S = session scratchpad
# edit $S/ideas.md with Edit, then:
gh issue edit 20 --body-file $S/ideas.md
```

## Add
- Check it is not already there (or already shipped: grep `openspec/specs` and the README).
- One line `- [ ] <idée>` under the fitting theme; a new `## theme` only if none fits. Show the line before saving.

## List
Show the open items by theme, priorities first. No edit.

## Start
- Run `/opsx:propose` with the idea's text as the starting point.
- Leave the box unticked; append ` — en cours : openspec/changes/<name>` to its line.

## Done (after `opsx:archive` and the `feat:` commit)
- Tick it: `- [x] <idée> — <short sha> (vX.Y.Z if released)`, drop the "en cours" note.
- When every box is ticked, ask before closing the issue.
