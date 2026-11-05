#!/usr/bin/env bash
#
# Publish this project to GitHub.
#
# Usage:
#   bash scripts/publish.sh [github-user] [repository-name]
#
# The repository must already exist and be empty. Create it once at:
#   https://github.com/new?name=ci-cd-final-project
#
set -euo pipefail
cd "$(dirname "$0")/.."

USER_NAME="${1:-Krushnansh22}"
REPO_NAME="${2:-ci-cd-final-project}"
REMOTE="git@github.com:${USER_NAME}/${REPO_NAME}.git"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git init -b main
fi

if git remote get-url origin >/dev/null 2>&1; then
    git remote set-url origin "$REMOTE"
else
    git remote add origin "$REMOTE"
fi

echo "Pushing main to ${REMOTE} ..."
git push -u origin main

echo
echo "Repository : https://github.com/${USER_NAME}/${REPO_NAME}"
echo "README     : https://github.com/${USER_NAME}/${REPO_NAME}/blob/main/README.md"
echo "Workflow   : https://github.com/${USER_NAME}/${REPO_NAME}/blob/main/.github/workflows/workflow.yml"
echo "Tasks      : https://github.com/${USER_NAME}/${REPO_NAME}/blob/main/.tekton/tasks.yml"
