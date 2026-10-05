#!/usr/bin/env bash
#
# Tests for install.sh: finding or fetching the checkout, and running the steps
# in scripts/steps/. Runs against fake checkouts whose steps only record that
# they ran, so nothing is installed. The steps source the real scripts/common.
#
#   bash tests/install-test.sh     (from the repo root; needs macOS)

set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

pass() { echo "ok - $1"; }
fail() { echo "not ok - $1" >&2; [[ -z ${2:-} ]] || echo "$2" >&2; exit 1; }

# A fake checkout: the real install.sh and scripts/common, and stub steps that
# append "<name> <cwd> <XDG_CONFIG_HOME>" to $tmp/ran.
make_checkout() {
  local dir="$1" version="$2" name
  mkdir -p "$dir/scripts/steps"
  cp "$ROOT/install.sh" "$dir/install.sh"
  cp "$ROOT/scripts/common" "$dir/scripts/common"
  echo "$version" >"$dir/VERSION"
  for name in 10-first 20-second 30-third; do
    cat >"$dir/scripts/steps/$name.sh" <<EOF
#!/usr/bin/env bash
# The $name step.
set -euo pipefail
source "\$(dirname "\$0")/../common"
echo "${name#*-} \$PWD \$XDG_CONFIG_HOME \$(cat VERSION)" >>"$tmp/ran"
[[ \${FAIL_STEP:-} != "${name#*-}" ]]
EOF
    chmod +x "$dir/scripts/steps/$name.sh"
  done
}

ran() { cat "$tmp/ran" 2>/dev/null | awk '{print $1}' | paste -sd' ' -; }

home="$tmp/home"
mkdir -p "$home"
make_checkout "$tmp/checkout" v1
cd "$tmp"   # not inside any checkout

run() { rm -f "$tmp/ran"; env HOME="$home" "$@"; }

# --- from a checkout -------------------------------------------------------------
run "$tmp/checkout/install.sh" >/dev/null
[[ $(ran) == "first second third" ]] || fail "all steps run in order" "$(ran)"
read -r _ cwd xdg version <"$tmp/ran"
[[ $cwd == "$tmp/checkout" ]] || fail "steps run from the checkout root" "$cwd"
[[ $xdg == "$home/.config" ]] || fail "XDG_CONFIG_HOME is ~/.config" "$xdg"
pass "a checkout runs every step in order from its root"

run "$tmp/checkout/install.sh" third first >/dev/null
[[ $(ran) == "third first" ]] || fail "named steps run in the order given" "$(ran)"
run "$tmp/checkout/install.sh" 20-second >/dev/null
[[ $(ran) == "second" ]] || fail "a step can be named with its NN- prefix" "$(ran)"
pass "named steps run alone, in the order given"

if run "$tmp/checkout/install.sh" first nosuch >/dev/null 2>"$tmp/err"; then
  fail "an unknown step is refused"
fi
grep -q "Unknown step: nosuch" "$tmp/err" || fail "the refusal names the step" "$(cat "$tmp/err")"
[[ -z $(ran) ]] || fail "nothing runs when a step name is unknown" "$(ran)"
pass "an unknown step name runs nothing"

if FAIL_STEP=second run "$tmp/checkout/install.sh" >/dev/null 2>"$tmp/err"; then
  fail "a failing step fails the install"
fi
[[ $(ran) == "first second" ]] || fail "steps after a failure do not run" "$(ran)"
grep -q "re-run: ./install.sh second" "$tmp/err" || fail "the failure says how to resume" "$(cat "$tmp/err")"
pass "a failing step stops the install and says how to resume"

list=$(run "$tmp/checkout/install.sh" --list)
[[ $(echo "$list" | awk '{print $1}' | paste -sd' ' -) == "first second third" ]] || fail "--list shows the steps" "$list"
[[ $list == *"The 20-second step."* ]] || fail "--list shows each step's description" "$list"
[[ -z $(ran) ]] || fail "--list runs nothing"
pass "--list shows the steps without running them"

rm -f "$tmp/ran"
(cd / && env HOME="$home" "$tmp/checkout/scripts/steps/20-second.sh")
read -r _ cwd _ _ <"$tmp/ran"
[[ $cwd == "$tmp/checkout" ]] || fail "a step run on its own moves to the repo root" "$cwd"
pass "a step runs on its own from any directory"

# --- the one-liner ---------------------------------------------------------------
# A local copy of GitHub's archive URL, so the download path runs offline.
make_checkout "$tmp/src/.dotfiles-master" v1
mkdir -p "$tmp/web/archive/refs/heads"
tarball() { tar -czf "$tmp/web/archive/refs/heads/master.tar.gz" -C "$tmp/src" .dotfiles-master; }
tarball
oneliner() { run env DOTFILES_REPO="file://$tmp/web" DOTFILES_DIR="$home/.dotfiles" bash -c "$1" >/dev/null; }

oneliner "bash <(cat '$ROOT/install.sh')"
[[ $(ran) == "first second third" && $(awk 'NR==1{print $4}' "$tmp/ran") == "v1" ]] || fail "the one-liner downloads and runs every step" "$(cat "$tmp/ran")"
[[ $(awk 'NR==1{print $2}' "$tmp/ran") == "$home/.dotfiles" ]] || fail "it runs from ~/.dotfiles"
echo v2 >"$tmp/src/.dotfiles-master/VERSION"; touch "$home/.dotfiles/stale"; tarball
(cd "$tmp/checkout" && oneliner "cat '$ROOT/install.sh' | bash -s -- second")
[[ $(cat "$tmp/ran") == "second $home/.dotfiles $home/.config v2" ]] || fail "curl | bash from inside a checkout updates ~/.dotfiles and runs the named step there" "$(cat "$tmp/ran")"
[[ ! -e $home/.dotfiles/stale ]] || fail "a downloaded copy is replaced, not merged"
pass "the one-liner downloads, updates and runs steps from ~/.dotfiles"

echo "all install tests passed"
