#!/usr/bin/env bash
# cite test harness , offline (a throwaway fixture git repo). the one network test is guarded.
# exits nonzero on any failure.
set -uo pipefail
CITE="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")/.." && pwd)/cite"
fails=0
ok()  { printf 'ok   - %s\n' "$1"; }
bad() { printf 'FAIL - %s\n' "$1"; fails=$((fails+1)); }

# fixture: a 5-line file, a github-looking origin, one commit, and a simulated remote-tracking ref
# (refs/remotes/origin/main) so HEAD reads as "pushed" without a real network remote.
fix="$(mktemp -d)"; trap 'rm -rf "$fix"' EXIT
git -C "$fix" init -q
git -C "$fix" config user.email t@t; git -C "$fix" config user.name t
git -C "$fix" remote add origin git@github.com:acme/widget.git
printf 'a\nb\nc\nd\ne\n' > "$fix/src.txt"
git -C "$fix" add src.txt; git -C "$fix" commit -qm init
git -C "$fix" update-ref refs/remotes/origin/main HEAD     # simulate "pushed"
sha="$(git -C "$fix" rev-parse HEAD)"

echo "# cite test on $(uname -s 2>/dev/null)"

# 1. permalink, line range, git@ remote, pushed HEAD
got="$("$CITE" permalink "$fix" src.txt 2 4 2>/dev/null)"
exp="https://github.com/acme/widget/blob/$sha/src.txt#L2-L4"
[ "$got" = "$exp" ] && ok "permalink (range, git@ remote)" || bad "permalink range got: $got"

# 2. single-line form, https remote
git -C "$fix" remote set-url origin https://github.com/acme/widget.git
got="$("$CITE" permalink "$fix" src.txt 3 2>/dev/null)"
exp="https://github.com/acme/widget/blob/$sha/src.txt#L3"
[ "$got" = "$exp" ] && ok "permalink (single line, https remote)" || bad "permalink single got: $got"

# 3. out-of-range line errors (nonzero), emits nothing
out="$("$CITE" permalink "$fix" src.txt 99 2>/dev/null)"; rc=$?
{ [ -z "$out" ] && [ "$rc" -ne 0 ]; } && ok "permalink rejects out-of-range line" || bad "permalink should reject line 99 (out='$out' rc=$rc)"

# 4. missing file errors
out="$("$CITE" permalink "$fix" nope.txt 1 2>/dev/null)"; rc=$?
{ [ -z "$out" ] && [ "$rc" -ne 0 ]; } && ok "permalink rejects missing file" || bad "permalink should reject missing file"

# 5. non-github remote errors
git -C "$fix" remote set-url origin https://gitlab.com/acme/widget.git
out="$("$CITE" permalink "$fix" src.txt 1 2>/dev/null)"; rc=$?
{ [ -z "$out" ] && [ "$rc" -ne 0 ]; } && ok "permalink rejects non-github remote" || bad "permalink should reject non-github remote"
git -C "$fix" remote set-url origin https://github.com/acme/widget.git

# 6. UNPUSHED HEAD: add a commit so HEAD is ahead of origin/main -> permalink must refuse (the bug the dogfood found)
printf 'f\n' >> "$fix/src.txt"; git -C "$fix" add src.txt; git -C "$fix" commit -qm second
out="$("$CITE" permalink "$fix" src.txt 1 2>/dev/null)"; rc=$?
{ [ -z "$out" ] && [ "$rc" -ne 0 ]; } && ok "permalink refuses unpushed HEAD" || bad "permalink should refuse unpushed HEAD (out='$out' rc=$rc)"

# 7. --ref pins to the pushed sha, validates lines AT that ref (src.txt had 5 lines at origin/main)
got="$("$CITE" permalink "$fix" src.txt 2 4 --ref origin/main 2>/dev/null)"
exp="https://github.com/acme/widget/blob/$sha/src.txt#L2-L4"
[ "$got" = "$exp" ] && ok "permalink --ref pins to pushed sha" || bad "permalink --ref got: $got"

# 8. --ref still range-validates at that ref (line 6 exists at HEAD but NOT at origin/main's 5-line version)
out="$("$CITE" permalink "$fix" src.txt 6 --ref origin/main 2>/dev/null)"; rc=$?
{ [ -z "$out" ] && [ "$rc" -ne 0 ]; } && ok "permalink --ref validates range at the ref" || bad "permalink --ref should reject line 6 at origin/main"

# 9. preflight reports unpushed HEAD
pf="$("$CITE" preflight "$fix" 2>/dev/null)"
printf '%s' "$pf" | grep -qE 'pushed: +no' && ok "preflight flags unpushed HEAD" || bad "preflight should say pushed: no"
printf '%s' "$pf" | grep -qE 'slug: +acme/widget' && ok "preflight reports slug" || bad "preflight should report slug"

# 10. verify: 200 passes, 404 fails (network; guarded so offline runs still pass)
if curl -fsS -o /dev/null --max-time 8 https://example.com 2>/dev/null; then
  "$CITE" verify https://example.com >/dev/null 2>&1 && ok "verify 200" || bad "verify should pass on example.com"
  "$CITE" verify https://example.com/definitely-not-a-real-page-9f3a2b >/dev/null 2>&1 && bad "verify should fail on 404" || ok "verify rejects 404"
  printf '%s\n' https://example.com | "$CITE" verify - >/dev/null 2>&1 && ok "batch verify passes when all 200" || bad "batch verify should pass on all-200"
  printf '%s\n%s\n' https://example.com https://example.com/definitely-not-a-real-page-9f3a2b | "$CITE" verify - >/dev/null 2>&1 && bad "batch verify should fail if any url fails" || ok "batch verify fails if any url fails"
else
  ok "verify (skipped, offline)"
fi

# 11. links: extract markdown-link urls, paren-safe (the parens-in-url extraction bug from the adversarial review)
md="$fix/links.md"; printf '[a](https://example.com/x) and [b](https://en.wikipedia.org/wiki/Cache_(computing)) done\n' > "$md"
lk="$("$CITE" links "$md" 2>/dev/null)"
printf '%s' "$lk" | grep -qx 'https://example.com/x' && ok "links: plain url" || bad "links: plain url"
printf '%s' "$lk" | grep -qx 'https://en.wikipedia.org/wiki/Cache_(computing)' && ok "links: paren url kept whole" || bad "links: paren url truncated (got: $lk)"
# html anchors too (the README-badge blind spot)
printf '<a href="https://ex.com/badge"><img src="x.svg"></a> and [m](https://md.example/y)\n' > "$md"
lk2="$("$CITE" links "$md" 2>/dev/null)"
printf '%s' "$lk2" | grep -qx 'https://ex.com/badge' && ok "links: html href extracted" || bad "links: html href missed (got: $lk2)"
printf '%s' "$lk2" | grep -qx 'https://md.example/y' && ok "links: md + html together" || bad "links: md+html (got: $lk2)"
rm -f "$md" 2>/dev/null

# 12. prove: the mechanical prose-integrity gate (the corpus run's blocking failure was a self-certified prose edit)
pf="$fix/post.md"
printf 'the cat sat on the [mat](https://old.example/x) near the door.\n' > "$pf"
git -C "$fix" add post.md; git -C "$fix" commit -qm post
# (a) url-only fix -> visible text identical -> passes
perl -i -pe 's#https://old.example/x#https://new.example/y#' "$pf"
"$CITE" prove "$pf" >/dev/null 2>&1 && ok "prove passes on url-only fix" || bad "prove url-only fix should pass"
# (b) add a new link around an existing word -> still markup-only -> passes
perl -i -pe 's/\bdoor\b/[door](https:\/\/example.com\/door)/' "$pf"
"$CITE" prove "$pf" >/dev/null 2>&1 && ok "prove passes when a link is added" || bad "prove add-link should pass"
# (c) a prose word change -> FAILS
perl -i -pe 's/\bcat\b/dog/' "$pf"
"$CITE" prove "$pf" >/dev/null 2>&1 && bad "prove should FAIL on prose change" || ok "prove fails on prose change"
# (d) a link-TEXT change is a prose change -> FAILS
git -C "$fix" checkout -q post.md
perl -i -pe 's/\[mat\]/[rug]/' "$pf"
"$CITE" prove "$pf" >/dev/null 2>&1 && bad "prove should FAIL on link-text change" || ok "prove fails on link-text change"
# (e) a CRLF flip (whole-file whitespace churn) -> FAILS
git -C "$fix" checkout -q post.md
perl -i -pe 's/\n/\r\n/' "$pf"
"$CITE" prove "$pf" >/dev/null 2>&1 && bad "prove should FAIL on CRLF churn" || ok "prove fails on line-ending churn"
git -C "$fix" checkout -q post.md
# (f) url-as-text half-fix repair: href AND visible-url text both changed -> passes (urls tokenized)
printf 'see <a href="https://old.example/x">https://old.example/x</a> ok.\n' > "$pf"
git -C "$fix" add post.md; git -C "$fix" commit -qm post3
perl -i -pe 's#https://old.example/x#https://new.example/y#g' "$pf"
"$CITE" prove "$pf" >/dev/null 2>&1 && ok "prove passes on url-as-text fix (href+text)" || bad "prove should pass when only urls changed"
git -C "$fix" checkout -q post.md
# (g) a BARE url is reader-visible text: repointing it is a prose change -> FAILS (not tokenized away)
printf 'download the installer from https://old.example/x and run it.\n' > "$pf"
git -C "$fix" add post.md; git -C "$fix" commit -qm postbare
perl -i -pe 's#https://old.example/x#https://new.example/y#' "$pf"
"$CITE" prove "$pf" >/dev/null 2>&1 && bad "prove should FAIL on a bare-url change (reader-visible)" || ok "prove fails on a bare-url text change"
git -C "$fix" checkout -q post.md
# (h) an angle-bracket autolink is reader-visible too -> FAILS
printf 'see <https://old.example/x> for details.\n' > "$pf"
git -C "$fix" add post.md; git -C "$fix" commit -qm postauto
perl -i -pe 's#https://old.example/x#https://new.example/y#' "$pf"
"$CITE" prove "$pf" >/dev/null 2>&1 && bad "prove should FAIL on an autolink change" || ok "prove fails on an autolink change"
git -C "$fix" checkout -q post.md
# links: a bare url wrapped in parens is still extracted (so check can't certify a paren-wrapped dead link)
pb="$fix/parenurl.md"; printf 'details in the post (https://example.com/p) here.\n' > "$pb"
"$CITE" links "$pb" | grep -qx 'https://example.com/p' && ok "links: paren-wrapped bare url extracted" || bad "links: paren-wrapped bare url missed"
rm -f "$pb"

# 13. lint: the half-fix (visible text is a url that differs from href)
lf="$fix/lint.md"
printf 'a [https://old.example/x](https://new.example/y) and [label](https://ok.example/z).\n' > "$lf"
"$CITE" lint "$lf" >/dev/null 2>&1 && bad "lint should FAIL on a url-text != href" || ok "lint flags markdown half-fix"
printf 'b <a href="https://new.example/y">https://old.example/x</a> here.\n' > "$lf"
"$CITE" lint "$lf" >/dev/null 2>&1 && bad "lint should FAIL on html half-fix" || ok "lint flags html half-fix"
printf 'c [label](https://ok.example/z) and [https://same.example/q](https://same.example/q).\n' > "$lf"
"$CITE" lint "$lf" >/dev/null 2>&1 && ok "lint clean when text!=url or text==href" || bad "lint should pass (descriptive text + matching url-text)"
rm -f "$lf"

# 14. flag: appends a durable line to .cite-flags.md at the repo root
ff="$fix/flagme.md"; printf 'x\n' > "$ff"; git -C "$fix" add flagme.md; git -C "$fix" commit -qm flagme
"$CITE" flag "$ff" "dead pre-existing link foo.example" >/dev/null 2>&1
{ [ -f "$fix/.cite-flags.md" ] && grep -q 'dead pre-existing link foo.example' "$fix/.cite-flags.md"; } && ok "flag appends to .cite-flags.md" || bad "flag should append to .cite-flags.md"
rm -f "$ff" "$fix/.cite-flags.md"

# 15. v3.7 fixes , single-quote href, image exclusion, permalink bounds + line count
mm="$fix/v37.md"
printf '%s\n' "<a href='https://sq.example/y'>z</a> and ![alt](https://img.example/pic.png) and [t](https://md.example/a)" > "$mm"
lk="$("$CITE" links "$mm" 2>/dev/null)"
printf '%s' "$lk" | grep -qx 'https://sq.example/y' && ok "links: single-quoted href extracted" || bad "links: single-quoted href missed (got: $lk)"
printf '%s' "$lk" | grep -qx 'https://img.example/pic.png' && bad "links: image url should be excluded" || ok "links: image url excluded"
# lint: image whose alt-text is a url is NOT a half-fix (the v3.6 false-positive); single-quoted html half-fix IS
printf '%s\n' "![https://old.example/x](https://img.example/pic.png)" > "$mm"
"$CITE" lint "$mm" >/dev/null 2>&1 && ok "lint: image alt-url is not a half-fix" || bad "lint: image false-positive not fixed"
printf '%s\n' "<a href='https://new.example/y'>https://old.example/x</a>" > "$mm"
"$CITE" lint "$mm" >/dev/null 2>&1 && bad "lint: single-quoted html half-fix missed" || ok "lint: single-quoted html half-fix caught"
rm -f "$mm"
# permalink: reject line 0 and a backwards range (lower-bound + order checks)
out="$("$CITE" permalink "$fix" src.txt 0 2>/dev/null)"; rc=$?
{ [ -z "$out" ] && [ "$rc" -ne 0 ]; } && ok "permalink rejects line 0" || bad "permalink should reject line 0"
out="$("$CITE" permalink "$fix" src.txt 4 2 2>/dev/null)"; rc=$?
{ [ -z "$out" ] && [ "$rc" -ne 0 ]; } && ok "permalink rejects backwards range" || bad "permalink should reject start>end"
# permalink: last line of a file with NO trailing newline is citable (awk NR, not wc -l)
printf 'x\ny\nz' > "$fix/nonl.txt"   # 3 lines, no trailing newline
git -C "$fix" add nonl.txt; git -C "$fix" commit -qm nonl; git -C "$fix" update-ref refs/remotes/origin/main HEAD
"$CITE" permalink "$fix" nonl.txt 3 --ref origin/main >/dev/null 2>&1 && ok "permalink accepts last line w/o trailing newline" || bad "permalink should accept line 3 of a no-trailing-newline file"

# 16. sweep: run prove+lint over a batch of changed .md vs a base ref
printf 'the cat sat on the mat.\n' > "$fix/swa.md"
printf 'see http://old.example/x here.\n' > "$fix/swb.md"
git -C "$fix" add swa.md swb.md; git -C "$fix" commit -qm sweepbase
swbase="$(git -C "$fix" rev-parse HEAD)"
perl -i -pe 's/\bmat\b/[mat](https:\/\/ex.example\/m)/' "$fix/swa.md"                 # clean link-add
printf 'see [http://old.example/x](https://new.example/y) here.\n' > "$fix/swb.md"     # half-fix
"$CITE" sweep "$fix" "$swbase" >/dev/null 2>&1 && bad "sweep should FAIL (swb half-fix)" || ok "sweep fails when a file has a half-fix"
swout="$("$CITE" sweep "$fix" "$swbase" 2>/dev/null)"
printf '%s' "$swout" | grep -q 'HALF-FIX.*swb.md' && ok "sweep names the offending file" || bad "sweep should name swb.md"
git -C "$fix" checkout -q swa.md swb.md 2>/dev/null

# 17. v3.9: --json, lint --fix, --relative, check
j="$fix/j.md"
printf '%s\n' "a [t](https://md.example/a) and ![i](https://img.example/p.png) and [r](./rel.md)" > "$j"
jout="$("$CITE" links "$j" --json 2>/dev/null)"
printf '%s' "$jout" | grep -q '"urls":\["https://md.example/a"\]' && ok "links --json urls (image excluded)" || bad "links --json urls (got: $jout)"
printf '%s' "$jout" | grep -q '"relative":\["./rel.md"\]' && ok "links --json relative" || bad "links --json relative (got: $jout)"
# lint --fix syncs a half-fix to its href, leaving the file clean
printf '%s\n' "see [http://old.example/x](https://new.example/y) ok" > "$j"
"$CITE" lint "$j" --fix >/dev/null 2>&1
"$CITE" lint "$j" >/dev/null 2>&1 && ok "lint --fix repaired the half-fix" || bad "lint --fix should leave it clean"
grep -q '\[https://new.example/y\](https://new.example/y)' "$j" && ok "lint --fix synced text to href" || bad "lint --fix did not sync text to href"
# lint --json reports the offender
printf '%s\n' "see [http://old.example/x](https://new.example/y) ok" > "$j"
ljson="$("$CITE" lint "$j" --json 2>/dev/null)"
printf '%s' "$ljson" | grep -q '"clean":false' && ok "lint --json flags offender" || bad "lint --json should be clean:false"
rm -f "$j"
# check: PASS on a committed link-free post (prove+lint clean, no network), ISSUES on a prose change
printf 'just some prose here.\n' > "$fix/c.md"; git -C "$fix" add c.md; git -C "$fix" commit -qm cbase
"$CITE" check "$fix/c.md" HEAD >/dev/null 2>&1 && ok "check PASS on a clean post" || bad "check should PASS on a clean post"
perl -i -pe 's/prose/PROSE-EDIT/' "$fix/c.md"
"$CITE" check "$fix/c.md" HEAD >/dev/null 2>&1 && bad "check should report ISSUES on a prose change" || ok "check fails on a prose change"
git -C "$fix" checkout -q c.md

# 18. v3.10: reference-style links, version, json error envelope, check prove-skipped, long-url verify
rs="$fix/rs.md"; printf 'see [docs][d].\n\n[d]: https://example.com/ref\n' > "$rs"
"$CITE" links "$rs" | grep -qx 'https://example.com/ref' && ok "links: reference-style def extracted" || bad "links: ref-style def missed"
rm -f "$rs"
"$CITE" version | grep -q '^cite [0-9]' && ok "version prints" || bad "version should print"
"$CITE" version --json | grep -q '"version"' && ok "version --json" || bad "version --json"
djson="$("$CITE" lint /no/such/file --json 2>/dev/null)"
printf '%s' "$djson" | grep -q '"error"' && ok "die emits a json error envelope under --json" || bad "die should emit json error"
# check: a clean new post ABSENT at base -> prove skipped (not a failure), still PASS (link-free, no network)
printf 'brand new prose only.\n' > "$fix/nf.md"
cout="$("$CITE" check "$fix/nf.md" HEAD 2>/dev/null)"
printf '%s' "$cout" | grep -q 'prove: skipped' && ok "check: prove skipped when file absent at base" || bad "check prove-skip (got: $cout)"
printf '%s' "$cout" | grep -q '=> PASS' && ok "check: PASS a clean new post (not false PROSE CHANGED)" || bad "check should PASS a clean new post"
rm -f "$fix/nf.md"
# the long-url batch-verify drop (network-guarded)
if curl -fsS -o /dev/null --max-time 8 https://example.com 2>/dev/null; then
  long="https://example.com/$(printf 'z%.0s' $(seq 1 300))"
  printf '%s\n' "$long" | "$CITE" verify - >/dev/null 2>&1 && bad "batch verify should catch a >255-byte dead url" || ok "batch verify catches a long dead url (no xargs -I drop)"
else ok "long-url verify (skipped, offline)"; fi

# 19. v3.11: code-fence/inline-code blindness, autolinks + bare urls, lint --fix code-protection, check flag-downgrade
cf="$fix/cf.md"
printf 'real [a](https://md.example/a).\n\n```\nex: [b](https://fenced.example/b)\n```\n\ninline `[c](https://inline.example/c)` end.\n' > "$cf"
lk="$("$CITE" links "$cf")"
printf '%s' "$lk" | grep -qx 'https://md.example/a' && ok "links: real link kept" || bad "links: real link dropped"
printf '%s' "$lk" | grep -qE 'fenced.example|inline.example' && bad "links: code-span link should be ignored" || ok "links: ignores fenced + inline code"
printf 'see <https://auto.example/x> and bare https://bare.example/y here.\n' > "$cf"
lk="$("$CITE" links "$cf")"
printf '%s' "$lk" | grep -qx 'https://auto.example/x' && ok "links: angle-bracket autolink extracted" || bad "links: autolink missed"
printf '%s' "$lk" | grep -qx 'https://bare.example/y' && ok "links: bare url extracted" || bad "links: bare url missed"
printf 'doc `[https://old.example/x](https://new.example/y)` ex.\n' > "$cf"; cp "$cf" "$cf.bak"
"$CITE" lint "$cf" --fix >/dev/null 2>&1
diff -q "$cf" "$cf.bak" >/dev/null 2>&1 && ok "lint --fix protects code spans" || bad "lint --fix mutated a code span"
rm -f "$cf" "$cf.bak"
printf 'a [dead][d].\n\n[d]: https://flagged-zzz.invalid\n' > "$fix/flk.md"; git -C "$fix" add flk.md; git -C "$fix" commit -qm flk
"$CITE" flag "$fix/flk.md" "known dead: https://flagged-zzz.invalid" >/dev/null 2>&1
cflag="$("$CITE" check "$fix/flk.md" HEAD 2>/dev/null)"
printf '%s' "$cflag" | grep -q 'flagged, known' && ok "check downgrades a flagged dead link" || bad "check should downgrade a flagged url"
printf '%s' "$cflag" | grep -q '=> PASS' && ok "check PASS when the only failure is flagged" || bad "check should PASS with only-flagged failure"
rm -f "$fix/.cite-flags.md"

# 20. v3.12: multi-line link text (slurp), linked-image target, html-comment masking
mlx="$fix/ml.md"
printf 'cites [a great\nresource](https://ml.example/x) here.\n' > "$mlx"
"$CITE" links "$mlx" | grep -qx 'https://ml.example/x' && ok "links: multi-line link text (slurp mode)" || bad "links: multi-line link text missed"
printf '[![CI](https://img.example/b.svg)](https://target.example/builds)\n' > "$mlx"
mout="$("$CITE" links "$mlx")"
printf '%s' "$mout" | grep -qx 'https://target.example/builds' && ok "links: linked-image target extracted" || bad "links: linked-image target missed"
printf '%s' "$mout" | grep -q 'img.example' && bad "links: linked-image src should be excluded" || ok "links: linked-image src excluded"
printf 'real [a](https://real.example/a). <!-- [b](https://commented.example/b) -->\n' > "$mlx"
"$CITE" links "$mlx" | grep -q 'commented.example' && bad "links: html-comment link should be masked" || ok "links: html comment masked"
rm -f "$mlx"

# 21. flag-downgrade must be EXACT-url, not substring (a prefix dead url must not ride on a longer flag)
printf 'a [x](https://dead-zzz.invalid/page) and [y](https://dead-zzz.invalid/page-two).\n' > "$fix/pre.md"
git -C "$fix" add pre.md; git -C "$fix" commit -qm pre
"$CITE" flag "$fix/pre.md" "known dead: https://dead-zzz.invalid/page-two" >/dev/null 2>&1
pout="$("$CITE" check "$fix/pre.md" HEAD 2>/dev/null)"
{ printf '%s' "$pout" | grep -q '1 flagged' && printf '%s' "$pout" | grep -q 'ISSUES'; } && ok "flag-downgrade is exact-url (prefix not vouched)" || bad "flag substring false-PASS (got: $pout)"
rm -f "$fix/pre.md" "$fix/.cite-flags.md"

# 22. tilde-fence --fix protection (the blocking corruption the varied pass found)
tf="$fix/tf.md"
printf 'fix it:\n\n~~~markdown\n[http://old.example/x](https://new.example/y)\n~~~\n' > "$tf"; cp "$tf" "$tf.bak"
"$CITE" lint "$tf" --fix >/dev/null 2>&1
diff -q "$tf" "$tf.bak" >/dev/null 2>&1 && ok "lint --fix protects ~~~ tilde fences" || bad "lint --fix corrupted a tilde-fenced code example"
rm -f "$tf" "$tf.bak"

# 23. cite insert: error only on 0 matches (missed add); wrap the FIRST occurrence; note on multiples
ins="$fix/ins.md"
printf 'a unique raft phrase and a token bucket and another token bucket.\n' > "$ins"
out="$("$CITE" insert "$ins" "no such phrase" https://example.com 2>&1)"; rc=$?
{ [ "$rc" -ne 0 ] && printf '%s' "$out" | grep -q 'not found'; } && ok "insert errors on 0 matches (missed add)" || bad "insert should error on a missing phrase"
if curl -fsS -o /dev/null --max-time 8 https://example.com 2>/dev/null; then
  "$CITE" insert "$ins" "raft phrase" https://example.com >/dev/null 2>&1
  grep -qF '[raft phrase](https://example.com)' "$ins" && ok "insert wraps a unique match" || bad "insert should wrap a unique phrase"
  out2="$("$CITE" insert "$ins" "token bucket" https://example.com 2>&1)"; rc2=$?
  { [ "$rc2" -eq 0 ] && printf '%s' "$out2" | grep -q 'citable occurrences'; } && ok "insert >1 links first + notes (no error)" || bad "insert >1 should link first + note"
  [ "$(grep -coF '[token bucket](https://example.com)' "$ins")" = "1" ] && ok "insert wraps only the FIRST of several" || bad "insert should wrap only the first occurrence"
else ok "insert wrap/multi (skipped, offline)"; fi
rm -f "$ins"

# 24. v3.18: insert + prove are code-aware (the blocking corrupted-but-vouched bug)
cz="$fix/cz.md"
printf 'install with `pip install reqlib` to begin.\n' > "$cz"; git -C "$fix" add cz.md; git -C "$fix" commit -qm cz
out="$("$CITE" insert "$cz" "reqlib" https://example.com 2>&1)"; rc=$?
{ [ "$rc" -ne 0 ] && printf '%s' "$out" | grep -q 'citable prose'; } && ok "insert refuses a phrase that only appears in code" || bad "insert should refuse a code-only phrase"
# prove FAILS on a link injected into a fenced code block (was a false PASS)
printf 'see:\n\n```\nwidgetlib here\n```\n' > "$cz"; git -C "$fix" add cz.md; git -C "$fix" commit -qm cz2
perl -i -pe 's/widgetlib here/[widgetlib](https:\/\/example.com) here/' "$cz"
"$CITE" prove "$cz" HEAD >/dev/null 2>&1 && bad "prove should FAIL on an in-code link injection" || ok "prove catches a link injected into code"
# double-insert leaves no nested [[..](..)](..)
printf 'we use widgetlib in prod.\n' > "$cz"; git -C "$fix" add cz.md; git -C "$fix" commit -qm cz3
if curl -fsS -o /dev/null --max-time 8 https://example.com 2>/dev/null; then
  "$CITE" insert "$cz" "widgetlib" https://example.com >/dev/null 2>&1
  "$CITE" insert "$cz" "widgetlib" https://example.com >/dev/null 2>&1
  grep -q '\[\[' "$cz" && bad "double-insert nested the link" || ok "double-insert does not nest (skips existing link)"
else ok "double-insert (skipped, offline)"; fi
rm -f "$cz"

# CITE_JOBS validation: a bad value must die LOUD at dispatch, not silently disable verification (offline,
# the dispatch guard fires before any network). guards the fail-open where a typo flips check ISSUES->PASS.
out="$(printf 'https://x\n' | CITE_JOBS=garbage "$CITE" verify - 2>/dev/null)"; rc=$?
{ [ -z "$out" ] && [ "$rc" -ne 0 ]; } && ok "CITE_JOBS=garbage dies (no silent fail-open)" || bad "CITE_JOBS=garbage should die (out='$out' rc=$rc)"
out="$(printf 'https://x\n' | CITE_JOBS=-5 "$CITE" verify - 2>/dev/null)"; rc=$?
{ [ -z "$out" ] && [ "$rc" -ne 0 ]; } && ok "CITE_JOBS=-5 dies" || bad "CITE_JOBS=-5 should die (rc=$rc)"

# json builders escape byte-identically to _jesc: a TAB in a relative target -> \t (short form), not a raw tab.
jt="$fix/jt.md"; printf 'x [a](p\tq.md) y\n' > "$jt"
out="$(CITE_JSON=1 "$CITE" links "$jt" 2>/dev/null)"
case "$out" in *'p\tq.md'*) ok "json escapes tab as backslash-t (byte-identical to _jesc)";; *) bad "json tab-escape got: $out";; esac
rm -f "$jt"

# (the bash+perl broken-perl fail-open test was removed in the node port , node is the runtime, there is no
# perl gate; if node runs the script, the engine works. the dep surface is now node + git only.)

# bare-url scanner must NOT manufacture a truncated phantom of a paren-url (cite's own insert produces these:
# wikipedia _(computer_science) disambig pages). links should yield the full url once, no truncated dup.
pp="$fix/paren.md"; printf 'we use [paxos](https://en.wikipedia.org/wiki/Paxos_(computer_science)) here.\n' > "$pp"
plout="$("$CITE" links "$pp")"
{ printf '%s\n' "$plout" | grep -qxF 'https://en.wikipedia.org/wiki/Paxos_(computer_science)' && ! printf '%s\n' "$plout" | grep -qxF 'https://en.wikipedia.org/wiki/Paxos_'; } && ok "no phantom truncated dup of a paren-url" || bad "paren-url phantom: $plout"
rm -f "$pp"

# lint must catch a url-as-text half-fix even when the link text has LEADING whitespace (markdown renders
# link text trimmed, so " https://x" is the same visible-url half-fix as "https://x").
lw="$fix/leadws.md"; printf 'see [ https://shown.example](https://real.example) ok.\n' > "$lw"
"$CITE" lint "$lw" >/dev/null 2>&1 && bad "lint missed a leading-whitespace half-fix (fail-open)" || ok "lint catches a leading-whitespace url-as-text half-fix"
rm -f "$lw"

# a directory path gives a clean 'no file' error, not a raw node EISDIR leak (the lost [ -f ] check)
out="$("$CITE" links "$fix" 2>&1)"; rc=$?
{ [ "$rc" -ne 0 ] && printf '%s' "$out" | grep -q 'no file' && ! printf '%s' "$out" | grep -qi 'EISDIR'; } && ok "directory path -> clean 'no file' error" || bad "directory should give clean error (got: $out)"

# CITE_JOBS is scoped to verify/check/sweep: a stray value must NOT kill non-parallel commands...
out="$(CITE_JOBS=auto "$CITE" prove "$fix/src.txt" HEAD 2>&1)"
printf '%s' "$out" | grep -q 'CITE_JOBS' && bad "CITE_JOBS falsely gates prove" || ok "CITE_JOBS does not gate non-parallel commands"
# ...but it DOES still gate verify.
out="$(printf 'https://x\n' | CITE_JOBS=auto "$CITE" verify - 2>&1)"; rc=$?
{ [ "$rc" -ne 0 ] && printf '%s' "$out" | grep -q 'CITE_JOBS'; } && ok "CITE_JOBS still gates verify" || bad "CITE_JOBS should gate verify (out='$out' rc=$rc)"

# `--` ends option parsing: a reason/phrase that IS a flag token must be taken literally, not swallowed.
rm -f "$fix/.cite-flags.md"
"$CITE" flag "$fix/src.txt" -- --json --fix >/dev/null 2>&1
grep -q -- '--json --fix' "$fix/.cite-flags.md" 2>/dev/null && ok "-- escapes flag tokens (literal reason recorded)" || bad "-- should record '--json --fix' as a literal reason"
# without --, the greedy scan strips them (documented behavior, the reason this escape exists)
rm -f "$fix/.cite-flags.md"

echo "# done. failures: $fails"
[ "$fails" -eq 0 ]
