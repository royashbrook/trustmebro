<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="assets/logo-dark.svg">
    <img src="assets/logo.svg" width="220" alt="cite">
  </picture>
</p>

<p align="center"><em>[citation needed], handled.</em></p>

<p align="center">
  <img src="https://img.shields.io/badge/license-MIT-111111?style=flat-square" alt="MIT">
  <img src="https://img.shields.io/badge/dependencies-0-111111?style=flat-square" alt="zero dependencies">
  <img src="https://img.shields.io/badge/node-%E2%89%A518-111111?style=flat-square" alt="node >= 18">
  <img src="https://img.shields.io/badge/runs%20on-mac%20%C2%B7%20linux%20%C2%B7%20windows-111111?style=flat-square" alt="cross-platform">
  <img src="https://img.shields.io/badge/tests-91%20passing-111111?style=flat-square" alt="91 tests">
</p>

<p align="center"><strong>adds citation links for common sense things. ensure all links resolve, flag failures. rewrites nothing.</strong></p>

---

you wrote something. maybe it has some jargon in it. maybe it should have some links to source code. cite checks over what you have written and adds things in common sense places. it's a tool for an agent to use to help refine your post to make things easier for your reader. instead of just letting you know a citation may be needed, cite goes and finds the actual source, checks that it loads, links it inline, and hands you back a diff showing it just added citations and didn't fiddle with your prose.

it's an [agent skill](SKILL.md) plus a small zero-dependency node CLI. the agent makes the judgment (which claims need a source, which source backs each); the CLI does the error-prone mechanics (resolve, verify, wrap, prove).

## what it cites

cite makes three kinds of link, in value order. in every one the **words don't change** , only the link markup , and `cite prove` checks that mechanically, so "it didn't touch my prose" is a passing test, not a promise.

**EXPLAIN** , a term a non-specialist reader wouldn't know gets an authoritative explainer:

```diff
- raft keeps the replicas consistent.
+ [raft](https://raft.github.io/) keeps the replicas consistent.
```

**SUBSTANTIATE** , a real tool / library / protocol / stat gets its authoritative page (where a wrong link does the most damage, so cite is conservative here):

```diff
- we store everything in sqlite, one file on disk.
+ we store everything in [sqlite](https://www.sqlite.org/), one file on disk.
```

**SHOW code** (rare) , a claim about code gets a SHA-pinned, line-ranged github permalink that can't rot:

```diff
- the dialect pick lives in one small file.
+ the [dialect pick](https://github.com/royashbrook/sql-spider/blob/c06334e9a88eb9b82193d89cc6387df042c6e9dc/src/core/Dialect.cs#L1-L10) lives in one small file.
```

every link resolves before it goes in (`cite verify`); a dead or dubious one is flagged, never faked. (and yes , every link in this README is one cite itself verified.)

## what it tries to do

anyone reading an article has an author on the other side basically saying 'trust me' to the reader. this tool tries to make that 'trust me bro' assumption a bit more realistic by providing some links to things that are meaningful. it also helps for someone writing a technical post that may need to link out to github lines of code for specific things they mention. so the intention is to improve the reader experience, and save some time for the author. you may still need to add more things, but this helps. it will also 'improve' a link if let's say you point to a file but no sha and no lines, it will try and improve that link based on the agents judgement. easy to revert if you dont' like it.

cite is not deterministic because it is an agent tool, so different agents may flag different things. but the script it runs is deterministic.

## what it definitely does

- **every link resolves, or it gets flagged.** a link is never inserted unless it returns HTTP 200. a dead or dubious one is recorded to `.cite-flags.md`, never faked.
- **it's checkable, not vibes.** `prove` + `lint` are mechanical gates with exit codes. a "cite-passed" post is one a machine verified, not one an agent said was fine.
- **zero dependencies.** one node file, stdlib only. needs `node` (>=18) and `git`. runs on macOS, Linux, and Windows.
- **markdown or html.** point it at a post, a doc, a readme, an article , `.md` or `.html`. insert writes a `[markdown](link)` or an `<a href>` to match the file, and it skips code regions in both (fenced ```` ``` ```` / `` `inline` `` for markdown, `<pre>` / `<code>` for html).

## what it doesn't do

- **it never rewrites your prose.** `cite prove` reduces the doc to its reader-visible text and asserts it's byte-identical to before , only link markup may change.
- it is NOT a fact-checker. cite adds + verifies *links* it doesn't provide any judgement
- when mixing this tool with an ai agent, it may offer suggestions, but that's not part of the tool

## install

```sh
node --version && git --version   # deps: node >=18 + git. nothing to npm install. missing one? see AGENTS.md.
git clone https://github.com/royashbrook/cite
chmod +x cite/cite
# then put cite/cite on your PATH, or drop it in your agent's skills/tools dir
```

**Claude Code** (auto-loads as a skill): `git clone https://github.com/royashbrook/cite ~/.claude/skills/cite`
**any other agent:** see [AGENTS.md](AGENTS.md). then point it at [SKILL.md](SKILL.md) , that's the whole playbook.

## the helper

the agent decides *what* to cite; the script does the mechanics:

```sh
cite verify <url> | cite verify -    # resolves? HTTP code + dead-vs-gated hint + redirect (batch: parallel, JSONL)
cite links <file>                    # every link url (md / html / refs / autolinks / bare), images excluded
cite insert <file> <phrase> <url>    # safe add: verify url + wrap the FIRST citable match (skips code + existing links)
cite prove <file> [ref]              # assert ONLY link markup changed vs ref , fails on any prose edit
cite lint <file>                     # catch the half-fix: visible text is a url that differs from its href (--fix syncs it)
cite flag <post> <reason...>         # record a dead link / dubious claim to .cite-flags.md
cite check <post> [base]             # optional one-shot: verify all links + prove + lint -> PASS/ISSUES
cite sweep <repo-dir> <base>         # prove + lint over every changed .md , backstop for a batch run
cite preflight / permalink           # (code mode) repo state / a SHA-pinned, range-validated github permalink
```

full doctrine + the judgment calls (what a *technical generalist* reader needs explained, the laundering trap, flag-don't-fabricate) live in [SKILL.md](SKILL.md).

## FAQ

**does it check whether my claims are true?**
no. it adds *verified links*, not verified facts. a link can resolve and still be the wrong source , that judgment stays with you (and the agent). cite makes a post easier for a reader to *verify*, it does not fact-check it for them , that's the job, not a gap.

**will it touch my writing?**
no, and it proves it. `cite prove` fails if anything but link markup changed. that's the one rule the whole tool is built around.

**why not just let the agent paste links directly?**
because agents hallucinate urls, paste dead ones, and quietly reword your sentence while they're in there. cite is the part that refuses to do any of that.

**dependencies?**
node and git. that's it. no npm install, no lockfile, one file you can read in one sitting.

## license

[MIT](LICENSE). cite the source, not the license.
