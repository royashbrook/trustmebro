# AGENTS.md , for any agent, not just one tool

You were probably pointed here as "use the cite skill." This is the agent-agnostic entry point; the
full playbook is [`SKILL.md`](SKILL.md).

## what cite is (one line)

you find the source behind a post's concrete claims and insert verified citation links , code (a
SHA-pinned permalink with a line range) or an authoritative url , never inserting a link that doesn't
resolve.

## dependencies , check first

`cite` needs exactly two things on the box: **`node` (>=18**, for built-in `fetch`) and **`git`**. it has
ZERO npm dependencies , there is nothing to `npm install`. check both:

```sh
node --version && git --version    # node must be v18 or newer
```

if one is missing, install it with whatever the box has (no project setup, just the binary):

```sh
# node (>=18):
brew install node            # macOS (Homebrew)
sudo apt-get install -y nodejs   # Debian/Ubuntu  (if the repo's node is <18, use nodesource or nvm/fnm)
winget install OpenJS.NodeJS # Windows
# no root? install node per-user: see https://github.com/nvm-sh/nvm or https://github.com/Schniz/fnm
# git: brew install git / sudo apt-get install -y git / winget install Git.Git
```

if you cannot install a dependency (no package manager, no permission), say so and ask the user , don't
guess. once `node --version` and `git --version` both work, continue.

## install (any agent)

`cite` is a single self-contained node script (needs `node` >=18 + `git`). get it on the box:

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
