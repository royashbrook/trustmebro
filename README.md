<!-- logo goes here once a direction is picked:
<p align="center"><picture><source media="(prefers-color-scheme: dark)" srcset="assets/logo-dark.svg"><img src="assets/logo.svg" width="200" alt="cite"></picture></p> -->

<h1 align="center">cite</h1>

<p align="center"><em>[citation needed], handled.</em></p>

<p align="center">
  <img src="https://img.shields.io/badge/license-MIT-111111?style=flat-square" alt="MIT">
  <img src="https://img.shields.io/badge/dependencies-0-111111?style=flat-square" alt="zero dependencies">
  <img src="https://img.shields.io/badge/node-%E2%89%A518-111111?style=flat-square" alt="node >= 18">
  <img src="https://img.shields.io/badge/runs%20on-mac%20%C2%B7%20linux%20%C2%B7%20windows-111111?style=flat-square" alt="cross-platform">
  <img src="https://img.shields.io/badge/tests-91%20passing-111111?style=flat-square" alt="91 tests">
</p>

<p align="center"><strong>adds verified citation links to a markdown post. every link resolves or it gets flagged, and it never rewrites your prose.</strong></p>

---

you wrote the post. cite is the one reading over your shoulder going "source?" , the calm librarian who, instead of just stamping `[citation needed]` in the margin, goes and finds the actual source, checks that it loads, links it inline, and hands you back a diff that proves it didn't touch a single one of your words.

it's an [agent skill](SKILL.md) plus a small zero-dependency node CLI. the agent makes the judgment (which claims need a source, which source backs each); the CLI does the error-prone mechanics (resolve, verify, wrap, prove).

## before / after

you write:

```
raft keeps the replicas consistent, and the io_uring submission queue stays hot.
```

cite hands back:

```
[raft](https://raft.github.io/) keeps the replicas consistent, and the
[io_uring](https://kernel.org/doc/html/latest/io_uring.html) submission queue stays hot.
```

same sentence. same words, same order. the only thing that changed is the link markup , and `cite prove` checks that mechanically, so "it didn't rewrite my prose" isn't a promise, it's a passing test.

## what it guarantees

cite's whole pitch is trust, so the guarantees are the point:

- **every link resolves, or it gets flagged.** a link is never inserted unless it returns HTTP 200. a dead or dubious one is recorded to `.cite-flags.md`, never faked.
- **it never rewrites your prose.** `cite prove` reduces the doc to its reader-visible text and asserts it's byte-identical to before , only link markup may change.
- **it's checkable, not vibes.** `prove` + `lint` are mechanical gates with exit codes. a "cite-passed" post is one a machine verified, not one an agent said was fine.
- **zero dependencies.** one node file, stdlib only. needs `node` (>=18) and `git`. runs on macOS, Linux, and Windows.

what it is NOT: a fact-checker. cite adds + verifies *links*; whether a claim is *true* is still on you. it under-links on purpose , a missing citation is fine, a wrong one isn't.

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
no. it adds *verified links*, not verified facts. a link can resolve and still be the wrong source , that judgment stays with you (and the agent). cite makes the post easier to *read and trust*, it does not fact-check it.

**will it touch my writing?**
no, and it proves it. `cite prove` fails if anything but link markup changed. that's the one rule the whole tool is built around.

**why not just let the agent paste links directly?**
because agents hallucinate urls, paste dead ones, and quietly reword your sentence while they're in there. cite is the part that refuses to do any of that.

**dependencies?**
node and git. that's it. no npm install, no lockfile, one file you can read in one sitting.

## license

[MIT](LICENSE). cite the source, not the license.
