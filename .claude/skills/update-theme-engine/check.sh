#!/usr/bin/env bash
# Compare the pinned theme engine with an upstream release and test
# theme-switcher against that release, without changing anything real: the
# engine is installed into a scratch HOME, themes are applied with no desktop,
# terminal or app changes and a private tmux server, and the repo is only read.
#
# Usage: check.sh [--from <ref>] [--all-themes] [--keep] [<tag>]
#   <tag>          upstream release tag to check (default: the latest release)
#   --from <ref>   compare from this tag or commit instead of THEME_ENGINE_REF
#   --all-themes   apply every theme of the release, not just the ones at risk
#   --keep         keep the scratch dir (printed at the end) for inspection
#
# Lines starting with "!!" need action before the pin can move. Exit status is
# 0 with none, 1 with some, 2 on a usage or setup error.
set -euo pipefail

# mapfile and associative arrays need bash 4+; macOS /bin/bash is 3.2.
if ((BASH_VERSINFO[0] < 4)); then
  for b in /opt/homebrew/bin/bash /usr/local/bin/bash; do
    [[ -x $b ]] && exec "$b" "$0" "$@"
  done
  echo "check.sh needs bash 4+ (brew install bash)" >&2
  exit 2
fi

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)
SWITCHER="$ROOT/local/bin/theme-switcher"

from="" tag="" all_themes=false keep=false
while (($#)); do
  case $1 in
    --from) from=${2:?--from needs a ref}; shift 2 ;;
    --all-themes) all_themes=true; shift ;;
    --keep) keep=true; shift ;;
    -h|--help) sed -n '2,15p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -*) echo "unknown option: $1" >&2; exit 2 ;;
    *) tag=$1; shift ;;
  esac
done

flags=0
flag() { echo "!! $*"; flags=$((flags + 1)); }
section() { printf '\n== %s\n' "$*"; }

# --- What the repo pins and calls --------------------------------------------
name=$(sed -n 's/^ENGINE_NAME=//p' "$SWITCHER")
repo=$(sed -n 's/^ENGINE_REPO="\(.*\)"$/\1/p' "$SWITCHER")
repo=${repo//\$ENGINE_NAME/$name}
pin=$(sed -n 's/^THEME_ENGINE_REF=//p' "$ROOT/scripts/common")
slug=$(sed -E 's#^https://github.com/##; s#\.git$##' <<<"$repo")
[[ -n $name && -n $repo && $pin =~ ^[0-9a-f]{40}$ ]] || { echo "could not read ENGINE_NAME, ENGINE_REPO or THEME_ENGINE_REF" >&2; exit 2; }

# The engine scripts theme-switcher runs directly, and the ones it stands in
# for: every ENGINE_*="$ENGINE_NAME-..." line.
mapfile -t shimmed < <(sed -nE 's/^ENGINE_[A-Z_]+="\$ENGINE_NAME-([a-z0-9-]+)"$/\1/p' "$SWITCHER")
# Of those, the ones run for real (the rest are stand-ins written in engine()).
mapfile -t run_real < <(sed -nE 's/^ *for name in (.*); do$/\1/p' "$SWITCHER" | grep -oE 'ENGINE_[A-Z_]+' |
  while read -r v; do sed -nE "s/^$v=\"\\\$ENGINE_NAME-([a-z0-9-]+)\"$/\\1/p" "$SWITCHER"; done)

# Themes the repo names: the installer's default and the ones the tests set.
# Names the tests make up themselves (alpha, hostile) are dropped below, once
# the engine is fetched, as names that are not engine themes at the pin.
mapfile -t named_themes < <(
  { sed -nE 's/.*theme-switcher" set ([a-z0-9-]+)$/\1/p' "$ROOT/scripts/steps/90-themes.sh"
    grep -hoE '(theme|COMMAND"?) set ("[^"]+"|[a-z0-9-]+)' "$ROOT"/tests/*-test.sh |
      sed -E 's/.* set //; s/"//g' | tr 'A-Z ' 'a-z-'
  } | sort -u)
current_theme=$(cat "$HOME/.local/state/theme-switcher/current/theme.name" 2>/dev/null || true)

# --- Upstream ----------------------------------------------------------------
if [[ -z $tag ]]; then
  tag=$(gh release view -R "$slug" --json tagName -q .tagName) || { echo "could not read the latest release of $slug (pass a tag)" >&2; exit 2; }
fi

work=$(mktemp -d)
cleanup() { $keep || rm -rf "$work"; }
trap cleanup EXIT
up="$work/up"
git clone -q --filter=blob:none --no-checkout "$repo" "$up"
git -C "$up" fetch -q --tags origin
G() { git -C "$up" "$@"; }
# Diffing wallpapers or previews would download them; text files only.
TEXT_ONLY=(':(glob,exclude)themes/*/backgrounds/**' ':(glob,exclude)themes/*/*.png')

to=$(G rev-parse --verify -q "$tag^{commit}") || { echo "no such tag upstream: $tag" >&2; exit 2; }
from=${from:-$pin}
from=$(G rev-parse --verify -q "$from^{commit}") || { echo "the base commit is not upstream: $from" >&2; exit 2; }
from_tag=$(G describe --tags --exact-match "$from" 2>/dev/null || echo "${from:0:12}")
prerelease=$(gh release view "$tag" -R "$slug" --json isPrerelease -q .isPrerelease 2>/dev/null || echo unknown)

section "Versions"
echo "repo:    $repo"
echo "pinned:  $pin ($(G describe --tags --exact-match "$pin" 2>/dev/null || echo untagged))"
echo "from:    $from ($from_tag)"
echo "to:      $to ($tag, prerelease: $prerelease)"
if [[ $from == "$to" ]]; then
  echo "from and to are the same commit: nothing to compare."
elif G merge-base --is-ancestor "$from" "$to"; then
  echo "commits: $(G rev-list --count "$from..$to")"
else
  echo "note:    $from_tag is not an ancestor of $tag (different release branch); the diff is still tree to tree"
fi
[[ $prerelease == false ]] || flag "$tag is a prerelease; pin only a full release unless asked"

# --- Themes ------------------------------------------------------------------
section "Themes"
themes_at() { G ls-tree --name-only "$1" themes/ | sed 's#^themes/##'; }
mapfile -t added < <(comm -13 <(themes_at "$from") <(themes_at "$to"))
mapfile -t removed < <(comm -23 <(themes_at "$from") <(themes_at "$to"))
echo "added:   ${added[*]:-none}"
echo "removed: ${removed[*]:-none}"
for t in "${removed[@]}"; do
  why=$(G log --format='%h %s' -1 "$from..$to" -- "themes/$t" 2>/dev/null || true)
  [[ -n $why ]] && echo "         $t: $why"
done
mapfile -t named_themes < <(for t in "${named_themes[@]}"; do G cat-file -e "$pin:themes/$t" 2>/dev/null && echo "$t"; done)
echo "used by the installer and tests: ${named_themes[*]:-none}"
for t in "${named_themes[@]}"; do
  G cat-file -e "$to:themes/$t/colors.toml" 2>/dev/null || flag "theme '$t' is used by the installer or tests but has no colors.toml in $tag"
done
if [[ -n $current_theme ]] && G cat-file -e "$from:themes/$current_theme" 2>/dev/null && ! G cat-file -e "$to:themes/$current_theme" 2>/dev/null; then
  echo "note:    this Mac's current theme ($current_theme) is gone in $tag; tell the user to pick another"
fi
echo "text files changed (palettes, neovim.lua, vscode.json, ...):"
G diff -M --numstat "$from" "$to" -- themes "${TEXT_ONLY[@]}" | awk -F '\t' '$1 != "-" { printf "  +%s -%s %s\n", $1, $2, $3 }'

# --- Wallpapers --------------------------------------------------------------
section "Wallpapers"
image_re=$(sed -nE "s/^IMAGE_PATTERN='(.*)'$/\\1/p" "$SWITCHER")
echo "extensions in $tag (files directly in backgrounds/):"
G ls-tree -r --name-only "$to" themes | grep -E '^themes/[^/]+/backgrounds/[^/]+$' | sed -E 's/.*\.//' | tr 'A-Z' 'a-z' | sort | uniq -c | sed 's/^/ /'
while read -r f; do
  flag "wallpaper $f does not match theme-switcher's IMAGE_PATTERN"
done < <(G ls-tree -r --name-only "$to" themes | grep -E '^themes/[^/]+/backgrounds/[^/]+$' | grep -viE "$image_re" || true)
subdirs=$(G ls-tree -r -d --name-only "$to" themes | grep -E '/backgrounds/' | sed -E 's#^themes/[^/]+/backgrounds/##' | sort | uniq -c || true)
echo "subfolders of backgrounds/ (skipped, files only): ${subdirs:- none}"

# --- Templates ---------------------------------------------------------------
section "Templates (default/themed)"
G diff --name-status "$from" "$to" -- default/themed | sed 's/^/  /'
funcs() { G grep -hoE '\{\{ *[a-z_]+ [^}]*\}\}' "$1" -- default/themed 2>/dev/null | sed -E 's/^\{\{ *([a-z_]+) .*/\1/' | sort -u; }
new_funcs=$(comm -13 <(funcs "$from") <(funcs "$to") | tr '\n' ' ')
echo "template functions new in $tag: ${new_funcs:-none}"

# --- Engine scripts ----------------------------------------------------------
section "Engine scripts"
for s in "${shimmed[@]}"; do
  if G cat-file -e "$to:bin/$name-$s" 2>/dev/null; then
    stat=$(G diff --numstat "$from" "$to" -- "bin/$name-$s" | awk '{print "+"$1" -"$2}')
    printf '  %-36s %s\n' "$s" "${stat:-unchanged}"
  else
    printf '  %-36s %s\n' "$s" "not in $tag"
    [[ " ${run_real[*]} " == *" $s "* ]] && flag "theme-switcher runs $name-$s, which $tag no longer has"
  fi
done

# Every engine command the scripts theme-switcher runs call, outside comments.
# One theme-switcher does not provide fails with "command not found".
calls() {
  local ref=$1 s
  for s in "${run_real[@]}"; do
    G show "$ref:bin/$name-$s" 2>/dev/null | grep -vE '^[[:space:]]*#' | grep -oE "\\b$name-[a-z0-9-]+" || true
  done | sed "s/^$name-//" | sort -u
}
while read -r c; do
  [[ -n $c ]] || continue
  [[ " ${shimmed[*]} " == *" $c "* ]] && continue
  if G cat-file -e "$to:bin/$name-$c" 2>/dev/null; then
    summary=$(G show "$to:bin/$name-$c" | sed -nE "s/^# $name:summary=//p")
    flag "$name-$c is called by the scripts theme-switcher runs but has no shim: ${summary:-no summary}"
  else
    echo "  (calls $name-$c, which is not a script in bin/; likely a name in a string)"
  fi
done < <(calls "$to")

# GNU-only features in the scripts theme-switcher runs. macOS has BSD tools;
# awk is gawk through the shims, sed/grep/date/stat/find are not.
section "GNU-only features (count at $from_tag -> $tag)"
gnu_patterns=(
  'awk RT|\bRT\b'
  'awk gensub/strtonum/asort/PROCINFO|\b(gensub|strtonum|asorti?|PROCINFO)\b'
  "sed -i without a suffix|\bsed (-E )?-i (-E )?['\"]?[s/0-9]"
  'grep -P|\bgrep -[a-zA-Z]*P'
  'date -d|\bdate -d\b|--date'
  'stat -c|\bstat -c\b|--format'
  'find -printf|-printf\b'
  'readlink -f/realpath -m|readlink -f|realpath -m'
  'xargs -r|\bxargs -r\b'
  'base64 -w|\bbase64 -w'
)
for entry in "${gnu_patterns[@]}"; do
  label=${entry%%|*} re=${entry#*|}
  count_at() { local ref=$1 s n=0; for s in "${run_real[@]}"; do n=$((n + $(G show "$ref:bin/$name-$s" 2>/dev/null | grep -vE '^[[:space:]]*#' | grep -cE -- "$re" || true))); done; echo "$n"; }
  a=$(count_at "$from") b=$(count_at "$to")
  printf '  %-34s %s -> %s\n' "$label" "$a" "$b"
  if ((b > a)); then
    case $label in
      awk*) echo "     (awk runs as gawk through the shims; confirm with the tests below)" ;;
      *) flag "$label is new in $tag in a script theme-switcher runs; macOS lacks it" ;;
    esac
  fi
done

# --- Settings the repo copied from the engine project ------------------------
section "Copied settings"
copied=(config/tmux/tmux.conf config/ghostty/config config/alacritty/alacritty.toml config/kitty/kitty.conf default/bash/aliases default/bash/fns/tmux)
for p in "${copied[@]}"; do
  a=$(G rev-parse -q --verify "$from:$p" || echo -) b=$(G rev-parse -q --verify "$to:$p" || echo -)
  if [[ $a == "$b" ]]; then printf '  %-34s unchanged\n' "$p"; else printf '  %-34s CHANGED (diff below)\n' "$p"; fi
done
for p in "${copied[@]}"; do
  G diff --quiet "$from" "$to" -- "$p" 2>/dev/null || { echo; G diff "$from" "$to" -- "$p"; }
done

# --- Install the release into a scratch HOME and test ------------------------
section "Tests against $tag"
home="$work/home"
mkdir -p "$home"
if ! HOME=$home XDG_DATA_HOME="" "$SWITCHER" engine install "$to" >"$work/install.log" 2>&1; then
  cat "$work/install.log"; flag "theme-switcher engine install $to failed"
else
  engine="$home/.local/share/theme-switcher/.engine"
  for t in "$ROOT"/tests/*-test.sh; do
    grep -q 'local/bin/theme-switcher' "$t" || continue
    n=$(basename "$t")
    if THEME_SWITCHER_ENGINE=$engine THEME_SWITCHER_TEST_REQUIRE_ENGINE=1 bash "$t" >"$work/$n.log" 2>&1; then
      printf '  %-28s pass (%s ok)\n' "$n" "$(grep -c '^ok' "$work/$n.log")"
    else
      printf '  %-28s FAIL\n' "$n"; grep -v '^ok' "$work/$n.log" | tail -6 | sed 's/^/     /'
      flag "$n fails against $tag"
    fi
  done

  # --- Apply themes ------------------------------------------------------------
  if $all_themes; then
    mapfile -t check < <(themes_at "$to")
  else
    # Themes whose palette or other text files changed; not wallpapers alone.
    mapfile -t changed < <(G diff --no-renames --name-only "$from" "$to" -- themes "${TEXT_ONLY[@]}" | cut -d/ -f2 | sort -u)
    mapfile -t intros < <(G ls-tree -r -d --name-only "$to" themes | grep -E '/backgrounds/[^/]+$' | cut -d/ -f2 | sort -u)
    mapfile -t check < <(printf '%s\n' "${added[@]}" "${changed[@]}" "${named_themes[@]}" "${intros[@]:0:3}" ${current_theme:+"$current_theme"} |
      grep . | sort -u | while read -r t; do G cat-file -e "$to:themes/$t" 2>/dev/null && echo "$t"; done)
  fi
  section "Applying ${#check[@]} theme(s) in a scratch HOME"
  sethome="$work/sethome"
  mkdir -p "$sethome" "$work/tmux"
  for t in "${check[@]}"; do
    out="$sethome/.local/state/theme-switcher/current/theme"
    if HOME=$sethome THEME_SWITCHER_ENGINE=$engine THEME_SWITCHER_NO_DESKTOP=1 THEME_SWITCHER_TERMINALS="" THEME_SWITCHER_APPS="" \
        TMUX="" TMUX_TMPDIR="$work/tmux" "$SWITCHER" set "$t" >"$work/set.log" 2>&1; then
      problems=()
      [[ $(wc -l <"$out/ghostty.conf") -gt 10 ]] || problems+=("ghostty.conf has $(wc -l <"$out/ghostty.conf") lines")
      grep -q '^background = #[0-9a-fA-F]\{6\}$' "$out/ghostty.conf" || problems+=("ghostty.conf has no background color")
      ! grep -rIqE '\{\{[^}]*\}\}' "$out" || problems+=("a {{ }} placeholder survived")
      if ((${#problems[@]})); then
        flag "$t: ${problems[*]}"
      else
        printf '  %-22s ok  %s\n' "$t" "$(grep -m1 '^Imported' "$work/set.log" || true)"
      fi
    else
      flag "$t: set failed: $(tail -2 "$work/set.log" | tr '\n' ' ')"
    fi
  done
fi

section "Result"
if ((flags)); then echo "$flags item(s) need action (lines starting with !!)."; else echo "Nothing blocks moving the pin to $tag ($to)."; fi
$keep && echo "scratch dir kept: $work"
((flags == 0))
