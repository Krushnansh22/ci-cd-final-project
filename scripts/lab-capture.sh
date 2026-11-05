#!/usr/bin/env bash
#
# Print the live OpenShift evidence for the final submission.
# Run this inside the IBM Skills Network lab after the pipeline succeeds.
#
# It prints the text used by Questions 4 and 8 and the data to capture for the
# three console screenshots (Questions 5, 6 and 7).
#
set -euo pipefail

echo "=================================================================="
echo " OpenShift project"
echo "=================================================================="
oc project -q
oc whoami

echo
echo "=================================================================="
echo " PVC — pipeline-workspace (Question 5)"
echo "=================================================================="
oc get pvc pipeline-workspace -o wide
oc describe pvc pipeline-workspace

echo
echo "=================================================================="
echo " Pipeline — ci-cd-pipeline (Question 6)"
echo "=================================================================="
tkn pipeline describe ci-cd-pipeline

echo
echo "=================================================================="
echo " Last PipelineRun (Question 7)"
echo "=================================================================="
tkn pipelinerun describe --last

echo
echo "=================================================================="
echo " PipelineRun logs (Questions 4 and 7)"
echo "=================================================================="
tkn pipelinerun logs --last

echo
echo "=================================================================="
echo " Application logs — counter-service (Question 8)"
echo "=================================================================="
oc logs deployment/counter-service --tail=50

echo
echo "=================================================================="
echo " Deployment and route"
echo "=================================================================="
oc get deployment counter-service
oc get route counter-service

echo
echo "Open the console at:"
echo "  https://console-openshift-console.apps.<cluster-domain>/"
echo "and capture:"
echo "  Storage -> PersistentVolumeClaims -> pipeline-workspace"
echo "  Pipelines -> ci-cd-pipeline"
echo "  Pipelines -> PipelineRuns -> the succeeded run"
