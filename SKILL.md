---
name: cite
version: 3.20.1
description: Insert verified links into a markdown post to make it easier to READ and TRUST, for the reader, not as proof. Three kinds: EXPLAIN a term a non-specialist would not know, SUBSTANTIATE a claim about an external thing, or (rarely) SHOW code via a sha-pinned permalink. Every link must resolve AND actually mean the thing in context (a live-but-wrong link is the worst output). NOT a fact-check of the document. Triggers: "cite this post", "add citations", "explain the jargon", "back up the claims", "make this post easier to follow". Auto-inserts; review the diff.
---

# cite

Insert **verified** links into a post so it is easier to **read and trust**: explain jargon, back up external claims, and (rarely) show code. For the reader, not as proof. **cite ADDS citations; it is NOT a fact-check of the document.**

The agent makes every judgment call; a small helper (`cite`) does the mechanics. **The helper only checks a link is LIVE; whether it is RIGHT is on you.**

## Quickstart

1. **Read** the post. Find what a *technical generalist* (literate, not a specialist in this domain) would not know: jargon to EXPLAIN, external claims to SUBSTANTIATE. Under-link, zero is a fine outcome, never manufacture links. Don't leave the post's *central* term unlinked while citing a secondary one , unless it has no honest target, then flag it (under-linking the center beats laundering it).
2. **Resolve** each: web-search the source, **open it**, confirm it means the term / backs the claim *in this post's sense*. A live-but-wrong link is the worst output.
3. **Flag, don't fabricate.** Can't back a claim, or it looks false? Don't invent a link: `cite flag <post> <reason>` (put the dead url IN the reason).
4. **Insert** each with `cite insert <file> <phrase> <url>` , it verifies the url, wraps the **first** occurrence of the phrase (errors if the phrase isn't found , the missed-add safety net; notes if it occurs several times), in the doc's format (markdown, or HTML `<a href>`; tell the user if you adapt). To target a specific later occurrence, pass a longer unique phrase. Never rewrite prose.
5. **Gate:** `cite prove <post> <base>` (only link markup changed) and `cite lint <post>` (no url-as-text half-fix). Both must pass. Pass the base ref, since a bare prove after committing self-passes.
6. **Offer, don't audit.** Your adds are verified. For the author's pre-existing links you did not touch, just count them (`cite links`) and offer: *"added 3 cites; 12 existing links i didn't touch, check those for rot?"* Run the full audit only on a yes.

## The reader you assume

A **technical generalist**: literate, but NOT a specialist in this post's domain. Link a term only if *that* reader would not know it. This one tiebreaker kills both "some novice might not know X" and "an expert knows X".

## The bar for every link

1. **RESOLVES** , public HTTP 200 (`cite verify`).
2. **RIGHT** , the page genuinely means the term / backs the claim in this post's sense. `cite verify` cannot check this; open it and read. Watch multi-sense terms (the `_(computing)` page, not the physics one), and prefer the canonical page over a stale-but-live one (follow the redirect).
3. **HELPS** , more than no link. Under-link: a handful per section, not per sentence.

## What to link (value-ranked)

1. **EXPLAIN** (highest) , a concept the reader would not know (`ast`, `raft`, `io_uring`) gets an authoritative explainer. It defines the word; it does NOT vouch the surrounding claim.
2. **SUBSTANTIATE** , a real tool / library / protocol / stat / quote gets its authoritative page. Where a wrong link does the most damage.
3. **SHOW code** (rare, gated on clarity not authorship) , when seeing the code illuminates a claim, a sha-pinned permalink. Public + verified. Skip proof-only code links.

## The laundering trap

An explainer link makes the surrounding sentence *read as backed*. So if a claim is dubious, unverifiable, or about a thing that may not exist, do NOT sprinkle explainer links around it , you would lend borrowed credibility. **Decision test: is the sentence's CORE claim independently true?** If no, refuse even a perfect term-explainer and flag it instead. (E.g. "vortex uses a count-min sketch": the term is real, but if "vortex" is unverifiable, linking it makes the whole sentence read as backed , refuse.)

## Flag, don't fabricate

Can't back a claim (a tool not made, a concept not invented, an unsourced stat)? Don't invent a link , surface it and record it: `cite flag <post> <reason>` appends to `.cite-flags.md` at the repo root. **Put the dead url in the reason:** `cite check` downgrades a verify failure whose url is flagged to "flagged, known" (not a gate failure), so a correctly-flagged pre-existing dead link still PASSes.

## What cite is NOT

Link-hygiene + targeted explanation, NOT a whole-document fact-check. It only inspects what it links; untouched claims ride straight through. **A cite-passed post is NOT a verified-true post.**

## Dead vs gated (when verifying)

A non-200 is not automatically dead. Some hosts (crates.io, npm, registries) 403 an anonymous check but load in a browser (bot-gated). Confirm via a non-gated source (a registry's json/index), or `cite verify --crosscheck` (probes the host root), before calling a link dead. A link YOU add must verify clean. A PRE-EXISTING author link that fails is FLAGGED, never auto-stripped; prefer fixing it to its canonical (often live nearby in the same doc), and fix every occurrence (href + visible text).

## Code mode (the rare code link)

Know or infer the repo, read a `.cite` map if present (`name = owner/repo`), or ask. `cite preflight <repo-dir>` reports slug / HEAD / pushed / visibility. Private repo, do not cite it. `cite permalink <repo-dir> <path> <start> [end] [--ref origin/<branch>]` builds a sha-pinned, range-validated link.

## Setup

The `cite` script is next to this file. Put it on PATH (`ln -s "$PWD/cite" ~/.local/bin/cite`) or call it by path. Needs `bash`, `git`, `curl`, `perl` (`gh` optional). Two roots: cite operates on **the post's** git repo (where prove / flag / check work). Clone the helper **outside** that repo (or gitignore it), so it does not get committed into the post's tree.

## Helper reference

```
cite verify <url> | cite verify -   resolves? HTTP code + dead-vs-gated hint + redirect landing (batch: parallel, JSONL). --crosscheck probes the host root.
cite links <file>                   every link url (md + html href + ref-defs + autolinks + bare), images excluded. --relative also lists relative targets.
cite insert <file> <phrase> <url>   safe add: verify url + wrap the FIRST literal match (md or html). errors on 0 (missed add); notes on multiples. no every-occurrence mode.
cite prove <file> [ref]             assert ONLY link markup changed vs ref (default HEAD); fails on any prose/text/whitespace edit.
cite lint <file>                    catch the half-fix (visible text is a url that differs from its href). --fix syncs it.
cite flag <post> <reason>           record a dead link / dubious claim (WITH its url) to .cite-flags.md.
cite check <post> [base]            OPTIONAL full audit: verify all links + prove + lint. Offer it, never auto-run, never a gate on adding links.
cite sweep <repo-dir> <base>        prove + lint over every changed .md , backstop after a batch run.
cite preflight / permalink          (code mode) repo state / sha-pinned permalink.
cite version
```

Add `--json` for structured output (links / verify / lint / check). Not caught (only matters for the optional audit; eyeball foreign docs): deeply-nested-paren urls, multi-line html anchors, html-entity hrefs.
