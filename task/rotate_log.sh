#!/usr/bin/env bash

if [ "$#" -ne 2 ]; then
  echo "Error: Two arguments required." >&2
  exit 1
fi

archive_dir="$1"
log_dir="$2"

if [ ! -d "$archive_dir" ]; then
  echo "Error: Archive directory does not exist." >&2
  exit 1
fi

if [ ! -d "$log_dir" ]; then
  echo "Error: Log directory does not exist." >&2
  exit 1
fi

for f in $"$log_dir"/*.log; do
  age=$(find "$f" -mtime +7) 
  if [ "$age" ]; then
  mv "$f" "$archive_dir/"
  count=$(($count+1))
  fi
done
echo "Archived $count files"