#!/usr/bin/env bash
#
# adopt-merge.bash — regression suite for json_merge() in script/adopt.
#
# The function is extracted from script/adopt and sourced AS IS (no copy to
# drift). Each case writes a repo/live pair, merges, asserts on the result.
# The historical failure this guards against: union-merging near-duplicate
# list entries stacked three "Default profile" karabiner profiles, all
# selected:true — Karabiner activates the first one, so live edits looked
# "lost" (twice, 2026-10-14 and 2026-10-18; fixed 2026-10-25).
#
# Run: script/tests/adopt-merge.bash   (exit 0 = all green)

set -u
ROOT="$(cd "$(dirname "$0")/../.." && pwd -P)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
cd "$tmp" || exit 1

# --- extract and source json_merge() from the real script ---------------------
sed -n '/^json_merge()/,/^}/p' "$ROOT/script/adopt" > func.sh
if ! grep -q '^json_merge()' func.sh 2>/dev/null; then
  echo 'adopt-merge: could not extract json_merge() from script/adopt' >&2
  exit 1
fi
# shellcheck source=/dev/null  # generated above
. ./func.sh
command -v jq >/dev/null 2>&1 || { echo 'adopt-merge: jq is required' >&2; exit 1; }

pass=0 fail=0

t() { # t <name> <repo-json> <live-json> <assertion-jq-on-merged-repo-file>
  local name="$1" repo="$2" live="$3" assert="$4"
  printf '%s' "$repo" > r.json
  printf '%s' "$live" > l.json
  if ! json_merge r.json l.json 2>/dev/null || [ ! -s r.json ]; then
    echo "FAIL $name — json_merge errored"; fail=$((fail+1)); return
  fi
  if jq -e "$assert" r.json >/dev/null 2>&1; then
    echo "PASS $name"; pass=$((pass+1))
  else
    echo "FAIL $name — assertion: $assert"
    head -c 300 r.json | sed 's/^/      /'; echo
    fail=$((fail+1))
  fi
}

# --- behavior preserved from the old union -------------------------------------
t scalar-arrays-still-union \
  '{"allow":["a","b"],"x":1}' \
  '{"allow":["b","c"],"y":2}' \
  '.allow == ["a","b","c"] and .x == 1 and .y == 2'

# --- identity merge -------------------------------------------------------------
t name-collision-live-wins \
  '{"profiles":[{"name":"P","rules":[{"name":"r1","v":1}],"kept":"repo"}]}' \
  '{"profiles":[{"name":"P","rules":[{"name":"r1","v":2}],"new":"live"}]}' \
  '(.profiles|length) == 1 and .profiles[0].kept == "repo" and .profiles[0].new == "live" and .profiles[0].rules[0].v == 2'

t repo-order-kept-live-appended \
  '{"list":[{"name":"B","v":1},{"name":"A"}]}' \
  '{"list":[{"name":"C"},{"name":"A","v":9}]}' \
  '[.list[].name] == ["B","A","C"] and .list[1].v == 9'

t mixed-list-falls-back-to-unique \
  '{"list":[1,{"name":"x"}]}' \
  '{"list":[2]}' \
  '(.list | length) == 3'

t keyless-objects-merge-by-from \
  '{"rules":[{"from":{"key_code":"caps_lock"},"to":1}]}' \
  '{"rules":[{"from":{"key_code":"caps_lock"},"to":2,"conditions":[{"type":"device_if"}]}]}' \
  '(.rules|length) == 1 and .rules[0].to == 2'

# --- the historical bug, replayed synthetically ---------------------------------
# Repo: three near-duplicate profiles (union artifact of 2026-10-18), all
# selected, the first one WITHOUT the device_if condition. Live: the fixed
# single profile. Expect ONE selected profile whose Caps rule carries the
# condition — i.e. the live edit can no longer be buried.
t self-heal-stacked-profiles \
  '{"profiles":[
      {"name":"Default profile","selected":true,
       "rules":[{"description":"Map Caps","from_k":"caps_lock"}]},
      {"name":"Default profile","selected":true,
       "rules":[{"description":"Map Caps (clavier intégré uniquement)","from_k":"caps_lock","cond":"built_in"}]},
      {"name":"Default profile","selected":true,
       "rules":[{"description":"Map Caps (internal keyboard)","from_k":"caps_lock","cond":"built_in"}]}]}' \
  '{"profiles":[
      {"name":"Default profile","selected":true,
       "rules":[{"description":"Map Caps (clavier intégré uniquement)","from_k":"caps_lock","cond":"built_in"}]}]}' \
  '(.profiles|length) == 1
   and .profiles[0].selected == true
   and ([.profiles[0].rules[] | select(.from_k == "caps_lock" and .cond == "built_in")] | length) >= 1
   and ([.profiles[0].rules[] | select(.description == "Map Caps")] | length) == 1'

# --- stability: a second identical merge changes nothing ------------------------
printf '%s' '{"profiles":[{"name":"P","v":1}]}' > s.json
printf '%s' '{"profiles":[{"name":"P","v":2},{"name":"Q"}]}'   > sl.json
json_merge s.json sl.json 2>/dev/null
cp s.json s1.json
json_merge s.json sl.json 2>/dev/null
if jq -e --slurpfile a s1.json '$a[0] == .' s.json >/dev/null 2>&1; then
  echo 'PASS stable-second-pass'; pass=$((pass+1))
else
  echo 'FAIL stable-second-pass'; fail=$((fail+1))
fi

echo "----"
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
