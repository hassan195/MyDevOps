#!/usr/bin/env bash

archive_dir=$1
log_dir=$2 
for f in $"$log_dir"/*.log; do
  age=$(find $f -mtime +7) 
  if [ $age ]; then
  mv $f $archive_dir/
  count=$count+1
  fi
done
echo "Archived $count files"