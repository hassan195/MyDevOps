#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $0 <log_dir>
        Exit codes:
        0 - nothing flagged for review
        1 - some files flagged for review
        2 - Invalid number of arguments
        3 - Log directory does not exist or is not readable"
}

log() {
  local message="$1"
  echo "$message"
}

die() {
  local message="$1"
  if [ "$2" -eq 2 ] || [ "$2" -eq 3 ]; then
    log "Error: $message" >&2
    usage
  fi
  exit "$2"
}

if [ "$#" -ne 1 ]; then
  die "One arguments required." 2
fi

log_dir="$1"

if [ ! -d "$log_dir" ] || [ ! -r "$log_dir" ]; then
  die "Error: $log_dir does not exist or is not readable." 3
fi

scanned_count=0
flagged_count=0

for f in "$log_dir"/*.log; do
  error_count=0
  error_count=$(grep -c "ERROR" "$f" || true)
  log "$f: $error_count errors"
# mkdir -p "$log_dir/review" &&  cp "$f" "$log_dir/review/"
  if [ "$error_count" -gt 10 ]; then
    if [ ! -d "$log_dir/review" ]; then
      mkdir "$log_dir/review"
    fi
    cp "$f" "$log_dir/review/"
    flagged_count=$((flagged_count + 1))
  fi 
  scanned_count=$((scanned_count + 1))
done

log "$scanned_count files scanned and $flagged_count files flagged for review."

if [ "$flagged_count" -gt 0 ]; then
  die "$flagged_count files flagged for review." 1
fi