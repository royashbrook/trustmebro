# AGENTS.md , for any agent, not just one tool

You were probably pointed here as "use the cite skill." This is the agent-agnostic entry point; the
full playbook is [`SKILL.md`](SKILL.md).

## what cite is (one line)

you find the source behind a post's concrete claims and insert verified citation links , code (a
SHA-pinned permalink with a line range) or an authoritative url , never inserting a link that doesn't
resolve.

## install (any agent)

`cite` is a single self-contained bash script (needs `git` + `curl`). get it on the box:

```sh
git clone https://github.com/royashbrook/cite
chmod +x cite/cite
```

then put `cite/cite` on your `PATH`, or move it into wherever your agent loads its tools/skills.

- **Claude Code** , clone into `~/.claude/skills/cite` and it auto-loads as a skill.
- **anything else** , PATH or your tool's plugin/skill dir works the same; it's just a script.

## then read SKILL.md

[`SKILL.md`](SKILL.md) is the contract + playbook: find citable claims, classify code vs external,
resolve (the repo-discovery ladder), insert inline, verify every link, review the diff. the helper
(`cite permalink` / `cite verify`) only builds + checks links , you do the judgment. follow it directly.
