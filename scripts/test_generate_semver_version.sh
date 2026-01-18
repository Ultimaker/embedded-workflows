#!/bin/bash
# Test script for generate_semver_version.sh
# Demonstrates different scenarios and how to test locally

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSION_SCRIPT="${SCRIPT_DIR}/generate_semver_version.sh"

echo "=========================================="
echo "Testing SemVer Version Generation Script"
echo "=========================================="
echo ""

# Test 1: Pull Request / Regular Commit (alpha version)
echo "Test 1: Pull Request / Regular Commit"
echo "Expected: X.Y.Z-alpha.0+sha"
export GITHUB_EVENT_NAME="pull_request"
export GITHUB_REF_TYPE="branch"
export GITHUB_REF_NAME="feature/test"
export GITHUB_REF="refs/heads/feature/test"
unset GITHUB_EVENT_BASE_REF
OUTPUT=$("$VERSION_SCRIPT")
echo "$OUTPUT"
echo ""

# Test 2: Master Branch Merge (nightly build - alpha)
echo "Test 2: Master Branch Merge (nightly build - alpha)"
echo "Expected: X.Y.Z-alpha.0+YYYYMMDD.main.sha"
export GITHUB_EVENT_NAME="push"
export GITHUB_REF_TYPE="branch"
export GITHUB_REF_NAME="main"
export GITHUB_REF="refs/heads/main"
OUTPUT=$("$VERSION_SCRIPT")
echo "$OUTPUT"
echo ""

# Test 3: Official Release Tag
echo "Test 3: Official Release Tag"
echo "Expected: X.Y.Z"
export GITHUB_EVENT_NAME="push"
export GITHUB_REF_TYPE="tag"
export GITHUB_REF_NAME="v1.2.3"
export GITHUB_REF="refs/tags/v1.2.3"
OUTPUT=$("$VERSION_SCRIPT")
echo "$OUTPUT"
echo ""

# Test 4: Alpha Release Tag
echo "Test 4: Alpha Release Tag"
echo "Expected: X.Y.Z-alpha"
export GITHUB_EVENT_NAME="push"
export GITHUB_REF_TYPE="tag"
export GITHUB_REF_NAME="v1.2.3-alpha"
export GITHUB_REF="refs/tags/v1.2.3-alpha"
OUTPUT=$("$VERSION_SCRIPT")
echo "$OUTPUT"
echo ""

# Test 5: Beta Release Tag
echo "Test 5: Beta Release Tag"
echo "Expected: X.Y.Z-beta.1"
export GITHUB_EVENT_NAME="push"
export GITHUB_REF_TYPE="tag"
export GITHUB_REF_NAME="v1.2.3-beta.1"
export GITHUB_REF="refs/tags/v1.2.3-beta.1"
OUTPUT=$("$VERSION_SCRIPT")
echo "$OUTPUT"
echo ""

# Test 6: Release Candidate Tag
echo "Test 6: Release Candidate Tag"
echo "Expected: X.Y.Z-rc.1"
export GITHUB_EVENT_NAME="push"
export GITHUB_REF_TYPE="tag"
export GITHUB_REF_NAME="v1.2.3-rc.1"
export GITHUB_REF="refs/tags/v1.2.3-rc.1"
OUTPUT=$("$VERSION_SCRIPT")
echo "$OUTPUT"
echo ""

# Test 7: Invalid Tag Format
echo "Test 7: Invalid Tag Format (should fall back to alpha)"
echo "Expected: X.Y.Z-alpha.0+sha"
export GITHUB_EVENT_NAME="push"
export GITHUB_REF_TYPE="tag"
export GITHUB_REF_NAME="random-tag"
export GITHUB_REF="refs/tags/random-tag"
OUTPUT=$("$VERSION_SCRIPT")
echo "$OUTPUT"
echo ""

echo "=========================================="
echo "All tests completed!"
echo "=========================================="
