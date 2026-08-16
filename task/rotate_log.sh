#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $0 <archive_dir> <log_dir>"
  exit 1
}

if [ "$#" -ne 2 ]; then
  echo "Error: Two arguments required." >&2
  usage
fi

archive_dir="$1"
log_dir="$2"

if [ ! -d "$archive_dir" ]; then
  echo "Error: Archive directory does not exist." >&2
  usage
fi

if [ ! -d "$log_dir" ]; then
  echo "Error: Log directory does not exist." >&2
  usage
fi

count=0
for f in $"$log_dir"/*.log; do
  age=$(find "$f" -type f -mtime +7 2>/dev/null ) || true
  if [ -n "$age" ]; then
    mv "$f" "$archive_dir/"
    count=$((count+1))
  fi
done
echo "Archived $count files"