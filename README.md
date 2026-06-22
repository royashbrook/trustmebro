<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="assets/logo-dark.svg">
    <img src="assets/logo.svg" width="200" alt="trustmebro">
  </picture>
</p>

<h1 align="center">trustmebro</h1>

<p align="center"><em>the end of "trust me bro."</em></p>

<p align="center">
  <img src="https://img.shields.io/badge/license-MIT-111111?style=flat-square" alt="MIT">
  <img src="https://img.shields.io/badge/dependencies-0-111111?style=flat-square" alt="zero dependencies">
  <img src="https://img.shields.io/badge/node-%E2%89%A518-111111?style=flat-square" alt="node >= 18">
  <img src="https://img.shields.io/badge/runs%20on-mac%20%C2%B7%20linux%20%C2%B7%20windows-111111?style=flat-square" alt="cross-platform">
  <img src="https://img.shields.io/badge/tests-95%20passing-111111?style=flat-square" alt="95 tests">
</p>

<p align="center"><strong>adds verified citation links for your jargon and claims , every link resolves or gets flagged, and it never rewrites a word.</strong></p>

---

you wrote something. maybe it has some jargon in it. maybe it should link out to source code. trustmebro checks over what you wrote and adds links in common-sense places. it's a tool for an agent to use to help refine your post for your reader. instead of just telling you a citation may be needed, trustmebro goes and finds the actual source, checks that it loads, links it inline, and hands you back a diff showing it only added citations and didn't fiddle with your prose.

yes, the name is the joke: every article is an author saying *trust me bro* to a reader. trustmebro is the part that means you don't have to , it hands the reader the receipts.

it's an [agent skill](SKILL.md) plus a small zero-dependency node CLI. the agent makes the judgment (which claims need a source, which source backs each); the CLI does the error-prone mechanics (resolve, verify, wrap, prove).

## what it cites

trustmebro makes three kinds of link, in value order. in every one the **words don't change** , only the link markup , and `tmb prove` checks that mechanically, so "it didn't touch my prose" is a passing test, not a promise.

**EXPLAIN** , a term a non-specialist reader wouldn't know gets an authoritative explainer:

```diff
- raft keeps the replicas consistent.
+ [raft](https://raft.github.io/) keeps the replicas consistent.
```

**SUBSTANTIATE** , a real tool / library / protocol / stat gets its authoritative page (where a wrong link does the most damage, so trustmebro is conservative here):

```diff
- we store everything in sqlite, one file on disk.
+ we store everything in [sqlite](https://www.sqlite.org/), one file on disk.
```

**SHOW code** (rare) , a claim about code gets a SHA-pinned, line-ranged github permalink that can't rot:

```diff
- the dialect pick lives in one small file.
+ the [dialect pick](https://github.com/royashbrook/sql-spider/blob/c06334e9a88eb9b82193d89cc6387df042c6e9dc/src/core/Dialect.cs#L1-L10) lives in one small file.
```

every link resolves before it goes in (`tmb verify`); a dead or dubious one is flagged, never faked. (and yes , every link in this README is one trustmebro itself verified.)

## what it tries to do

anyone reading an article has an author on the other side basically saying 'trust me' to the reader. this tool tries to make that 'trust me bro' assumption a bit more realistic by providing some links to things that are meaningful. it also helps for someone writing a technical post that may need to link out to github lines of code for specific things they mention. so the intention is to improve the reader experience, and save some time for the author. you may still need to add more things, but this helps. it will also 'improve' a link if let's say you point to a file but no sha and no lines, it will try and improve that link based on the agent's judgement. easy to revert if you don't like it.

so trustmebro isn't fully deterministic, and that's by design: the *judgment* , WHICH words deserve a link, and what the right source is , belongs to the agent reading your doc, the way it would belong to any editor, so different agents (or the same one with more context) may pick differently. the *mechanics* are the deterministic half: hand the `tmb` script a phrase and a url and it resolves, wraps, and proves the same way every time. judgment is the agent's; the receipts are the tool's.

## what it definitely does

- **every link resolves, or it gets flagged.** a link is never inserted unless it returns HTTP 200. a dead or dubious one is recorded to `.tmb-flags.md`, never faked.
- **it's checkable, not vibes.** `prove` + `lint` are mechanical gates with exit codes. a "trustmebro-passed" post is one a machine verified, not one an agent said was fine.
- **zero dependencies.** one node file, stdlib only. needs `node` (>=18) and `git`. runs on macOS, Linux, and Windows.
- **markdown or html.** point it at a post, a doc, a readme, an article , `.md` or `.html`. insert writes a `[markdown](link)` or an `<a href>` to match the file, and it skips code regions in both (fenced ```` ``` ```` / `` `inline` `` for markdown, `<pre>` / `<code>` for html).

## what it doesn't do

- **it never rewrites your prose.** `tmb prove` reduces the doc to its reader-visible text and asserts it's byte-identical to before , only link markup may change.
- **it doesn't fact-check.** trustmebro adds + verifies *links*; whether a claim is *true* is the reader's call, made from the source , not trustmebro's.
- **the suggestions aren't the tool.** an agent driving trustmebro might also propose other edits (a rewrite, a missing section); that's the agent's doing , the `tmb` script itself only ever touches link markup.

## install

```sh
node --version && git --version   # deps: node >=18 + git. nothing to npm install. missing one? see AGENTS.md.
git clone https://github.com/royashbrook/trustmebro
chmod +x trustmebro/trustmebro
# then put trustmebro/trustmebro on your PATH (it ships a `tmb` symlink too), or drop it in your agent's skills/tools dir
```

run it as `trustmebro` or the short alias `tmb` , same tool. on windows, or if the symlink doesn't survive your clone, just `alias tmb=trustmebro` (zero effort).

**Claude Code** (auto-loads as a skill): `git clone https://github.com/royashbrook/trustmebro ~/.claude/skills/trustmebro`
**any other agent:** see [AGENTS.md](AGENTS.md). then point it at [SKILL.md](SKILL.md) , that's the whole playbook.

## the helper

the agent decides *what* to cite; the script does the mechanics. the command is `trustmebro` (or `tmb` for short):

```sh
tmb verify <url> | tmb verify -    # resolves? HTTP code + dead-vs-gated hint + redirect (batch: parallel, JSONL)
tmb links <file>                   # every link url (md / html / refs / autolinks / bare), images excluded
tmb insert <file> <phrase> <url>   # safe add: verify url + wrap the FIRST citable match (skips code + existing links)
tmb prove <file> [ref]             # assert ONLY link markup changed vs ref , fails on any prose edit
tmb lint <file>                    # catch the half-fix: visible text is a url that differs from its href (--fix syncs it)
tmb flag <post> <reason...>        # record a dead link / dubious claim to .tmb-flags.md
tmb check <post> [base]            # optional one-shot: verify all links + prove + lint -> PASS/ISSUES
tmb sweep <repo-dir> <base>        # prove + lint over every changed .md , backstop for a batch run
tmb preflight / permalink          # (code mode) repo state / a SHA-pinned, range-validated github permalink
```

full doctrine + the judgment calls (what a *technical generalist* reader needs explained, the laundering trap, flag-don't-fabricate) live in [SKILL.md](SKILL.md).

## FAQ

**why call it trustmebro if it's the opposite of that?**
exactly , that's the joke. "trust me bro" is what every unsourced claim quietly says to a reader. trustmebro is the tool that means you don't have to say it: it hands them the source instead. (run it as `tmb`, and yes, you can `alias` it to whatever you like.)

**does it check whether my claims are true?**
no. it adds *verified links*, not verified facts. a link can resolve and still be the wrong source , that judgment stays with you (and the agent). trustmebro makes a post easier for a reader to *verify*, it does not fact-check it for them , that's the job, not a gap.

**will it touch my writing?**
no, and it proves it. `tmb prove` fails if anything but link markup changed. that's the one rule the whole tool is built around.

**why not just let the agent paste links directly?**
because agents hallucinate urls, paste dead ones, and quietly reword your sentence while they're in there. trustmebro is the part that refuses to do any of that.

**dependencies?**
node and git. that's it. no npm install, no lockfile, one file you can read in one sitting.

## license

[MIT](LICENSE). cite the source, not the license.
