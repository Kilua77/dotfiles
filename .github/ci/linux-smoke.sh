#!/usr/bin/env bash
#
# linux-smoke.sh — runs INSIDE a distro container (CI and locally):
#
#   docker run --rm -v "$HOME/.dotfiles:/src:ro" rockylinux:9 \
#     bash /src/.github/ci/linux-smoke.sh
#
# Proves the repo's core promise on Linux: the complete tool install with
# NO root beyond the documented prerequisites. The container starts as
# root and does two things with it, nothing else:
#   1. install the prerequisites (git curl unzip xz tar gzip python3, and
#      gcc/make unless WITH_COMPILER=no) — what an admin would provide
#   2. create the unprivileged user the install actually runs as
# The dotfiles scripts themselves never elevate.
#
# Env:
#   WITH_COMPILER  yes|no   — no: source builds must WARN and skip
#   ASSERT_TOOLS   space-separated binaries that must exist afterwards
#   DOTFILES_SKIP_LLVM=1 is honored via the tester's ~/.localrc when set.

# shellcheck disable=SC2086  # word lists (package names, tool names) are deliberate
set -eu

echo "==> linux-smoke: $(grep PRETTY_NAME /etc/os-release | cut -d'"' -f2)"

# --- Root phase: prerequisites + the unprivileged user --------------------------

base="git curl unzip xz tar gzip python3 ca-certificates"
if command -v dnf >/dev/null 2>&1; then
    dnf -y -q install $base
    if [ "${WITH_COMPILER:-yes}" = yes ]; then dnf -y -q install gcc make; fi
else
    apt-get update -qq
    apt-get install -y -qq $base
    if [ "${WITH_COMPILER:-yes}" = yes ]; then apt-get install -y -qq build-essential; fi
fi

id tester >/dev/null 2>&1 || useradd -m tester
# The opt-out flag travels the documented way: ~/.localrc, never the repo.
if [ "${DOTFILES_SKIP_LLVM:-0}" = 1 ]; then
    printf 'export DOTFILES_SKIP_LLVM=1\n' > /home/tester/.localrc
    chown tester:tester /home/tester/.localrc
    chmod 600 /home/tester/.localrc
fi

# --- User phase: bootstrap + install, then assertions ---------------------------

# shellcheck disable=SC2016  # the single-quoted payload must not expand here
run_as_tester='
set -e
cp -r /src /home/tester/.dotfiles
cd /home/tester/.dotfiles
./script/bootstrap --force
./script/install
export PATH="$HOME/.local/bin:$PATH"
echo "==> linux-smoke: asserting delivered tools"
for t in $ASSERT_TOOLS; do
    command -v "$t" >/dev/null || { echo "MISSING: $t"; exit 1; }
done
echo "==> linux-smoke: idempotence (second install run)"
./script/install >/tmp/second-run.log && echo ok
echo "==> linux-smoke: tool versions"
for t in $ASSERT_TOOLS; do
    printf "%-13s %s\n" "$t" "$("$t" --version 2>/dev/null | head -1)"
done
echo "==> linux-smoke: PASS"
'
export ASSERT_TOOLS="${ASSERT_TOOLS:-}"
su - tester -c "ASSERT_TOOLS='$ASSERT_TOOLS' bash -s" <<<"$run_as_tester"
