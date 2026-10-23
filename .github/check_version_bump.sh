#!/usr/bin/env bash
# Fails when ipregion.sh changed since the given commit but SCRIPT_VERSION did not.
# Usage: check_version_bump.sh BASE_COMMIT   (all zeros or empty = new branch, nothing to compare)

base="${1:-}"

if [[ -z "$base" || "$base" =~ ^0+$ ]] || ! git cat-file -e "$base^{commit}" 2>/dev/null; then
  echo "No base commit to compare with, skipping"
  exit 0
fi

if git diff --quiet "$base" HEAD -- ipregion.sh; then
  echo "ipregion.sh unchanged since ${base:0:7}"
  exit 0
fi

old=$(git show "$base:ipregion.sh" | grep -m1 '^SCRIPT_VERSION=')
new=$(grep -m1 '^SCRIPT_VERSION=' ipregion.sh)

echo "before ${base:0:7}: $old"
echo "now:            $new"

if [[ "$old" == "$new" ]]; then
  echo "::error file=ipregion.sh::ipregion.sh changed but SCRIPT_VERSION was not bumped"
  exit 1
fi
