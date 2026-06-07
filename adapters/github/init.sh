#!/bin/bash
# IEF GitHub-First Ingestion Adapter -- Bootstrap Stub
# Stage D P0: placeholder for future implementation
# Usage: bash init.sh [project-dir]

set -e

PROJECT_DIR="${1:-.}"

echo "=== IEF GitHub Adapter: Bootstrap ==="
echo "Project directory: $PROJECT_DIR"
echo ""
echo "This is a placeholder bootstrap script."
echo "The GitHub-first ingestion contract spec is defined in:"
echo "  adapters/github/AGENTS.md"
echo ""
echo "Implementation status: CONTRACT SPEC ONLY"
echo "No runtime components are deployed at this stage."
echo ""
echo "To integrate:"
echo "  1. Read adapters/github/AGENTS.md for the full contract spec."
echo "  2. Implement HostEvent normalization per Phase 1.1."
echo "  3. Implement dedupe key computation per Phase 1.2."
echo "  4. Implement idempotent replay per Phase 1.3."
echo "  5. Implement TaskEnvelope production per Phase 1.4."
echo "  6. Enforce no-fake-completion rule per Phase 1.5."
echo "  7. Enforce auth/identity boundary per Phase 1.6."
echo ""
echo "=== Bootstrap complete ==="
