#!/bin/zsh
set -u

usage() {
  echo "Usage: $0 {init|check|update} path/to/folder"
  exit 1
}

[[ $# -eq 2 ]] || usage

mode="$1"
target="$2"

[[ -d "$target" ]] || { echo "Folder not found: $target"; exit 1; }

target="$(cd "$target" && pwd -P)"
store="$HOME/Documents/Integrity-Manifests"
mkdir -p "$store"

label="$(basename "$target" | tr -c 'A-Za-z0-9._-' '_')"
id="$(printf '%s' "$target" | shasum -a 256 | awk '{print substr($1,1,12)}')"
base="$store/$label-$id"

manifest="$base.sha256"
baseline="$base.files"
current="$base.current"

make_list() {
  find "$target" -type f -not -name ".DS_Store" -print | LC_ALL=C sort
}

make_hashes() {
  while IFS= read -r file; do
    shasum -a 256 "$file"
  done
}

case "$mode" in
  init)
    [[ ! -e "$manifest" ]] || {
      echo "A baseline already exists. Use 'check' or 'update'."
      exit 1
    }
    make_list > "$baseline"
    make_hashes < "$baseline" > "$manifest"
    echo "Baseline saved."
    echo "Files: $baseline"
    echo "Hashes: $manifest"
    ;;

  check)
    [[ -f "$manifest" && -f "$baseline" ]] || {
      echo "No baseline exists yet. Run 'init' first."
      exit 1
    }

    echo "Checking original files:"
    if shasum -a 256 -c "$manifest"; then
      hashes_ok=true
    else
      hashes_ok=false
    fi

    make_list > "$current"

    added="$(comm -13 "$baseline" "$current")"
    removed="$(comm -23 "$baseline" "$current")"

    [[ -n "$added" ]] && echo "\nNew files:" && echo "$added"
    [[ -n "$removed" ]] && echo "\nRemoved files:" && echo "$removed"

    rm -f "$current"

    if [[ "$hashes_ok" == true && -z "$added" && -z "$removed" ]]; then
      echo "\nResult: no unexpected changes detected."
    else
      echo "\nResult: review the changes above."
      exit 2
    fi
    ;;

  update)
    echo "Replacing the baseline—only do this after reviewing changes."
    make_list > "$baseline"
    make_hashes < "$baseline" > "$manifest"
    echo "Baseline updated."
    ;;

  *)
    usage
    ;;
esac
