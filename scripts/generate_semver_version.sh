#!/bin/bash
# Generate SemVer 2.0 compliant version based on git history and context
# Usage: generate_semver_version.sh [options]
#
# This script generates semantic versions following SemVer 2.0:
# Format: major.minor.patch-prerelease.0+build_metadata
#
# Prerelease progression: alpha → beta → rc → release
#
# Environment variables:
#   GITHUB_EVENT_NAME     - Type of GitHub event (push, pull_request, etc.)
#   GITHUB_REF_TYPE       - Type of ref (tag, branch)
#   GITHUB_REF_NAME       - Name of the ref (tag name or branch name)
#   GITHUB_REF            - Full ref (refs/heads/main, refs/tags/v1.0.0)
#   GITHUB_EVENT_BASE_REF - Base ref for pull requests
#   MASTER_BRANCH_LIST    - Space-separated list of master branch prefixes
#
# Outputs (printed to stdout in key=value format):
#   RELEASE_VERSION=X.Y.Z-pre.0+metadata
#   RELEASE_REPO=repository-name

set -euo pipefail

# Default values
MASTER_BRANCH_LIST="${MASTER_BRANCH_LIST:-main master stable}"
# Regex to capture full prerelease identifiers including numeric suffixes
# Examples: v1.2.3, v1.2.3-alpha, v1.2.3-beta.1, v1.2.3-rc.2
VERSION_REGEX='v[0-9]{1,4}\.[0-9]{1,4}\.[0-9]{1,9}(-(alpha|beta|rc)(\.?[0-9]+)?)?'

# Function to get latest version from git tags and bump patch
# Returns version in format: major.minor.patch
get_bumped_version() {
    # Find the latest semver tag reachable from current branch
    LATEST_TAG=$(git describe --tags --abbrev=0 --match "v[0-9]*.[0-9]*.[0-9]*" 2>/dev/null || echo "v0.0.0")
    echo "Latest reachable tag: ${LATEST_TAG}" >&2

    # Parse the version (remove 'v' prefix and any suffix)
    VERSION_ONLY="${LATEST_TAG#v}"
    VERSION_ONLY="${VERSION_ONLY%%-*}"  # Remove anything after first dash

    # Split into major.minor.patch
    IFS='.' read -r MAJOR MINOR PATCH <<< "$VERSION_ONLY"
    MAJOR=${MAJOR:-0}
    MINOR=${MINOR:-0}
    PATCH=${PATCH:-0}

    # Bump patch version
    PATCH=$((PATCH + 1))

    echo "${MAJOR}.${MINOR}.${PATCH}"
}

# Main logic
main() {
    echo "=== SemVer Version Generator ===" >&2
    echo "GITHUB_REF: ${GITHUB_REF:-<not set>}" >&2
    echo "GITHUB_REF_NAME: ${GITHUB_REF_NAME:-<not set>}" >&2
    echo "GITHUB_REF_TYPE: ${GITHUB_REF_TYPE:-<not set>}" >&2
    echo "GITHUB_EVENT_NAME: ${GITHUB_EVENT_NAME:-<not set>}" >&2

    # Get short commit SHA for build metadata
    COMMIT_SHA=$(git rev-parse --short HEAD)
    echo "COMMIT_SHA: ${COMMIT_SHA}" >&2

    # Determine current branch for master branch detection
    if [[ "${GITHUB_REF_TYPE:-branch}" == "branch" ]]; then
        CURRENT_BRANCH_REF="${GITHUB_REF:-refs/heads/main}"
    else
        CURRENT_BRANCH_REF="${GITHUB_EVENT_BASE_REF:-refs/heads/main}"
    fi

    # Check if this is a commit/tag in the master branch
    IS_MASTER_BRANCH="no"
    CURRENT_BRANCH="${CURRENT_BRANCH_REF##refs/heads/}"
    for master_branch in $MASTER_BRANCH_LIST; do
        # Try to remove "master_branch" from "CURRENT_BRANCH" and check if it changes
        if [[ "${CURRENT_BRANCH##${master_branch}}" != "${CURRENT_BRANCH}" ]]; then
            IS_MASTER_BRANCH="yes"
            break
        fi
    done
    echo "CURRENT_BRANCH: ${CURRENT_BRANCH}" >&2
    echo "IS_MASTER_BRANCH: ${IS_MASTER_BRANCH}" >&2

    # Check what triggered this action: A Pull Request, a tag push or branch push
    TRIGGER="pull_request"
    if [[ "${GITHUB_EVENT_NAME:-pull_request}" == "push" ]]; then
        if [[ "${GITHUB_REF_TYPE:-branch}" == "tag" ]]; then
            TRIGGER="tag"
        else
            TRIGGER="branch"
        fi
    fi
    echo "TRIGGER: ${TRIGGER}" >&2

    RELEASE_VERSION=""
    RELEASE_REPO="packages-dev"  # Default to packages-dev, always release at minimum here

    if [[ "${TRIGGER}" == "branch" && "${IS_MASTER_BRANCH}" == "yes" ]]; then
        echo "This is a merge to master, lets make the Alpha nightly build" >&2

        # Get base version and prepare alpha nightly build following SemVer 2.0
        BASE_VERSION=$(get_bumped_version)

        # Prepare the branch name suffix following Debian and SemVer rules
        # - Only lowercase letters, numbers, '.', '+' and '-'
        BRANCH_SUFFIX="${GITHUB_REF_NAME@L}"
        BRANCH_SUFFIX=${BRANCH_SUFFIX//[^0-9a-z+.-]/-}

        # SemVer 2.0 format: major.minor.patch-prerelease.0+build_metadata
        # Nightly alpha format: X.Y.Z-alpha.0+YYYYMMDD.branch.sha
        BUILD_DATE=$(date +%Y%m%d)
        RELEASE_REPO="nightly-builds"
        RELEASE_VERSION="${BASE_VERSION}-alpha.0+${BUILD_DATE}.${BRANCH_SUFFIX}.${COMMIT_SHA}"

        echo "Alpha nightly build version: '${RELEASE_VERSION}'" >&2

    elif [[ "${TRIGGER}" == "tag" ]]; then
        echo "This is a tag push, lets parse the tag >${GITHUB_REF_NAME}< and check if we should release" >&2
        VERSION=$(echo "${GITHUB_REF_NAME}" | grep -o -E -e "${VERSION_REGEX}") || true   # Return true if grep finds nothing
        RELEASE_VERSION="${VERSION#v}"  # Remove the initial "v" leaving only the numbers and optional "-alpha", "-beta", "-rc"

        if [[ -z "${RELEASE_VERSION}" ]]; then
            echo "Failed to parse the tag, it does not follow the standard" >&2
            # Fall through to generate version from git tags
        elif [[ "${RELEASE_VERSION}" =~ (alpha|beta|rc) ]]; then
            echo "Success, this is a pre-release (alpha/beta/rc)" >&2
            RELEASE_REPO="packages-dev"
            # Tag-based releases use the tag as-is, no build metadata added
        else
            echo "Success, this is an official release" >&2
            RELEASE_REPO="packages-released"
            # Tag-based releases use the tag as-is, no build metadata added
        fi
    fi

    # If no valid version yet, generate one from git history
    # SemVer 2.0 format: major.minor.patch-pre.0+build_metadata
    if [[ -z "${RELEASE_VERSION}" ]]; then
        echo "Generating version from git tags following SemVer 2.0" >&2
        BASE_VERSION=$(get_bumped_version)
        # Format: X.Y.Z-alpha.0+sha (alpha is earliest pre-release stage)
        RELEASE_VERSION="${BASE_VERSION}-alpha.0+${COMMIT_SHA}"
        echo "Generated version: ${RELEASE_VERSION}" >&2
    fi

    echo "RELEASE_VERSION: ${RELEASE_VERSION}" >&2
    echo "RELEASE_REPO: ${RELEASE_REPO}" >&2

    # Output in format that can be sourced or parsed
    echo "RELEASE_VERSION=${RELEASE_VERSION}"
    echo "RELEASE_REPO=${RELEASE_REPO}"
}

# Run main function
main "$@"
