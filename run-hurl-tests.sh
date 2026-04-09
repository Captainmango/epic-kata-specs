#!/bin/sh

# Run task-manager.hurl test suite with HTML report
# Usage: ./run-hurl-tests.sh [host]
# Default host: http://localhost:8080

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HURL_FILE="$SCRIPT_DIR/api/task-manager.hurl"
REPORT_DIR="$SCRIPT_DIR/test-reports/hurl-report"

# Allow overriding the host via command line or environment variable
HOST="${1:-${HURL_HOST:-http://localhost:3000}}"

echo "Running Hurl test suite..."
echo "Host: $HOST"
echo "Hurl file: $HURL_FILE"
echo "Report directory: $REPORT_DIR"
echo ""

# Create report directory if it doesn't exist
mkdir -p "$REPORT_DIR"

# Run hurl with HTML report
hurl --test \
     --variable host="$HOST" \
     --report-html "$REPORT_DIR" \
     "$HURL_FILE"

echo ""
echo "✓ Test suite completed successfully!"
echo "HTML report available at: $REPORT_DIR/index.html"
