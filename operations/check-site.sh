#!/bin/bash
set -euo pipefail

site=https://posthales.github.io/ring-recall-support
scratch=$(mktemp -d)
trap 'rm -rf -- "$scratch"' EXIT

check_page() {
    local path=$1 title=$2 counterpart=$3
    local body="$scratch/page.html"
    if ! curl --silent --show-error --fail --proto '=https' --connect-timeout 8 \
            --max-time 15 --retry 2 --retry-all-errors --retry-delay 2 --retry-max-time 45 \
            --output "$body" "$site/$path"; then
        printf 'Could not load %s after retrying. Inspect the GitHub Pages deployment.\n' "$path" >&2
        return 1
    fi
    if ! grep -Fq "$title" "$body" ||
        ! grep -Fq 'mailto:support@hibarimadeit.com?subject=Ring%20Recall%20support' "$body" ||
        ! grep -Fq "href=\"$counterpart\"" "$body"; then
        printf '%s is missing its expected title, contact, or navigation link.\n' "$path" >&2
        return 1
    fi
    printf '%s passed\n' "$path"
}

case ${1:-live} in
    live)
        check_page support.html 'Course help' privacy.html
        check_page privacy.html 'Privacy policy' support.html
        ;;
    test-missing-page)
        check_page check-intentionally-missing.html 'Not published' support.html
        ;;
    *)
        printf 'Invalid check mode.\n' >&2
        exit 2
        ;;
esac
