#! /usr/bin/env bash
set -euo pipefail

log(){
  printf "[%s] %s\n" "$(date +'%Y-%m-%d %H:%M:%S')" "$*"
}

die(){
  printf "[%s] FAILED: %s\n" "$(date +'%Y-%m-%d %H:%M:%S')" "$*" >&2
  exit 1
}


DOCKERFILE="${DOCKERFILE:-Dockerfile}"
SCAN_PATH="${SCAN_PATH:-.}"
SEVERITY="${SEVERITY:-HIGH,CRITICAL}"

status=0
declare -a summary=()


[[ -f "${DOCKERFILE}" ]] || die "Dockerfile not found: ${DOCKERFILE}"
[[ -d "${SCAN_PATH}" ]] || die "Scan path not found: ${SCAN_PATH}"


check() {
    local check_name="$1"
    shift
    local result=0

    log "Running check: ${check_name}..."

    if "$@"; then
        result=0
    else
        result=$?
    fi

    if [[ "${result}" -eq 0 ]]; then
        summary+=("${check_name}: PASSED")
        log "${check_name} PASSED"
    else
        summary+=("${check_name}: FAILED")
        log "${check_name} FAILED"
        status=1
    fi
}


check "hadolint" hadolint "${DOCKERFILE}"
check "trivy config" trivy config --severity "${SEVERITY}" --exit-code 1 "${SCAN_PATH}"
check "trivy fs" trivy fs --scanners vuln,secret --severity "${SEVERITY}" --exit-code 1 "${SCAN_PATH}"


log "Security checks completed. Summary:"
for line in "${summary[@]}"; do
    log "${line}"
done    

if [[ "${status}" -eq 0 ]]; then
    log "All security checks passed."
else
    die "Some security checks failed. See summary above."
fi

exit "${status}"