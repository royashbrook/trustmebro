# cite , adversarial review log + backlog

5 rounds of adversarial cold-agent review (2026-06-20), per Roy's goal: iterate corrections + reviews
until the agents reach consensus the tool is useful, or 10 rounds. **consensus reached at round 5.**

## round history (findings shrank each round = convergence)

- **round 1 (v2 → v3):** 3 agents on foreign README / planted traps / code-spam bait. 7 findings:
  resolves-vs-right (the verified-but-wrong link), undefined-audience, EXPLAIN-laundering, misattributed
  concepts, "cite is not a fact-check" scope honesty, code-mode wrongly author-gated, html/parens blind
  spots. all folded into v3.
- **round 2 (v3 → v3.1):** both READY. 2 advisories: "drop any failing link" was unsafe (bot-gated
  hosts false-fail), and the laundering rule needed a decision-test. folded into v3.1.
- **round 3 (v3.1 → v3.2):** both READY (one NOT-READY was about the fake post, not the skill). bot-gated
  rule had a false-KEEP hole (confirm existence via a non-gated registry index); canonical-not-just-live.
  folded into v3.2.
- **round 4 (v3.2 → v3.3):** both READY. findings now all TOOLING: html `<a href>` not extracted,
  verify gave no code/hint scaffolding, flag-vs-drop ambiguity, prove-only-markup-changed. folded into
  v3.3 (helper grew `cite links` html extraction + `cite verify` code+hint; skill got prose-integrity +
  canonical-replacement).
- **round 5 (v3.3 → v3.4):** both READY, consensus. one soft finding (zero-links is a valid outcome ,
  folded in) + two deterministic ENHANCEMENTS (below), explicitly non-blocking.

verdicts across rounds 2-5: READY, READY, READY, (post-not-tool), READY, READY, READY, READY.

## corpus round (v3.4 -> v3.5): cite run on all 244 royashbrook.com posts + 4-lens adversarial review

a real-world pass: 31 agents cited the whole blog corpus in place, then 4 reviewers (over-cite/laundering,
dead-link/canonical, prose-integrity, under-cite) sampled the result. cite's link JUDGMENT passed well
(~85% over-cite, ~85-90% dead-link, ~70% under-cite; under-links hard, zero laundering, strong canonical
chasing). but it surfaced real failures, all folded into v3.5:

1. **BLOCKING , a prose edit self-certified as markup-only** (`dumb-` -> `super-simple` on the blame post,
   committed claiming markup-only). the "prove the diff is markup-only" step was a gut-check and the
   attestation was simply false. FIX: `cite prove <file>` , mechanical gate, strips links to visible text
   and asserts byte-identical-to-HEAD prose; fails on any prose edit, link-text change, or line-ending churn.
2. **dead-link half-fix** (heroku: href repointed to canonical but the visible anchor text left as the dead
   url; plus the identical dead link one line below missed). FIX: skill rule , fix EVERY occurrence of a
   confirmed-dead url (href AND visible text AND other lines), or leave clean.
3. **under-cite, central term skipped** (the bitwise-logic post left wholly untouched , its own subject
   unlinked and its pre-existing dead links never verified). FIX: skill , link the post's CENTRAL term
   first; never fully skip an in-scope post (at minimum verify its pre-existing links).
4. **non-canonical redirect target** (macvlan link pointed at a 301 redirector). FIX: `cite verify` now
   surfaces the redirect landing url (`-> <final>`) so the agent links the canonical home.
5. **nit, CRLF churn** from agent editing tooling on ~10 posts , now caught for free by `cite prove`
   (line-ending change != prose, so prove fails on it).

## large-batch corpus round (v3.5 -> v3.6): 8 agents x ~31 posts, all 244 + re-review

the at-scale pass that worked , larger batches dodged the burst rate-limit that killed the 31-agent run.
8/8 batches, 244 posts, +45 links, 39 dead fixed, 111 flagged, 178 untouched. **all 66 edited files pass
cite prove** (harness-swept independently, not agent self-report) , the v3.4 prose-integrity failure is
fully closed. review ~88-94% per lens. two residuals prove/skill-prose couldn't stop, fixed in v3.6:

1. **the half-fix recurred (~5 posts)** despite v3.5's rule , href fixed, visible dead-url text left.
   prove can't catch it (url->url text is a no-op to it by design). FIX: `cite lint <file>` , mechanical
   detector for a link whose visible text is a url differing from its href. rules-as-prose didn't stop it;
   a check does.
2. **flags evaporated** , 111 dead-pre-existing-links / dubious claims surfaced only in agent reports and
   were lost (aggregated to a count twice). FIX: `cite flag <post> <reason>` appends to `.cite-flags.md`
   at the repo root , the inventory persists.

still open (process, not tooling): **skipped-post under-verification** , at 31 posts/agent a few in-scope
posts (Riak central-term miss, EA/appharbor dead links) got skimmed. smaller batches cite deeper but hit
the rate limit; bigger dodge it but skim. mitigation = a harness sweep (`cite lint`/`prove`/`verify` over
ALL posts post-run) to catch skipped ones, not agent diligence.

## dual review (v3.6 -> v3.8): the running code AND the skill-as-authored-artifact (+ mcp lens)

5 cold agents: 2 hammered the CLI / verified the gates on the real corpus, 3 judged SKILL.md as a doc
an outsider could use via MCP. verdict: strong doctrine, solid core, real edge-bugs + a delivery problem.

v3.7 (code bugs, all fixed + tested):
- `cite links` missed single-quoted html href (rode through unverified) while `cite lint` matched it (with
  a spurious quote) , unified the href regex (', ", or none) across links/lint; both now EXCLUDE images
  (negative-lookbehind on `!`), fixing v3.6's lint false-positive on a pre-existing image whose alt was a url.
- `cite verify -` under-trimmed whitespace (one trailing char) , a url with stray spaces false-FAILed; now
  trims properly. single-url verify now prints the ok/redirect line (matched the documented behavior).
- `cite permalink` emitted invalid `#L0` and backwards `#L4-L2` (added start>=1 + start<=end) and miscounted
  a file with no trailing newline via `wc -l` (now `awk NR`), which had wrongly rejected its last line.

v3.8 (delivery + harness):
- SKILL.md rewritten as a clean agent-to-agent spec (Roy: a public skill is by agents for agents, not in
  his voice): quickstart + setup at top, the ~35% triplication cut (the old "contract" folded in), the
  giant flow-step-5 broken into labeled dead-link rules, real punctuation instead of comma-as-em-dash.
- `cite sweep <repo-dir> <base>` , runs prove + lint over every changed .md after a batch/corpus run.
  the harness backstop, since per-post agent diligence is uneven (the gates' self-reports can't be trusted;
  the corpus run produced zero `.cite-flags.md` despite flag-worthy items).
- documented the prove footgun (run vs the BASE / pre-commit, not bare HEAD post-commit, or it self-passes).
- README command list refreshed to the full set.

mcp: judgment lives in SKILL.md prose and must travel as an MCP PROMPT/resource, not as tool descriptions,
or you ship the safe-but-dumb half. permalink/preflight/flag are local-git/fs (don't remote); file-takers
need inline-content variants; output should go `--json`. PLAN (Roy): build this as a separate MCP MIRROR
that wraps the helper + serves the judgment as a prompt , do NOT bake mcp shape into the skill/helper.

still open (process, not tooling): semantic correctness (the 1TB live-but-wrong redirect-to-index) is
structurally invisible to prove+lint; mitigated by `cite sweep` + verify, not eliminated. it rides on agent
judgment by design , cite is link-hygiene, not a fact-check.

## independent "is it perfect" pass (v3.9 -> v3.10): 5 fresh agents, real holes found

asked 5 cold agents to either find a real flaw or concede it is sound. they did NOT rubber-stamp , two
serious bugs + several real ones, all fixed in v3.10:

- **`cite verify -` silently passed any url > 255 bytes** , the parallel batch used `xargs -I{}`, whose
  BSD replstr limit DROPS long lines; a long dead url returned rc=0/PASS with no output, breaking the
  core gate (and check/sweep/the documented pipe). FIX: `xargs -P 8 -n1` (positional arg, no length cap).
- **reference-style links were invisible** , `cite links` only saw inline + html, so a `[text][label]`
  doc certified PASS with zero fetches (the adjudicator's catch: unchecked-but-vouched, the worst class).
  FIX: extract `[label]: url` reference definitions too.
- **`cite check` conflated prove failures** , reported "PROSE CHANGED" for not-in-git / file-absent-at-base
  / real-prose-change alike; a clean NEW post vs its branch point read as ISSUES. FIX: check distinguishes
  prove-inapplicable (skipped) from a real change, in text and json.
- **--json hardening** , code field was number(200)/string("404") , now always string; `die` emits
  `{"error":...,"ok":false}` under --json; `check --json` embeds failed_urls + offenders (self-sufficient);
  `_jesc` escapes all control chars (valid JSON); batch verify documented as JSONL; added `cite version`.

51 tests green (+7). doc: quickstart step 6 surfaces the base-ref footgun; known-limits notes ref-style
coverage (+ the prove-url-no-op caveat) and the multi-line-html-anchor lint blind spot.

deferred to the MCP MIRROR (not the helper): a full structured error envelope on EVERY path (usage/arg
errors still go to stderr), a declared schema_version, and collecting batch JSONL into an array , these
are mirror-shape concerns, per Roy's "mcp shape lives in the mirror, not the skill."

## confirming pass (v3.10 -> v3.11): fixes hold, but fresh agents found a NEW class

4 agents: one independently re-verified all four v3.10 fixes hold (real repros, suite green); the others
hunted fresh. they did NOT rubber-stamp , a new class the prior 9 rounds missed, all fixed in v3.11:

- **code-fence / inline-code blindness** , every extractor scanned raw bytes, so a link inside ``` or
  `inline code` was treated as real. Two harms: (a) a doc documenting an example/dead url FAILED the gate
  (false ISSUES), and (b) the dangerous inverse , `lint --fix` REWROTE a teaching example inside code,
  and `prove` certified it green (url->url is a no-op to prove). FIX: `_mask_code` strips fenced + inline
  code before extraction in links + lint; `lint --fix` uses a code-span-first alternation so it never
  rewrites inside code.
- **autolinks + bare urls not extracted** , `<https://x>` and bare prose urls render clickable but were
  invisible, so a dead one rode through check as PASS (same unchecked-but-vouched class as the v3.10
  ref-style hole, just two more forms). FIX: cmd_links now extracts both (code-masked).
- **check vs flag-don't-remove contradiction** , a correctly-FLAGGED pre-existing dead link still failed
  check, contradicting the headline rule. FIX: `cite check` treats a verify failure whose url is in
  `.cite-flags.md` as "flagged, known", not a gate failure (flag the dead link WITH its url).

61 tests green (+10). nits left on the record (not fixed): html-entity-in-href verified literally,
url-with-interior-space word-split in batch, prove over-strict on a ref-label rename (conservative, never
lets bad content through).

## backlog , deterministic enhancements (non-blocking, surfaced round 5)

worth building when cite gets more investment; the skill's prose already mandates the manual versions,
and a careful agent reaches the right answer without them.

1. **`cite verify --crosscheck` (root-probe gated-vs-dead).** today the dead-vs-gated call is the
   agent's manual cross-check. mechanize it: on a non-200, also probe the host root , `root also 403 ->
   likely host-wide gate (keep, confirm existence)`, `root 200 + page 404 -> likely dead`. turns a
   reassuring-but-passive hint into a deterministic verdict, closing the "weaker agent rubber-stamps all
   403s as gated" risk.
2. **`cite links --relative` (surface repo-relative links).** `cite links` emits only `http(s)://`, so
   repo-relative links (`LICENSE-APACHE`, `#anchors`) are invisible to both verify and the inventory ,
   yet absolutizing them is often the highest-value fix on a foreign README read outside its repo. emit
   them (separately / on stderr) so the agent can absolutize by hand instead of eyeballing raw markdown.

## what held up under fire (don't regress these)

the judgment core converged and was battle-tested: reader-first + the generalist-reader tiebreaker,
under-link (incl. zero), explain > substantiate > show-code, the laundering trap + its decision-test,
flag-don't-fabricate (incl. misattributed concepts), resolves-AND-right, public-only, dead-vs-gated via
non-gated cross-check, don't-rewrite-prose-and-prove-it. these are the spine.

## confirming pass (v3.11 -> v3.12): fixes hold, three more extractor edges found

3 agents: one verified all v3.11 fixes hold (SOUND, fresh repros, suite green). the other two found three
more real holes, ALL in the one regex link-extractor, all fixed in v3.12:

- BLOCKING: a markdown link whose visible TEXT spans a soft line break was invisible , cmd_links was
  line-mode (`perl -ne`) while its siblings _strip/_lint_scan slurp (`-0777`); the `[^\]]*` text class
  only crosses a newline in slurp mode. a dead multi-line-text link certified PASS. FIX: cmd_links now
  slurps too (-0777, /m on the ^-anchored patterns).
- REAL: linked-image / clickable badge `[![alt](src)](target)` , the inline regex matched `[![alt](src)`
  and emitted the IMAGE SRC while the real outer TARGET rode through unchecked (a dead badge target = PASS).
  bites hardest on badge-dense foreign READMEs, which the blog-post corpus rounds never exercised. FIX:
  collapse `![alt](src)` -> alt before extraction, so images vanish (src never emitted) and the outer
  target is exposed.
- REAL: html comments not masked , a link inside `<!-- ... -->` doesn't render but was extracted + failed
  (false ISSUES on a commented-out link). FIX: _mask_code strips `<!-- ... -->` (and lint --fix protects it).
- nit: the VERSION constant lagged SKILL frontmatter (said 3.10.0); now synced.

67 tests green. CONVERGENCE NOTE: every recent pass closes the real holes and the next finds a narrower
markdown form (ref-style -> autolinks/bare -> code-fences -> multi-line/linked-image/html-comment). a
regex extractor has an irreducible long tail; "provably complete" extraction means a CommonMark-AST
parser, which trades the bash+perl lightweight contract. the gates (prove/lint) and judgment core are
sound; extraction is best-effort-regex with a shrinking, documented tail.

## scope resolution (v3.13): the full link-audit is OPTIONAL, never a gate

the convergence question (regex extraction has an asymptotic markdown-edge tail , chase it forever, or
rebuild on a CommonMark parser and lose the lightweight contract?) went to Roy. his call reframed the
whole thing: cite's MAIN job is adding sensible links (pure agent judgment, no extraction involved). the
exhaustive "verify every pre-existing link in the doc" is a separate AUDIT feature , and it should be
OPTIONAL, offered to the user, and must NEVER hang up the main purpose.

so the doctrine, settled:
- MANDATORY gate: the links you ADD resolve + are right; `cite prove` (no prose changed); `cite lint`
  (no half-fix you introduced). these are cheap, exact, and never about exotic markdown forms.
- OPTIONAL bonus: `cite check` / `cite links | cite verify -` audits every pre-existing link for rot.
  best-effort (the extraction tail lives ONLY here), offered as a courtesy, never blocking.

this dissolves the asymptote: the regex tail only ever affected the optional audit, not the core job. no
CommonMark-parser rebuild needed; the lightweight bash+perl contract stays. the adversarial loop closes
here , the agents had shifted to mining markdown-parser trivia in a secondary path.

## clarity + simplicity pass (v3.15 -> v3.16): a real bug + a 40% trim

3 cold agents (ruthless editor / cold mission-reader / features critic). verdict: mission clear, name strong,
feature-complete for its scope, but one real bug + heavy redundancy:

- REAL BUG (false PASS): `cite check`'s flag-downgrade used a substring `grep -qF`, so flagging a LONGER url
  silently vouched a SHORTER dead url that is its prefix (e.g. flag /page-two -> /page rides through as
  "flagged, known"). reopened the unchecked-but-vouched hole in flag matching. FIX: `_flagged` extracts urls
  from .cite-flags.md and EXACT-matches (grep -oE | grep -qxF). + `cite flag` now warns if the reason has no
  url (the downgrade key would be missing).
- SIMPLICITY: SKILL.md said every rule 3-4 times (137 lines / ~4.6K tokens). rewrote to one-home-per-rule:
  led the description + body with a plain one-line WHAT, moved Setup below the Quickstart, cut the
  worked-example section, halved known-limits, folded the link-form inventory + the audit rule + the
  live-but-wrong rule to single homes. ~40% shorter, zero load-bearing rule lost.

noted, not built (in-scope future): a diff-aware "verify only the links I ADDED" mode (so the mandatory
gate matches the agent's responsibility without fusing the optional audit); `cite flag --url` as a
first-class arg; relative-link absolutize using the known slug. all natural in-mission extensions.

## varied-content pass (v3.16 -> v3.17): a blocking bug, a missing feature, a friction cluster

5 cold agents each wrote + cited a DIFFERENT realistic doc (tutorial / opinion essay / badge-heavy README /
HTML article / breaker). all confirmed cite handles real varied content well and stays out of fact-checking.
findings, all addressed:

- BLOCKING: `cite lint --fix` silently corrupted code inside `~~~` (tilde) fences , `_mask_code` protected
  both fence styles but the two --fix regexes protected backtick-only, reopening the v3.11 "dangerous
  inverse" for tildes. FIX: both --fix regexes now protect `(?:`|~){3,}` fences (+ indented).
- MISSING FEATURE (3 agents): the ADD half had no safety net , a silently-missed insertion passed every
  gate. FIX: `cite insert <file> <phrase> <url>` , verifies the url, requires an EXACTLY-ONE literal match
  (0 or >1 errors), wraps in the doc's format. the add now has the same mechanical floor the hygiene half had.
- friction cluster: removed the flag url-warn (misfired on legit url-less CLAIM flags , 3 agents);
  `cite check` text output now LISTS the failing urls (was: "re-run for detail") and surfaces a
  "flags recorded" count (observability for url-less claim flags, which no gate can confirm); softened the
  verify redirect note to "open the final page and confirm it still means the term" (an AWS-docs redirect to
  a stripped index was steering toward a live-but-wrong link); SKILL Setup now says clone the helper OUTSIDE
  the post repo (cloning inside committed it as a gitlink); added the central-term-vs-launder caveat to step 1.
70 tests green.

## tightened cycle (v3.17 -> v3.18): the insert feature we just shipped had a BLOCKING bug

mandate changed to failure-and-refusal only (no wishlist), run cold across copilot + 2 claude subagents.
copilot cited fine (cross-model still holds). the claude runs found a blocking bug + doc drift , and it was
in `cite insert`, the v3.17 addition. proof that every new feature breeds the next cycle's finding.

- BLOCKING (corrupted-but-vouched): `cite insert` did a raw whole-file substitution , it wrapped a phrase
  inside a `code` span / fence (e.g. `pip install [requests](url)`), and `prove` certified it clean (it
  stripped the in-code link to text on both sides = a no-op). the same divergence class as the tilde bug:
  code-protection lived in _mask_code but insert + prove's _strip were never wired to it.
- FIX (structural, kills the divergence class): ONE shared code-region pattern `CITE_CR`, consumed by
  _mask_code, _strip, cmd_insert, and both lint --fix regexes. insert now wraps the first occurrence
  OUTSIDE code AND outside an existing link (also fixes the double-insert `[[x](u)](u)` nesting bug),
  erroring if there's no citable occurrence. _strip leaves code regions verbatim, so a link injected into
  code shows as a diff and prove FAILS instead of self-passing.
- doc drift (A-1b): README/comment said insert "errors on >1"; it links the first (v3.17.1). corrected.
- footgun nudge (A-1d): a bare `cite prove` after committing self-passes; prove now notes when the file is
  identical to HEAD and tells you to pass the base ref.
73 tests green (+3, incl. insert-in-code, prove-catches-in-code, double-insert-no-nest). the laundering
false-confidence (A-1a) is the documented is-it-right ceiling, not a defect , gates check mechanics, not judgment.

## engineering review (v3.18 -> v3.19): stay bash, but fix the measured perf + portability holes

aggressive 4-lens arch review (portability / performance / language / scope). STRATEGIC verdict, all four
converged: STAY bash+perl, ONE tool. don't rewrite (rust/go/dotnet) , the consumer git-clones a skill, so a
binary worsens distribution; deps are universal on mac/linux/CI; speed is network-bound; a rewrite discards
18 versions + 73 tests of behavioral hardening for a green binary. the only pro-rewrite axis (regex tail) was
already quarantined to the optional audit (v3.13). don't split url-validation (one 12-line curl wrapper behind
verify+insert; splitting breaks insert's verify contract). the real boundary , mechanics (script) vs judgment
(SKILL.md) , is already made. sql-spider being dotnet is a different consumer.

but the perf/portability lenses MEASURED real holes, all fixed:
- BLOCKING (fail-open): a perl-less box made every perl call silently no-op (2>/dev/null), so prove/insert
  PASSED while doing nothing. FIX: a dispatch preflight hard-fails loudly if perl is missing; _probe does the
  same for curl. (the dangerous failure was open, not closed.)
- BLOCKING (perf): --json built arrays with one perl spawn PER url (links/lint/check) , 200-1800x slow
  (links --json: ~9s -> 0.04s on a 1500-url file). FIX: _json_arr / _json_objs build the array in ONE perl
  pass; cmd_check's double _lint_scan deduped to one.
- verify parallelism 8 -> 16 (tunable via CITE_JOBS), + dedupe urls before fan-out + busybox fallback (no
  -P -> sequential instead of erroring). measured ~7.7s -> ~5.4s on 100 urls.
- replaced prove's diff <(...) process-substitution (a bashism) with a temp-file diff (dash/busybox-safe).
73 tests green. (also: README still scopes macOS/Linux; native Windows needs WSL/git-bash + perl , now a
loud preflight, not a silent pass.)

## v3.19 -> v3.20: the v3.19 changes bred 3 findings (2 fail-opens), all closed

a breaker round aimed only at the v3.19 changes. clean on the prove temp-file diff + the check ffail/loff
refactor. three real findings, two of them fail-opens (the dangerous class):
- FAIL-OPEN (CITE_JOBS): a bad CITE_JOBS (typo: auto / -5 / garbage) sailed past the hardcoded `-P 2`
  probe, then real `xargs -P <bad>` errored -> empty output -> swallowed by 2>/dev/null -> verify reported
  SUCCESS on dead links, flipping check/sweep from ISSUES to PASS. FIX: validate CITE_JOBS (positive int)
  at DISPATCH (before check/sweep can swallow it); probe with the REAL jobs value not a hardcoded 2; and
  guard cmd_verify + cmd_check so a non-empty input that yields no output reads as FAILURE, never all-clear.
- FAIL-OPEN (preflight): the perl gate tested `command -v perl` (presence), so a present-but-broken perl
  (stub / corrupt / wrong-arch) passed, then every perl call no-opped -> prove/lint PASS on tampered input.
  FIX: probe `perl -e1` (perl actually RUNS), which catches absent AND broken.
- divergence: _json_arr/_json_objs emitted 	/ for tab/CR where _jesc emits \t/\r (both valid
  JSON, same decoded char, but not byte-identical to the contract). FIX: mirror _jesc's escape order exactly.
documented won't-fix nits confirmed: deeply-nested-paren urls (SKILL line 77, optional-audit only), lint
--fix drops the human label (by design). process nit: tag releases (no v* tags existed) , done from v3.20.0.
73 -> 76 tests green.

## v3.20.1 -> v3.20.2: the confirming round caught that the v3.20 perl fix was INADEQUATE

honest correction: v3.20.0 claimed `perl -e1` "catches absent AND broken" perl. it does NOT. a stub /
wrong-arch / corrupt perl can satisfy the trivial `-e1` yet no-op or error on the real `-0777 -pe` slurp
mode, so the SAME fail-open reopened , prove reported "prose intact" on a full rewrite, and check PASSed a
dead-link+changed-prose post (cmd_links returns empty under broken perl -> nlink=0 -> the v3.20 check guard
never fires). both BLOCKING, both rooted in one bad probe. FIX: gate with the ACTUAL work mode , a
`printf A | perl -0777 -pe 's/A/B/'` round-trip that must yield B, which a no-op/erroring perl fails. that
closes prove/check/lint/links + the json-url-blanking, all of which were downstream of the same blind spot.
also REAL (over-reach): the v3.20 CITE_JOBS validation ran for EVERY command, so a stray CITE_JOBS=auto in
the env falsely killed links/prove/lint/insert/flag/permalink (none use parallelism). FIX: scope the
CITE_JOBS check to verify/check/sweep only (still at dispatch, so check/sweep can't swallow it).
defenses that HELD (verified, not re-investigated): insert fails closed under broken perl; lint --fix fails
closed; huge CITE_JOBS dies; $0 with a space is xargs-robust. +2 tests (broken-perl-caught, CITE_JOBS-scoped).

## v3.20.2 -> v3.20.3: convergence round , perl + CITE_JOBS confirmed CLEAN; fresh eyes found the flag parser

the tight convergence round confirmed the two prior fixes hold: the perl work-mode round-trip gate is clean
(no false-die on odd-but-working perls, no slip on realistically-broken ones), and CITE_JOBS scoping is
clean (consuming set is actually {verify,check}; gated {verify,check,sweep} is a safe superset, sweep
over-gates but fails LOUD not open). but fresh eyes found one REAL pre-existing bug (predates the v3.20.x
work): the global flag parser is greedy + position-independent with no end-of-options escape, so a
phrase/reason that exactly equals a flag token (--json/--fix/--crosscheck/--relative) is silently swallowed
AND flips the mode , e.g. `cite insert post.md --fix <url>` citing a literal CLI flag name. silent data
loss. FIX: honor `--` as end-of-options (everything after is verbatim): `cite insert post.md -- --fix <url>`.
documented in usage + SKILL. 78 tests green. CONVERGENCE READ: the core (cold-e2e + wide-correctness) has
been clean for multiple rounds; findings are now narrow pre-existing edges surfaced by fresh eyes.

## v3.20.3 -> v3.20.4: final round , perl confirmed load-bearing; closed a prove fail-open + a links gap

the final round answered the perl question with evidence: perl is genuinely load-bearing (every call needs
slurp/multi-line/non-greedy/split-with-capture awk/sed can't do; the lone line-wise call shares escaping
with the json builders so splitting it would fork the logic), and a perl-less box fails LOUD on every real
subcommand (exit 1 + message, no silent success). two real findings, both bare-url handling, both closed:
- WORKING-PERL FAIL-OPEN in prove/check/sweep: _strip tokenized EVERY url to <URL>, so repointing a BARE
  url or an angle-bracket AUTOLINK (where the url IS the reader-visible text) passed as 'prose intact'. fix:
  tokenize a url ONLY when it's a LINK's visible text (preserves the heroku half-fix no-op) and mask ref-def
  targets, but leave bare urls + autolinks intact so changing them correctly FAILS prove.
- links missed a bare url preceded by '(' (e.g. '(https://x)'), so check could certify a paren-wrapped dead
  link as PASS. fix: allow '(' / '[' as a leading delimiter in the bare-url scan.
82 tests green (+prove-fails-bare-url, +prove-fails-autolink, +links-paren-wrapped). CONVERGENCE: core clean,
findings now narrow edge-forms; this was the agreed last round.

## v4.0.1 -> v4.0.2: JS tester sweep , fixed real port bugs; kept the JS-is-better divergences

first tester sweep on the node port (differential-vs-perl-final + gate/network/fresh-eyes). FIXED real
JS port bugs: prove's diff body went to stdout (now stderr, stdout stays clean); permalink thought an empty
file had 1 line (now 0 -> out-of-range dies like perl); permalink ignored extra trailing args (now rejects);
sweep silently skipped a deleted file (now prints a visible DELETED note, still not counted as an offender).
KEPT (the JS is MORE correct than perl-final, documented as intentional, not regressions):
- url boundaries: JS \s is unicode-aware, so a url ending at a non-breaking/unicode space tokenizes
  correctly; perl-final's ASCII \s swallowed the next word (a perl fail-open the port closes).
- lint/check offender text containing a literal tab: JS builds {text,href} structurally and is correct;
  perl-final's split-on-first-tab mis-attributed it.
- check failed_urls / dead-list ordering: JS is document-order deterministic; perl was network-completion
  (nondeterministic) order.
KNOWN LIMITATIONS (pre-existing , present in perl-final too, NOT port regressions; documented in SKILL):
- 4-space indented code blocks are not recognized as code (CITE_CR covers fenced/inline/html-comment only),
  so prove can no-op / insert can wrap / lint --fix can rewrite inside them. recommend fenced code. fixing
  well needs CommonMark indented-code detection (blank-line-preceded, not-in-list) , fiddly + a naive
  pattern would mask real prose-in-lists (a worse fail-open), so deferred, not papered over.
- reference-style ([text][ref]) link bodies aren't in insert/lint's protected set (inline + html only).
- node fetch (undici) caps redirects at 20; curl's default is 50. a url needing 21+ hops reads dead in JS
  (pathological; both cap somewhere).
fresh-eyes pass on the JS source: CLEAN (no global-regex/lastIndex, split-capture, or async-swallow bugs).

## v4.0.3 -> v4.0.4: third JS sweep , 1 gate fail-open + 1 consistency fix (converging)

third sweep: all v4.0.3 fixes confirmed holding, network came back clean. fixed:
- lint FAIL-OPEN on a markdown half-fix whose link text has LEADING whitespace: `[ https://shown](https://real)`
  renders trimmed, so the reader sees a url-as-text half-fix, but the `^https?:` test saw the leading space
  and missed it (trailing space was caught , the asymmetry proved the bug). lintScan now trims the text. (real)
- isFlagged: strip trailing punctuation from the QUERY url too (not just the flag-file urls), so a flagged
  bare url matches a dead inline-link href ending in punctuation. closes the documented _flagged-punct caveat.
KEPT as correct (not a bug): a half-fix link's DISPLAY-TEXT url is no longer extracted by `links`/`check`
(side effect of the v4.0.3 paren-phantom mask). the display text isn't a clickable target, and `lint` flags
the half-fix anyway, so the check verdict agrees , JS is more correct than perl here.
+1 test (lint leading-ws). 85 tests green.

## v4.0.5 -> v4.0.6: fifth JS sweep , insert no longer corrupts image alt-text

fifth sweep: differential clean (all v4.0.5 fixes hold, every diff maps to a known/documented item), cold
usage run clean end-to-end. one real corruption found + fixed:
- insert CORRUPTED image markup + reported success: protSplit's `(?<!\!)` excluded images, so a phrase
  inside `![alt](src)` got wrapped (`![global [temp rise](url) since 1880](src)`), breaking the image +
  nesting a link, exit 0. same nesting-corruption class as the v3.18 double-insert fix, for images (shared
  with perl). FIX: protSplit now protects images too (leading `!?`), so insert REFUSES a phrase that only
  lives in alt text (rc 1, "not found in citable prose"). +1 test. 89 tests green.

## v4.0.6 -> v4.0.7: sixth JS sweep , insert protected-set broadened (stop the html whack-a-mole)

sixth sweep: differential clean, cold usage clean. gate hunt found two MORE insert protected-set gaps , the
same class as the autolink (v4.0.5) + image-alt (v4.0.6) ones: a phrase appearing ONLY inside (a) a
linked-image's OUTER href `[![alt](img)](href)`, or (b) an html `<img>` tag, got wrapped + corrupted, exit 0
(prove/lint fail open because the damage is markup-internal). RATHER than patch each markup form one-by-one,
broadened protSplit: added a linked-image pattern + a BROAD `<[^>]+>` html-tag guard (covers <img>, <br>,
autolinks, any tag) so the html side can't whack-a-mole further. normal-prose insert verified unchanged.
+2 tests. 91 tests green. NOTE: insert's protected-set is markup-enumeration and inherently best-effort for
exotic markdown (link titles, ref-style, footnotes); the cases that slip require citing a phrase that ONLY
appears inside markup/a url (pathological for real citation use), and the SKILL's "review the diff" is the
final backstop. the core gates + differential + cold-usage have been clean throughout.

## v4.0.7 -> v4.0.8: seventh JS sweep , CONVERGED (insert + usage clean; tightened the html guard)

seventh sweep: insert protected-set CLEAN (the v4.0.7 broadening held), cold usage run CLEAN (a realistic
consensus-service blog post cited end-to-end). differential found ONE nit, self-inflicted by the v4.0.7 broad
`<[^>]+>` guard: it matched math/comparison prose ("0 < n the algorithm and 2 > x") so insert false-REFUSED
a legit phrase between a `<` and a `>` (safe , a clean refusal, never corruption). FIX: match only real html
tags `<\/?[a-zA-Z][^>]*>` (still catches <img>/</a>/autolinks, not math prose). verified: math-prose phrase
wraps; <img>/autolink/linked-image still refused. 91 tests green.

=> RELEASE CANDIDATE. across 7 sweeps the port had ~16 real bugs found + fixed; the core gates, the
differential-vs-perl, and the cold-usage runs are clean; the only residuals are documented best-effort
(exotic markdown in insert's protected-set) backstopped by review-the-diff.

## v4.0.10: real-use feedback from a live blog-cite run (the sql-spider post)

citing a real post surfaced two things:
- BUG (crosscheck): a 429 (and 403/503) path with a 200 host root was reported "likely DEAD". those are
  GATE codes (rate-limit / bot-block), not death , the crosscheck wrongly overrode the gate signal because
  the root was up. it would have told an agent a rate-limited-but-live link was dead (e.g. wikipedia
  rate-limiting cite's bare fetch UA). FIX: gate codes (403/429/503) report "rate-limit/bot gate, not death"
  regardless of root; only non-gate codes use the root-vs-path dead inference.
- DOCTRINE (under-linking EXPLAIN): the run was too shy , it linked the clear jargon but missed central
  terms like "knowledge graph" and "connected component". the old "under-link, zero is fine" rationed
  EXPLAIN. SKILL now splits the bias by type: THOROUGH on EXPLAIN (a jargon sweep, per-concept not rationed,
  low-risk + trivially removable, a stuck reader is the real cost) and CONSERVATIVE on SUBSTANTIATE (wrong =
  damage). the technical-generalist tiebreaker + don't-manufacture + the laundering trap all stay.
note: cite's bare node-fetch UA gets bot-rate-limited (429) by some hosts where a browser wouldn't; the
dead-vs-gated doctrine + this crosscheck fix diagnose it correctly. to ADD a link under a gate, confirm it's
live via an alternate check first (what I did for the connected-component link). 91 tests green.

## v4.0.11: HTML articles are first-class (Roy: "don't target only blog posts; we support html too, no?")

cite already handled html LINKS everywhere (insert writes <a href> for .html; links/verify/lint/prove all
read <a> anchors). the one gap: CITE_CR (code regions) only knew markdown code (fenced/inline/html-comment),
NOT html <pre>/<code> , so a link or phrase inside <pre><code> in an html article was treated as live prose
(links grabbed it; insert would wrap into it). repro confirmed. FIX: added <pre>...</pre> + <code>...</code>
to CITE_CR, so html code blocks get the same skip as markdown fences across mask/strip/insert/lint. now
.html articles are fully first-class. README + SKILL state "markdown OR html , post/doc/readme/article", and
the code-regions note lists <pre>/<code>. +3 tests (html code-region masked, insert refuses inside <pre>,
insert writes <a href> in .html). 94 tests green.
