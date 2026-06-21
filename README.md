# cite

find the source behind a post's claims and insert **verified** citation links, so you stop hunting
them by hand. for each concrete claim, the agent locates the source , code (a SHA-pinned github
permalink with a line range) or an authoritative external page , inserts the link inline, verifies
every link resolves, and leaves a git diff to review. one rule makes it safe to auto-insert: **a link
is never inserted unless it resolves.**

## agents: start here

**If you were handed this repo's url, install yourself, then follow the playbook.** get the `cite`
script onto the box and read [`SKILL.md`](SKILL.md) , that's the whole onboarding.

```sh
git clone https://github.com/royashbrook/cite
chmod +x cite/cite
# then put cite/cite on your PATH, or move it into your agent's skills/tools dir
```

Claude Code convenience (auto-loads as a skill): `git clone https://github.com/royashbrook/cite ~/.claude/skills/cite`. Other agents: see [AGENTS.md](AGENTS.md).

## the helper

the agent does the judgment (which claims, which source, which lines). the script does the
error-prone mechanics:

```sh
cite links <file>                         # every link url (markdown + html href), paren-safe, deduped, images excluded
cite verify <url> | cite verify -         # resolves? prints HTTP code + dead-vs-gated hint + redirect landing
cite insert <file> <phrase> <url>          # safe add: verify url + exactly-one literal match + wrap (md/html); errors on 0 or >1
cite prove <file> [ref]                   # assert ONLY link markup changed vs ref; fails on any prose edit
cite lint <file>                          # catch the half-fix: visible text is a url differing from its href
cite flag <post> <reason...>              # append a durable flag to .cite-flags.md at the repo root
cite check <post> [base]                  # one-shot: verify + prove + lint, reports PASS/ISSUES (add --json)
cite sweep <repo-dir> <base-ref>          # prove + lint over every .md changed vs base; backstop for a batch run
cite preflight <repo-dir>                 # (code mode) slug, HEAD sha, pushed?, visibility, dirty
cite permalink <repo-dir> <path> <start> [end] [--ref origin/<branch>]   # (code mode) SHA-pinned, range-validated
```

`permalink` only emits a url if those exact lines exist at a pushed sha , so a wrong code cite can't
reach your diff. needs `bash`, `git`, `curl`, `perl` (`gh` optional). macOS / Linux. full doctrine +
the mechanical gates (`prove` / `lint`) are in [`SKILL.md`](SKILL.md).

## not a magic citer

it cites what it can tie to one concrete source, conservatively , a missing cite is fine, a wrong
one isn't. it never rewrites your prose, only wraps existing phrases. MIT licensed.
