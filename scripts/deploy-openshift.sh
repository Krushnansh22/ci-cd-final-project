#!/usr/bin/env bash
#
# Apply the Tekton resources and start a pipeline run.
#
# Required environment variables:
#   REPO_URL         your GitHub repository, e.g. https://github.com/you/ci-cd-final-project.git
#   IMAGE_REFERENCE  the image to build, e.g.
#                    image-registry.openshift-image-registry.svc:5000/sn-labs-you/ci-cd-final-project:latest
#
# Optional:
#   REVISION         branch to build (default: main)
#
set -euo pipefail
cd "$(dirname "$0")/.."

: "${REPO_URL:?Set REPO_URL to your GitHub repository}"
: "${IMAGE_REFERENCE:?Set IMAGE_REFERENCE to the image to build}"
REVISION="${REVISION:-main}"

echo "==> Applying Tekton resources"
oc apply -f .tekton/tasks.yml
oc apply -f .tekton/pipeline.yml
oc apply -f .tekton/pvc.yml

PROJECT="$(oc project -q)"
echo "==> Granting the pipeline service account permission in $PROJECT"
oc policy add-role-to-user edit "system:serviceaccount:${PROJECT}:pipeline" || true
oc policy add-role-to-user system:image-builder "system:serviceaccount:${PROJECT}:pipeline" || true

echo "==> Starting the pipeline"
tkn pipeline start ci-cd-pipeline --showlog \
    --workspace name=shared-workspace,claimName=pipeline-workspace \
    --workspace name=dockerconfig,secret=registry-dockerconfig-secret \
    --param repo-url="$REPO_URL" \
    --param revision="$REVISION" \
    --param image-reference="$IMAGE_REFERENCE"
