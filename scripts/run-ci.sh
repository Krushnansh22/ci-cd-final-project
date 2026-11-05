#!/usr/bin/env bash
#
# Run the same checks as the GitHub Actions CI workflow.
#
set -euo pipefail
cd "$(dirname "$0")/.."

echo "==> Lint with flake8"
flake8 service --count --select=E9,F63,F7,F82 --show-source --statistics
flake8 service --count --max-complexity=10 --max-line-length=127 --statistics

echo "==> Unit tests with nose"
nosetests -v --with-spec --spec-color --with-coverage --cover-package=service

echo "==> Coverage report"
coverage report -m

echo "CI checks passed."
