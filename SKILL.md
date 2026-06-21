---
name: cite
version: 3.15.0
description: Make a markdown post easier to READ and TRUST by inserting verified links, for the reader, not as proof. Three kinds, value-ranked: EXPLAIN a term a non-specialist reader would not know (link an authoritative explainer, e.g. "ast", "raft"); SUBSTANTIATE a claim about an external thing (link that thing's real page); or, rarely, SHOW code when seeing it illuminates a claim (a sha-pinned permalink). Every link must (a) resolve publicly AND (b) actually mean or back the thing in context; a live-but-wrong link is the worst output. cite is link-hygiene plus targeted explanation, NOT a fact-check of the whole document. Triggers: "cite this post", "add citations", "explain the jargon", "back up the claims", "make this post easier to follow". Auto-inserts; review the diff.
---

# cite

Make a markdown post easier to **read and trust**: explain the jargon, back up the claims, and (sparingly) show code, with verified links, inline. It is for the **reader**.

The agent makes every judgment call. A small helper, `cite`, does the error-prone mechanics (extract, verify, prove, lint, flag, permalink). **The helper only checks that a link is LIVE. Whether it is RIGHT is on the agent.**

## Setup

The helper is the `cite` script next to this file. Put it on PATH (`ln -s "$PWD/cite" ~/.local/bin/cite`) or call it by its path. Dependencies: `bash`, `git`, `curl`, `perl` (and `gh`, optional, only for repo-visibility checks in code mode). Run `cite help` for the command list.

## Quickstart

1. **Read** the post. Find what a *technical generalist* reader (literate, but not a specialist in this post's domain) genuinely needs: jargon to EXPLAIN, external claims to SUBSTANTIATE. **Under-link.** Zero links is a valid, common, correct outcome; never manufacture links to look productive. But do not leave the post's *central* term unlinked while citing a secondary one.
2. **Resolve** each candidate: web-search the authoritative source, then **open it and confirm it actually means the term or backs the claim in this post's sense.** A live, authoritative-looking, semantically-wrong link is the worst output this tool can produce.
3. **Flag, don't fabricate.** If a claim can't be backed or looks false, do not invent a link. Record it: `cite flag <post> <reason>`.
4. **Verify the links you ADD** (mandatory , a link you insert must resolve and be right). Just `cite verify <url>` each one.
5. **Insert** by wrapping the tightest existing phrase, **in the document's own format**. Markdown `[phrase](url)` by default, but if the doc is HTML use `<a href="url">phrase</a>`, and for rST/AsciiDoc/etc. use their link syntax , adapt ad hoc and tell the user you matched the format. Never rewrite prose. Only the insertion *syntax* changes: the judgment (what to link, the bar, the laundering trap) is format-agnostic, and the gates already handle it , `cite verify` is just urls, and `cite links`/`prove`/`lint` cover HTML `<a href>` as well as markdown, so calibrate and validate exactly as you would for markdown.
6. **Gate** before you are done (mandatory): `cite prove <post> <base>` (you changed only link markup) and `cite lint <post>` (no url-as-text half-fix). Both must pass. **Pass the base ref** (the branch point): a bare prove run *after* committing compares the file to its own commit and passes trivially.

7. **At completion, notice and offer , do NOT audit by default.** cite's job is the citations you ADDED, and those are already verified. The post may also have links the author wrote, which you did not touch. Don't validate them on every run; just notice them and offer: *"Added 3 citations (all verified). The post also has 12 existing links I didn't touch , want me to check those for rot?"* `cite links <post>` gives the count. Only if the user says yes do you run the audit.

**The audit (only on request):** `cite check <post> <base>` (or `cite links post.md | cite verify -`) verifies every pre-existing link too. Use it when the user accepts the offer, or when they explicitly ask to "review / improve the links in this post" (that ask IS the audit mode , verify + prove + lint over what's there). Fix or flag failures; never blindly strip them (see *dead vs gated*). Best-effort: link extraction covers the common + most exotic markdown forms, but an unusual one can slip, so it complements an eyeball, it does not replace one. It is never a gate on adding citations.

The sections below are the reference layer for the judgment calls in steps 1-3.

## The reader you assume

cite serves the **reader**, not the author. It can be run by the author on their own post or by a reader on someone else's, so it stays neutral: explain and substantiate, do not editorialize.

**Assume one specific reader: technically literate, but NOT a specialist in this post's domain** — a smart generalist developer. Link a term only if *that* reader plausibly would not know it. This single tiebreaker kills both "some novice might not know X" (everything fails that) and "an expert knows X" (everything fails that too). Pick the generalist and stay consistent.

> If you are the author's own agent and know what they care about, you may *flavor* the selection (surface a term or source they would want highlighted). A bonus, never the goal.

## The bar for every link

1. **It RESOLVES** — public, HTTP 200 (`cite verify`). The check is unauthenticated, so private and dead links fail.
2. **It is RIGHT** — the page genuinely means the term or backs the claim *in this post's sense*. `cite verify` cannot check this; you must open the page and read it. Example failure: linking "backpressure" to Wikipedia's exhaust-pipe article (returns 200, looks right, is wrong). For multi-sense terms (Wikipedia disambiguation, `_(computing)` pages), confirm you grabbed the right one. And a 200 is not necessarily CANONICAL: a url that redirects to another host, or an abandoned-but-live old page, means you may be citing a stale home — prefer where the redirect lands.
3. **It HELPS this reader** — more than no link does. If not, omit it. A handful of links per section, not per sentence. A missing link is fine; a useless, wrong, or credibility-laundering one is not.

## What to link (value-ranked)

1. **EXPLAIN a term** (highest value). A word or concept the assumed reader would not know (`ast`, `raft`, `io_uring`, `token bucket`) gets an authoritative explainer (Wikipedia, the official site, the canonical spec or paper). An explainer DEFINES a word; it does NOT vouch for the surrounding claim (see *the laundering trap*).
2. **SUBSTANTIATE a claim about an external thing.** A real tool, library, protocol, stat, or quote links to its authoritative page. This is where a wrong or invented link does the most damage.
3. **SHOW code** (rare; gated on CLARITY, not authorship). When *seeing the code* illuminates a claim ("you add a dialect by implementing this interface"), link a sha-pinned permalink — true whether it is the author's repo or someone else's. It must still be public and verified. Do NOT add proof-only code links ("it never opens a connection" → the source file does not help a reader).

## The laundering trap

An EXPLAIN or SUBSTANTIATE link makes the surrounding sentence *read as backed*, even when the link only defines a word. "I used the [raft protocol]" reads as vouched once it is a link. So:

- If the underlying claim is dubious, unverifiable, or about a thing that may not exist, do NOT sprinkle explainer links around it. cite makes TRUE content clearer; it does not dress up shaky content.
- Never place a link where it would FALSELY BACK or CONTRADICT the claim. "I invented the lru algorithm" — lru is decades old, so an lru explainer contradicts the sentence and falsely implies a source. Flag it; do not link around it.

**Decision test: is the sentence's CORE claim independently true?** If yes, explain its jargon freely. If no (the tool may not exist, the benchmark is unsourced, the superlative is unprovable), refuse even a perfect term-explainer. Worked example: "vortex uses a count-min sketch." A count-min sketch is a real term a generalist would not know, so in isolation it is a textbook EXPLAIN — but if "vortex" is unverifiable, you REFUSE the link, because linking it makes the whole sentence read as backed. The term being real is not enough; the sentence around it has to be true.

## Flag, don't fabricate

cite can only link a *true* claim. If the prose says something you cannot back — a tool the author did not make, a concept they did not invent, a stat with no source, a "spec" that does not exist, an API that may not be real — do NOT invent a plausible link. Surface it to the author, and record it durably: `cite flag <post> <reason>` appends to `.cite-flags.md` at the repo root, so the dead-link and dubious-claim inventory survives instead of evaporating into a chat reply. A confidently-wrong cite is the worst output.

**When you flag a pre-existing dead link, put its url in the reason.** `cite check` treats any verify failure whose url appears in `.cite-flags.md` as "flagged, known" rather than a gate failure — so a post with a correctly-flagged dead author link still reports PASS instead of contradicting the flag-don't-remove rule.

## What cite is NOT

cite is link-hygiene plus targeted explanation. It is NOT a fact-check of the whole document. It only inspects what it links; untouched claims (wrong code samples, bad API examples, typos, false assertions you did not cite) ride straight through. **A cite-passed post is NOT a verified-true post.** Never imply otherwise. If you happen to notice an obvious falsehood while working, flag it, but cite makes no promise to find them.

## Dead links, and fixing pre-existing ones

`cite links post.md | cite verify -` checks every link. A failure is not automatically a deletion:

- **Dead vs gated.** Some hosts (crates.io, repology, npm, badge and registry pages) return non-200 to an unauthenticated check yet load fine in a browser (bot- or JS-gated). To tell dead from gated *for real*, don't guess — confirm existence via a NON-gated authoritative source (a registry's sparse index or JSON API, e.g. `index.crates.io`, the crates.io API with a browser UA, npm's registry JSON). A 404 from the authoritative index means it genuinely never existed, even when the web page 403s.
- **A link YOU add must verify clean.** Find a working one or do not add it.
- **A PRE-EXISTING author link that fails is flagged, never auto-removed.** Obediently deleting the author's real links vandalizes a healthy doc. Even when one is confirmed dead, prefer a FIX over a delete: the live successor often sits right beside it in the same doc — surface the canonical replacement; else `cite flag` it.
- **Fix EVERY occurrence of a confirmed-dead url**, not just the first. The same url often repeats on another line, or as BOTH a link's href AND its visible text.
- **The half-fix:** when a link's visible text is itself a url, fixing only the href leaves the reader staring at and copying a dead url. Fix the text too, or leave the link clean. `cite lint` catches this; `cite prove` cannot (a url-to-url text change is a no-op to it).
- **Follow redirects to the canonical.** If `cite verify` reports `-> <final>`, link the final url, not the redirector (e.g. the Docker macvlan docs moved `/network` → `/engine`).

## The gates (mechanical, not gut-checks)

These exist because rules-as-prose did not stop the failures at scale; the checks do.

- `cite prove <file> [ref]` — strips every link to its visible text and asserts the prose is byte-identical to the ref (default HEAD). Fails on any prose edit, link-TEXT change, or line-ending churn. The don't-rewrite-prose contract, made verifiable. **Footgun:** run it BEFORE committing, or explicitly against the base (`cite prove <file> main`). A bare `cite prove <file>` after committing compares the file to its own commit and passes trivially.
- `cite lint <file>` — catches the half-fix prove cannot see (visible text is a url differing from its href). `cite lint <file> --fix` auto-syncs the visible text to the href (a url→url change, so it stays prose-safe).
- `cite flag <post> <reason>` — durable flag inventory (above).
- `cite check <post> [base]` — the OPTIONAL full audit: verify *every* pre-existing link, then prove (vs base), then lint, reporting PASS or ISSUES in one shot. Offer it as a bonus (tidy an old post / a foreign README); it is not the mandatory gate (prove + lint are), and it must never block adding good links. Best-effort on exotic link forms.
- `cite sweep <repo-dir> <base-ref>` — runs prove + lint over every `.md` changed vs the base and reports offenders. The harness backstop after a batch or corpus run, where per-post agent diligence is uneven; do not trust self-reports, sweep the whole diff.
- Add `--json` to `links`, `verify`, `lint`, or `check` for structured output; `--crosscheck` to `verify` to call dead-vs-gated via a host-root probe.

## Repo discovery (code mode only)

Works for the author's repo or a foreign one. Climb only as far as needed: know or infer the repo → read a `.cite` map if present (`name = owner/repo`, plus gotchas like "repo archived, code moved to X") → ask the user → record what you learn. `cite preflight <repo-dir>` reports slug, HEAD sha, pushed?, visibility, dirty. Unpushed HEAD → `cite permalink ... --ref origin/<branch>`. Private repo → do not cite it. Grep the named repo before trusting it; code moves and repos get archived.

## Known limits

- **Relative links** (`COMPAT.md`, `#anchors`) are not http, so `cite verify` skips them, and they break the moment a post is read outside its repo. `cite links --relative` surfaces them; absolutizing the load-bearing ones to a full canonical url is often the single highest-value fix on a foreign README.
- **`<img src>` badge images** are not citations; `cite links` excludes image markdown and image hrefs by design.
- **All clickable link forms are extracted:** inline `[t](url)` (including text that wraps across a line, and the outer target of a linked image `[![alt](src)](target)`), html `href`, reference defs `[label]: url`, angle-bracket autolinks `<url>`, and bare urls in prose , so none rides through verify unchecked. Image `src` is never emitted (images aren't citations). Caveat: editing a `[label]: url` target is a url-only change, so `prove` treats it as a no-op (link-hygiene, by design) — `verify` is what catches a dead/changed ref target.
- **Code spans and html comments are ignored.** Links inside fenced ``` blocks, `inline code`, and `<!-- comments -->` are NOT treated as real links by any command, so a doc that documents (or comments out) an example/dead url won't fail the gate, and `lint --fix` never rewrites content there.
- **Multi-line html anchors** (a `<a>` whose visible text spans newlines) are not caught by `cite lint` (the half-fix detector); rare, but eyeball them.
- **Deeply nested parens in urls** (two levels) are dropped by `cite links`; prefer a paren-free or redirect target when one exists.
- **verify cannot tell private from never-existed from typo** — all just fail. Reason about which it is: private → find a public source; nonexistent → the claim itself is suspect.
- **Semantic correctness is not mechanical.** prove and lint are link-MARKUP checks; a green from both does NOT mean a link is right. The right disambiguation, the canonical-not-just-live page, and flagging all still ride on agent judgment.

## Helper reference

```
cite links <file> [--relative] [--json]   every link url (markdown + html href), paren-safe, deduped, images excluded
cite verify <url> | cite verify - [--crosscheck] [--json]   resolves? HTTP code + dead-vs-gated hint + redirect landing (batch runs in parallel)
cite prove <file> [ref]                    assert ONLY link markup changed vs ref (default HEAD); fails on any prose edit
cite lint <file> [--fix] [--json]          catch (or auto-fix) the half-fix: visible text is a url differing from its href
cite flag <post> <reason...>               append a durable flag to .cite-flags.md at the repo root
cite check <post> [base] [--json]          one-shot: verify + prove + lint, reports PASS/ISSUES
cite sweep <repo-dir> <base-ref>           prove + lint over every .md changed vs base; harness backstop for a batch run
cite preflight <repo-dir>                  (code mode) slug, HEAD sha, pushed?, visibility, dirty
cite permalink <repo-dir> <path> <start> [end] [--ref origin/<branch>]   (code mode) sha-pinned, range-validated
cite version                               print the helper version (add --json)
```

`--json` gives structured output on links/verify/lint/check; batch `verify -` emits JSONL (one object per line, unordered), and errors emit `{"error":...,"ok":false}`. Most cites are EXPLAIN/SUBSTANTIATE: plain urls you find, read, verify, and insert. `preflight` and `permalink` are only for the rare code link.

## Worked example

Post says: *"We pipe events through a [token bucket] limiter, then fan out with goroutines."* (the brackets are not yet a link.)

1. **Candidates.** "token bucket" — a rate-limiting algorithm a generalist may not know → EXPLAIN. "goroutines" — Go concurrency primitive, borderline; a generalist Go-adjacent dev likely knows it → skip (under-link). "events"/"fan out" — plain English → skip.
2. **Resolve.** Search "token bucket algorithm", open `https://en.wikipedia.org/wiki/Token_bucket`, confirm the page is the rate-limiting sense (not a literal bucket) → right.
3. **Insert.** Wrap the existing phrase only: `[token bucket](https://en.wikipedia.org/wiki/Token_bucket)`. Prose untouched.
4. **Gate.** `cite check post.md main` → `links: 1 checked, 0 failed / prove: prose intact / lint: clean / => PASS`.

If instead the post had claimed *"using our [FooBucket] algorithm we invented"* and FooBucket is unverifiable, you would NOT link "token bucket"-style jargon around it (the laundering trap); you would `cite flag post.md "FooBucket algorithm: unverifiable, reads as invented"` and move on.
