# Course 12 — Peer Review Submission Answers

## Project Title

**Hit Counter Service — Automated CI/CD Pipeline with GitHub Actions and Tekton on OpenShift**

A Flask REST microservice that is linted and tested by GitHub Actions on every
push, then cloned, linted, tested, built with Buildah, and deployed to
OpenShift by a six-stage Tekton pipeline.

---

## Task 1 — Repository URL (2 pts)

```text
https://github.com/Krushnansh22/ci-cd-final-project
```

---

## Task 2 — workflow.yml: Lint with flake8 (2 pts)

```text
https://github.com/Krushnansh22/ci-cd-final-project/blob/main/.github/workflows/workflow.yml#L27-L30
```

Plain file URL:

```text
https://github.com/Krushnansh22/ci-cd-final-project/blob/main/.github/workflows/workflow.yml
```

Snippet:

```yaml
      - name: Lint with flake8
        run: |
          flake8 service --count --select=E9,F63,F7,F82 --show-source --statistics
          flake8 service --count --max-complexity=10 --max-line-length=127 --statistics
```

---

## Task 3 — workflow.yml: Run unit tests with nose (2 pts)

```text
https://github.com/Krushnansh22/ci-cd-final-project/blob/main/.github/workflows/workflow.yml#L32-L34
```

Plain file URL:

```text
https://github.com/Krushnansh22/ci-cd-final-project/blob/main/.github/workflows/workflow.yml
```

Snippet:

```yaml
      - name: Run unit tests with nose
        run: |
          nosetests -v --with-spec --spec-color --with-coverage --cover-package=service
```

---

## Task 4 — tasks.yml: cleanup task (2 pts)

```text
https://github.com/Krushnansh22/ci-cd-final-project/blob/main/.tekton/tasks.yml#L9-L42
```

Plain file URL:

```text
https://github.com/Krushnansh22/ci-cd-final-project/blob/main/.tekton/tasks.yml
```

Snippet:

```yaml
apiVersion: tekton.dev/v1beta1
kind: Task
metadata:
  name: cleanup
spec:
  description: This task will clean up a workspace by deleting all the files.
  workspaces:
    - name: source
  steps:
    - name: remove
      image: alpine:3
      env:
        - name: WORKSPACE_SOURCE_PATH
          value: $(workspaces.source.path)
      workingDir: $(workspaces.source.path)
      securityContext:
        runAsNonRoot: false
        runAsUser: 0
      script: |
        #!/usr/bin/env sh
        set -eu
        echo "Removing all files from ${WORKSPACE_SOURCE_PATH} ..."
        if [ -d "${WORKSPACE_SOURCE_PATH}" ] ; then
          rm -rf "${WORKSPACE_SOURCE_PATH:?}"/*
          rm -rf "${WORKSPACE_SOURCE_PATH}"/.[!.]*
          rm -rf "${WORKSPACE_SOURCE_PATH}"/..?*
        fi
```

---

## Task 5 — tasks.yml: nose task (2 pts)

```text
https://github.com/Krushnansh22/ci-cd-final-project/blob/main/.tekton/tasks.yml#L68-L90
```

Plain file URL:

```text
https://github.com/Krushnansh22/ci-cd-final-project/blob/main/.tekton/tasks.yml
```

Snippet:

```yaml
apiVersion: tekton.dev/v1beta1
kind: Task
metadata:
  name: nose
spec:
  description: This task runs the unit tests with the nose framework.
  workspaces:
    - name: source
  params:
    - name: args
      description: Arguments to pass to nose
      type: string
      default: "-v"
  steps:
    - name: nosetests
      image: python:3.9-slim
      workingDir: $(workspaces.source.path)
      script: |
        #!/bin/bash
        set -e
        python -m pip install --upgrade pip wheel
        pip install -r requirements.txt
        nosetests $(params.args)
```

---

## Task 6 — PVC details screenshot (2 pts)

**Upload file:** `screenshots/oc-pipelines-console-pvc-details.png`

Shows the `pipeline-workspace` PVC with:

- Status: **Bound**
- Storage class: **skills-network-learner**
- Requested capacity: **1 GiB**
- Access mode: **ReadWriteOnce**

---

## Task 7 — GitHub Actions running successfully (2 pts)

**Upload file:** `screenshots/cicd-github-validate.png`

Real GitHub Actions job page for:

```text
https://github.com/Krushnansh22/ci-cd-final-project/actions/runs/41989547014
```

It shows the `build` job **succeeded in 34s**, with every step green:

```text
Set up job
Initialize containers
Checkout
Install dependencies
Lint with flake8
Run unit tests with nose
Show coverage report
Post Checkout
Stop containers
Complete job
```

---

## Task 8 — OpenShift Pipeline details (2 pts)

**Upload file:** `screenshots/oc-pipelines-oc-final.png`

Shows the `ci-cd-pipeline` with all six stages:

```text
cleanup -> git-clone -> flake8 -> nose -> buildah -> openshift-client (deploy)
```

---

## Task 9 — OpenShift Pipeline running successfully (2 pts)

**Upload file:** `screenshots/oc-pipelines-oc-green.png`

Shows PipelineRun `ci-cd-pipeline-run-x7k2m` with status **Succeeded** and every
TaskRun green:

```text
cleanup, git-clone, flake8, nose, buildah, openshift-client (deploy)
```

---

## Task 10 — OpenShift application logs (2 pts)

**Upload file:** `screenshots/oc-pipelines-app-logs.png`

Shows the terminal output of:

```bash
oc get pods
oc logs deployment/counter-service
```

with the Gunicorn startup banner, the line:

```text
SERVICERUNNING on port 8000
```

and the requests served by the application.

---

## File summary

| Task | File |
| --- | --- |
| 6 | `screenshots/oc-pipelines-console-pvc-details.png` |
| 7 | `screenshots/cicd-github-validate.png` |
| 8 | `screenshots/oc-pipelines-oc-final.png` |
| 9 | `screenshots/oc-pipelines-oc-green.png` |
| 10 | `screenshots/oc-pipelines-app-logs.png` |
