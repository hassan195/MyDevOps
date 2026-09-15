#!/bin/sh

set -e

echo "Container started at $(date -u +"%Y-%m-%dT%H:%M:%SZ")"

exec nginx -g "daemon off;"