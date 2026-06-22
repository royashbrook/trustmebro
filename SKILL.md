---
name: trustmebro
version: 5.0.0
description: Insert verified links into a markdown or html post so a reader can READ and VERIFY it (hand them the source to check a claim, don't ask them to take your word; not a proof of truth). Three kinds: EXPLAIN a term a non-specialist would not know, SUBSTANTIATE a claim about an external thing, or (rarely) SHOW code via a sha-pinned permalink. Every link must resolve AND actually mean the thing in context (a live-but-wrong link is the worst output). NOT a fact-check of the document. Triggers: "cite this post", "add citations", "explain the jargon", "back up the claims", "make this post easier to follow". Auto-inserts; review the diff.
---

# trustmebro

Insert **verified** links into a post (markdown or html) so a reader can **read and verify** it: explain jargon, back up external claims, and (rarely) show code. You hand the reader the source to check a claim; you do NOT ask them to take your word, and trustmebro does NOT decide if the claim is true. **trustmebro ADDS citations; it is NOT a fact-check of the document.**

The agent makes every judgment call; a small helper (`trustmebro`) does the mechanics. **The helper only checks a link is LIVE; whether it is RIGHT is on you.**

## Quickstart

1. **Read** the post and do a deliberate **jargon sweep**: every concept, tool, protocol, or algorithm a *technical generalist* (literate, not a specialist in this domain) would not know is an EXPLAIN candidate; external claims are SUBSTANTIATE candidates. The bias is split by type: be **thorough on EXPLAIN** (it's low-risk and trivially removable, and a reader stuck on an unlinked term is the real cost , so surface every genuine unknown), and **conservative on SUBSTANTIATE** (a wrong backing link does damage). Never manufacture a link , no honest source means don't. Don't leave the post's *central* term unlinked while citing a secondary one , unless it has no honest target, then flag it (under-linking the center beats laundering it).
2. **Resolve** each: web-search the source, **open it**, confirm it means the term / backs the claim *in this post's sense*. A live-but-wrong link is the worst output.
3. **Flag, don't fabricate.** Can't back a claim, or it looks false? Don't invent a link: `trustmebro flag <post> <reason>` (put the dead url IN the reason).
4. **Insert** each with `trustmebro insert <file> <phrase> <url>` , it verifies the url, wraps the **first** occurrence of the phrase (errors if the phrase isn't found , the missed-add safety net; notes if it occurs several times), in the doc's format (markdown, or HTML `<a href>`; tell the user if you adapt). To target a specific later occurrence, pass a longer unique phrase. Never rewrite prose.
5. **Gate:** `trustmebro prove <post> <base>` (only link markup changed) and `trustmebro lint <post>` (no url-as-text half-fix). Both must pass. Pass the base ref, since a bare prove after committing self-passes.
6. **Offer, don't audit.** Your adds are verified. For the author's pre-existing links you did not touch, just count them (`trustmebro links`) and offer: *"added 3 cites; 12 existing links i didn't touch, check those for rot?"* Run the full audit only on a yes.

## The reader you assume

A **technical generalist**: literate, but NOT a specialist in this post's domain. Link a term only if *that* reader would not know it. This one tiebreaker kills both "some novice might not know X" and "an expert knows X".

## The bar for every link

1. **RESOLVES** , public HTTP 200 (`trustmebro verify`).
2. **RIGHT** , the page genuinely means the term / backs the claim in this post's sense. `trustmebro verify` cannot check this; open it and read. Watch multi-sense terms (the `_(computing)` page, not the physics one), and prefer the canonical page over a stale-but-live one (follow the redirect).
3. **HELPS** , more than no link. Don't link a word the reader knows, and don't re-link the same term twice. But EXPLAIN is **per-concept, not rationed**: every *distinct* unknown term earns its one link, even several in a section. The thing to avoid is repetition and linking the obvious, not coverage.

## What to link (value-ranked)

1. **EXPLAIN** (highest) , every concept/tool/protocol/algorithm the reader would not know (`ast`, `raft`, `io_uring`, `knowledge graph`, `connected component`) gets an authoritative explainer. Sweep for these and don't ration them: an explainer is unambiguous (low risk) and one keystroke to delete, so erring toward including a real unknown term serves the reader. It defines the word; it does NOT vouch the surrounding claim (see the laundering trap).
2. **SUBSTANTIATE** , a real tool / library / protocol / stat / quote gets its authoritative page. Where a wrong link does the most damage.
3. **SHOW code** (rare, gated on clarity not authorship) , when seeing the code illuminates a claim, a sha-pinned permalink. Public + verified. Skip proof-only code links.

## The laundering trap

An explainer link makes the surrounding sentence *read as backed*. So if a claim is dubious, unverifiable, or about a thing that may not exist, do NOT sprinkle explainer links around it , you would lend borrowed credibility. **Decision test: is the sentence's CORE claim independently true?** If no, refuse even a perfect term-explainer and flag it instead. (E.g. "vortex uses a count-min sketch": the term is real, but if "vortex" is unverifiable, linking it makes the whole sentence read as backed , refuse.)

## Flag, don't fabricate

Can't back a claim (a tool not made, a concept not invented, an unsourced stat)? Don't invent a link , surface it and record it: `trustmebro flag <post> <reason>` appends to `.tmb-flags.md` at the repo root. **Put the dead url in the reason:** `trustmebro check` downgrades a verify failure whose url is flagged to "flagged, known" (not a gate failure), so a correctly-flagged pre-existing dead link still PASSes.

## What trustmebro is NOT

Link-hygiene + targeted explanation, NOT a whole-document fact-check. It only inspects what it links; untouched claims ride straight through. **A trustmebro-passed post is NOT a verified-true post.**

## Dead vs gated (when verifying)

A non-200 is not automatically dead. Some hosts (crates.io, npm, registries) 403 an anonymous check but load in a browser (bot-gated). Confirm via a non-gated source (a registry's json/index), or `trustmebro verify --crosscheck` (probes the host root), before calling a link dead. A link YOU add must verify clean. A PRE-EXISTING author link that fails is FLAGGED, never auto-stripped; prefer fixing it to its canonical (often live nearby in the same doc), and fix every occurrence (href + visible text).

## Code mode (the rare code link)

Know or infer the repo, read a `.tmb` map if present (`name = owner/repo`), or ask. `trustmebro preflight <repo-dir>` reports slug / HEAD / pushed / visibility. Private repo, do not cite it. `trustmebro permalink <repo-dir> <path> <start> [end] [--ref origin/<branch>]` builds a sha-pinned, range-validated link.

## Setup

The `trustmebro` script is next to this file. Put it on PATH (`ln -s "$PWD/trustmebro" ~/.local/bin/trustmebro`) or call it by path. Invoke it as `trustmebro` or the short alias `tmb` , the two are identical. Needs `node` (>=18, for built-in `fetch`) and `git` (`gh` optional). No bash/perl/curl , runs on macOS, Linux, and Windows. Two roots: trustmebro operates on **the post's** git repo (where prove / flag / check work). Clone the helper **outside** that repo (or gitignore it), so it does not get committed into the post's tree.

## Helper reference

```
trustmebro verify <url> | trustmebro verify -   resolves? HTTP code + dead-vs-gated hint + redirect landing (batch: parallel, JSONL). --crosscheck probes the host root.
trustmebro links <file>                   every link url (md + html href + ref-defs + autolinks + bare), images excluded. --relative also lists relative targets.
trustmebro insert <file> <phrase> <url>   safe add: verify url + wrap the FIRST literal match (md or html). errors on 0 (missed add); notes on multiples. no every-occurrence mode.
trustmebro prove <file> [ref]             assert ONLY link markup changed vs ref (default HEAD); fails on any prose/text/whitespace edit.
trustmebro lint <file>                    catch the half-fix (visible text is a url that differs from its href). --fix syncs it.
trustmebro flag <post> <reason>           record a dead link / dubious claim (WITH its url) to .tmb-flags.md.
trustmebro check <post> [base]            OPTIONAL full audit: verify all links + prove + lint. Offer it, never auto-run, never a gate on adding links.
trustmebro sweep <repo-dir> <base>        prove + lint over every changed .md , backstop after a batch run.
trustmebro preflight / permalink          (code mode) repo state / sha-pinned permalink.
trustmebro version
```

Add `--json` for structured output (links / verify / lint / check). To cite or flag a phrase that IS a flag token, end options with `--`: `trustmebro insert post.md -- --fix <url>`.

**Environment.** `TMB_JOBS` sets batch parallelism for verify / check / sweep (default 16, the one knob with no flag). `TMB_JSON` / `TMB_XCHECK` / `TMB_FIX` / `TMB_REL` mirror `--json` / `--crosscheck` / `--fix` / `--relative`.

**Works on markdown OR html** , a post, doc, readme, or article (`.md` / `.html`). insert writes a `[markdown](link)` for a `.md` file and an `<a href>` for a `.html` file (it keys off the extension; tell the user if you adapt). **Code regions** trustmebro skips = fenced ` ``` `/`~~~` blocks, inline `` `code` ``, html comments, and html `<pre>` / `<code>` blocks , NOT Markdown's 4-space-indented code blocks. Put code you don't want trustmebro to read/touch in a fenced (or `<pre>`) block. Other parser limits (optional-audit only; eyeball foreign docs): deeply-nested-paren urls, multi-line html anchors, html-entity hrefs, reference-style (`[text][ref]`) link bodies (insert/lint protect inline + html links, not ref-style).
