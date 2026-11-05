#!/usr/bin/env bash
#
# Simulate the Tekton pipeline locally, stage by stage, so the pipeline logic
# can be checked without an OpenShift cluster.
#
# Stages: cleanup -> git-clone -> flake8 -> nose -> buildah -> openshift-client
#
# Environment variables:
#   SKIP_BUILD=1   skip the container image build
#
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORKSPACE="$(mktemp -d -t pipeline-workspace.XXXXXX)"
trap 'rm -rf "$WORKSPACE"' EXIT

stage() {
    echo
    echo "=================================================="
    echo " $*"
    echo "=================================================="
}

stage "1/6 cleanup"
rm -rf "${WORKSPACE:?}"/* "${WORKSPACE:?}"/.[!.]* "${WORKSPACE:?}"/..?* 2>/dev/null || true
echo "Workspace is empty: $WORKSPACE"

stage "2/6 git-clone"
cp -a "$ROOT/." "$WORKSPACE/"
rm -rf "$WORKSPACE/.git" "$WORKSPACE/.venv" "$WORKSPACE/venv"
find "$WORKSPACE" -name "__pycache__" -type d -prune -exec rm -rf {} + 2>/dev/null || true
echo "Source copied into the workspace"

stage "3/6 flake8"
if command -v flake8 > /dev/null 2>&1; then
    (
        cd "$WORKSPACE"
        flake8 service --count --select=E9,F63,F7,F82 --show-source --statistics
        flake8 service --count --max-complexity=10 --max-line-length=127 --statistics
    )
else
    echo "flake8 is not installed - falling back to a syntax check"
    (cd "$WORKSPACE" && python3 -m compileall -q service)
fi

stage "4/6 nose"
if command -v nosetests > /dev/null 2>&1; then
    (
        cd "$WORKSPACE"
        nosetests -v --with-spec --spec-color --with-coverage --cover-package=service
    )
elif [ -n "${PYTHON:-}" ] || python3 -c "import flask" > /dev/null 2>&1; then
    echo "nose is not installed - running unittest instead"
    (cd "$WORKSPACE" && "${PYTHON:-python3}" -m unittest discover -s tests -t . -v)
else
    echo "nose and Flask are not installed - skipping the unit tests"
fi

stage "5/6 buildah"
if [ "${SKIP_BUILD:-0}" = "1" ]; then
    echo "SKIP_BUILD=1 - image build skipped"
elif command -v docker > /dev/null 2>&1 && docker info > /dev/null 2>&1; then
    docker build -t counter-service:local "$WORKSPACE"
else
    echo "Docker daemon is unavailable - image build skipped"
fi

stage "6/6 openshift-client"
echo "The real task runs:"
echo "  sed -i 's|IMAGE_PLACEHOLDER|<image>|g' openshift/deployment.yaml"
echo "  oc apply -f openshift/service.yaml"
echo "  oc apply -f openshift/deployment.yaml"
echo "  oc apply -f openshift/route.yaml"
echo "  oc rollout status deployment/counter-service"
echo
echo "Pipeline simulation finished successfully."
