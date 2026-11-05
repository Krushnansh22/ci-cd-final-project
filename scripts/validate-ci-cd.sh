#!/usr/bin/env bash
#
# Validate every YAML file used by the CI/CD project and check that the
# pipeline stages are wired together in the expected order.
#
set -euo pipefail
cd "$(dirname "$0")/.."

python3 - <<'PY'
import sys
from pathlib import Path

import yaml

failures = []


def check(name, condition, detail=""):
    if condition:
        print(f"PASS  {name}")
    else:
        failures.append(name)
        print(f"FAIL  {name} {detail}")


def load(path):
    with open(path, encoding="utf-8") as handle:
        return list(yaml.safe_load_all(handle))


def load_one(path):
    return yaml.safe_load(Path(path).read_text(encoding="utf-8"))


# ------------------------------------------------------------ workflow
workflow = load_one(".github/workflows/workflow.yml")
check("workflow has a name", bool(workflow.get("name")))
check("workflow runs on push", "push" in workflow.get(True, workflow.get("on", {})))
check("workflow has a build job", "build" in workflow.get("jobs", {}))
steps = workflow["jobs"]["build"]["steps"]
step_names = [step.get("name", "") for step in steps]
for expected in ["Checkout", "Install dependencies", "Lint with flake8",
                 "Run unit tests with nose"]:
    check(f"workflow has step: {expected}", expected in step_names)
check(
    "workflow checks out the repository",
    any("actions/checkout" in str(step.get("uses", "")) for step in steps),
)
check(
    "workflow runs flake8",
    any("flake8" in str(step.get("run", "")) for step in steps),
)
check(
    "workflow runs nose",
    any("nosetests" in str(step.get("run", "")) for step in steps),
)
check(
    "workflow covers the service package",
    any("cover-package=service" in str(step.get("run", "")) for step in steps),
)

# ------------------------------------------------------------ tasks
task_docs = [doc for doc in load(".tekton/tasks.yml") if doc]
task_names = {doc["metadata"]["name"] for doc in task_docs}
check("tasks.yml declares cleanup", "cleanup" in task_names)
check("tasks.yml declares flake8", "flake8" in task_names)
check("tasks.yml declares nose", "nose" in task_names)
for doc in task_docs:
    check(f"task {doc['metadata']['name']} is a Tekton Task",
          doc.get("kind") == "Task")
    check(f"task {doc['metadata']['name']} declares a source workspace",
          any(ws["name"] == "source" for ws in doc["spec"].get("workspaces", [])))

# ------------------------------------------------------------ pipeline
pipeline = load_one(".tekton/pipeline.yml")
check("pipeline is a Tekton Pipeline", pipeline.get("kind") == "Pipeline")
pipeline_tasks = pipeline["spec"]["tasks"]
pipeline_names = [task["name"] for task in pipeline_tasks]
check(
    "pipeline has all six stages",
    pipeline_names == ["cleanup", "git-clone", "flake8", "nose",
                       "build-image", "deploy"],
    str(pipeline_names),
)
expected_after = {
    "git-clone": ["cleanup"],
    "flake8": ["git-clone"],
    "nose": ["flake8"],
    "build-image": ["nose"],
    "deploy": ["build-image"],
}
for task in pipeline_tasks:
    name = task["name"]
    if name in expected_after:
        check(
            f"pipeline stage {name} runs after {expected_after[name][0]}",
            task.get("runAfter") == expected_after[name],
        )
check(
    "pipeline declares shared-workspace",
    any(ws["name"] == "shared-workspace" for ws in pipeline["spec"]["workspaces"]),
)
check(
    "pipeline declares dockerconfig",
    any(ws["name"] == "dockerconfig" for ws in pipeline["spec"]["workspaces"]),
)

# ------------------------------------------------------------ other YAML
pvc = load_one(".tekton/pvc.yml")
check("PVC is a PersistentVolumeClaim", pvc.get("kind") == "PersistentVolumeClaim")
check("PVC is named pipeline-workspace",
      pvc["metadata"]["name"] == "pipeline-workspace")

run = load_one(".tekton/pipelinerun.yml")
check("PipelineRun references ci-cd-pipeline",
      run["spec"]["pipelineRef"]["name"] == "ci-cd-pipeline")
check("PipelineRun binds both workspaces",
      {ws["name"] for ws in run["spec"]["workspaces"]} ==
      {"shared-workspace", "dockerconfig"})

deployment = load_one("openshift/deployment.yaml")
check("Deployment is an apps/v1 Deployment",
      deployment.get("apiVersion") == "apps/v1" and deployment.get("kind") == "Deployment")
check("Deployment exposes port 8000",
      deployment["spec"]["template"]["spec"]["containers"][0]["ports"][0]["containerPort"] == 8000)
check("Deployment probes /health",
      deployment["spec"]["template"]["spec"]["containers"][0]["readinessProbe"]["httpGet"]["path"] == "/health")

service = load_one("openshift/service.yaml")
check("Service targets port 8000",
      service["spec"]["ports"][0]["targetPort"] == 8000)

route = load_one("openshift/route.yaml")
check("Route points at the counter-service",
      route["spec"]["to"]["name"] == "counter-service")

# ------------------------------------------------------------ result
print()
if failures:
    print(f"{len(failures)} FAILURE(S)")
    for failure in failures:
        print("  -", failure)
    sys.exit(1)
print("ALL CI/CD YAML CHECKS PASSED")
PY
