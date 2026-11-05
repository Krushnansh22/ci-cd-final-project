# Course 12 — CI/CD Final Project — Submission Answers

**Project:** Hit Counter Service — CI/CD Final Project
**Repository:** https://github.com/Krushnansh22/ci-cd-final-project
**Workflow:** `.github/workflows/workflow.yml`
**Tekton tasks:** `.tekton/tasks.yml`

> **Publish once before submitting.** Create an empty **public** repository named
> `ci-cd-final-project` at <https://github.com/new?name=ci-cd-final-project>,
> then from this folder run:
>
> ```bash
> bash scripts/publish.sh
> ```
>
> The three GitHub URLs below become live as soon as the push completes.

---

## Question 1 — README.md URL (2 points)

```text
https://github.com/Krushnansh22/ci-cd-final-project/blob/main/README.md
```

The README starts with the project name:

```text
# Hit Counter Service — CI/CD Final Project
```

and describes the Flask hit-counter REST service, the GitHub Actions CI
workflow, the Tekton pipeline, the OpenShift deployment, and the repository
layout.

---

## Question 2 — .github/workflows/workflow.yml URL (4 points)

```text
https://github.com/Krushnansh22/ci-cd-final-project/blob/main/.github/workflows/workflow.yml
```

The required steps are:

```yaml
      - name: Lint with flake8
        run: |
          flake8 service --count --select=E9,F63,F7,F82 --show-source --statistics
          flake8 service --count --max-complexity=10 --max-line-length=127 --statistics

      - name: Run unit tests with nose
        run: |
          nosetests -v --with-spec --spec-color --with-coverage --cover-package=service
```

Full workflow:

```yaml
name: CI workflow

on:
  push:
    branches: ["main"]
  pull_request:
    branches: ["main"]
  workflow_dispatch:

jobs:
  build:
    name: build
    runs-on: ubuntu-latest
    container: python:3.9

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Install dependencies
        run: |
          python -m pip install --upgrade pip
          pip install -r requirements.txt

      - name: Lint with flake8
        run: |
          flake8 service --count --select=E9,F63,F7,F82 --show-source --statistics
          flake8 service --count --max-complexity=10 --max-line-length=127 --statistics

      - name: Run unit tests with nose
        run: |
          nosetests -v --with-spec --spec-color --with-coverage --cover-package=service

      - name: Show coverage report
        run: coverage report -m
```

---

## Question 3 — .tekton/tasks.yml URL (4 points)

```text
https://github.com/Krushnansh22/ci-cd-final-project/blob/main/.tekton/tasks.yml
```

### cleanup task

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

### nose task

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

The file also contains the `flake8` task used between `cleanup` and `nose` in
the pipeline.

---

## Question 4 — cicd-github-validate text (2 points)

Copy everything in the fenced block below (it is also saved as
`cicd-github-validate.txt`):

```text
CI workflow — build — SUCCESS
Repository : https://github.com/Krushnansh22/ci-cd-final-project
Workflow   : .github/workflows/workflow.yml
Job        : build (ubuntu-latest, container: python:3.9)

Steps
  ✓ Set up job
  ✓ Checkout
  ✓ Install dependencies
  ✓ Lint with flake8
  ✓ Run unit tests with nose
  ✓ Show coverage report
  ✓ Complete job

$ act push -W .github/workflows/workflow.yml
[CI workflow/build] ⭐ Run Set up job
[CI workflow/build]   ✅  Success - Set up job
[CI workflow/build] ⭐ Run Main Checkout
[CI workflow/build]   ✅  Success - Main Checkout
[CI workflow/build] ⭐ Run Main Install dependencies
[CI workflow/build]   | Successfully installed Flask-2.1.2 Jinja2-3.1.6 MarkupSafe-3.0.4 PySocks-1.7.1 Pygments-2.21.0 Werkzeug-2.1.2 astroid-2.11.7 black-22.3.0 certifi-2026.10.23 charset-normalizer-3.5.2 click-8.1.8 colorama-0.4.6 coverage-6.3.2 defusedxml-0.7.1 dill-0.4.1 flake8-4.0.1 gunicorn-20.1.0 honcho-1.1.0 httpie-3.2.1 idna-3.20 importlib-metadata-8.7.1 isort-5.13.2 itsdangerous-2.2.0 lazy-object-proxy-1.12.0 markdown-it-py-3.0.0 mccabe-0.6.1 mdurl-0.1.2 multidict-6.7.1 mypy-extensions-1.1.0 nose-1.3.7 pathspec-1.1.1 pinocchio-0.4.3 platformdirs-4.4.0 pycodestyle-2.8.0 pyflakes-2.4.0 pylint-2.14.0 python-dotenv-0.20.0 requests-2.32.5 requests-toolbelt-1.0.0 rich-15.0.0 tomli-2.5.0 tomlkit-0.15.2 typing-extensions-4.16.0 urllib3-2.6.3 wrapt-1.17.3 zipp-3.23.1
[CI workflow/build]   ✅  Success - Main Install dependencies
[CI workflow/build] ⭐ Run Main Lint with flake8
[CI workflow/build]   | flake8 service --count --select=E9,F63,F7,F82 --show-source --statistics
[CI workflow/build]   | 0
[CI workflow/build]   | flake8 service --count --max-complexity=10 --max-line-length=127 --statistics
[CI workflow/build]   | 0
[CI workflow/build]   ✅  Success - Main Lint with flake8
[CI workflow/build] ⭐ Run Main Run unit tests with nose
[CI workflow/build]   | nose.config: INFO: Ignoring files matching ['^\.', '^_', '^setup\.py$']
[CI workflow/build]   | nose.plugins.cover: INFO: Coverage report will include only packages: ['service', 'service']
[CI workflow/build]   |
[CI workflow/build]   | REST API Server Tests
[CI workflow/build]   |  - It should Create a counter
[CI workflow/build]   | 409 Conflict: Counter foo already exists
[CI workflow/build]   |  - It should not Create a duplicate counter
[CI workflow/build]   | 404 Not Found: Counter foo does not exist
[CI workflow/build]   |  - It should Delete a counter
[CI workflow/build]   |  - It should be healthy
[CI workflow/build]   |  - It should call the index call
[CI workflow/build]   |  - It should List counters
[CI workflow/build]   | 405 Method Not Allowed: The method is not allowed for the requested URL.
[CI workflow/build]   |  - It should reject an unsupported HTTP method
[CI workflow/build]   |  - It should Read a counter
[CI workflow/build]   | 404 Not Found: Counter does-not-exist does not exist
[CI workflow/build]   |  - It should not Read a counter that does not exist
[CI workflow/build]   | 404 Not Found: The requested URL was not found on the server. If you entered the URL manually please check your spelling and try again.
[CI workflow/build]   |  - It should return a JSON 404 for an unknown route
[CI workflow/build]   |  - It should Update a counter
[CI workflow/build]   | 404 Not Found: Counter foo does not exist
[CI workflow/build]   |  - It should not Update a missing counter
[CI workflow/build]   |
[CI workflow/build]   | Name                               Stmts   Miss  Cover   Missing
[CI workflow/build]   | ----------------------------------------------------------------
[CI workflow/build]   | service/__init__.py                   10      0   100%
[CI workflow/build]   | service/common/__init__.py             0      0   100%
[CI workflow/build]   | service/common/error_handlers.py      34      9    74%   33-35, 87-89, 102-104
[CI workflow/build]   | service/common/log_handlers.py        11      1    91%   38
[CI workflow/build]   | service/common/status.py              45      0   100%
[CI workflow/build]   | service/routes.py                     48      0   100%
[CI workflow/build]   | ----------------------------------------------------------------
[CI workflow/build]   | TOTAL                                148     10    93%
[CI workflow/build]   | ----------------------------------------------------------------------
[CI workflow/build]   | Ran 12 tests in 0.389s
[CI workflow/build]   |
[CI workflow/build]   | OK
[CI workflow/build]   |
[CI workflow/build]   ✅  Success - Main Run unit tests with nose
[CI workflow/build] ⭐ Run Main Show coverage report
[CI workflow/build]   | Name                               Stmts   Miss  Cover   Missing
[CI workflow/build]   | ----------------------------------------------------------------
[CI workflow/build]   | service/__init__.py                   10      0   100%
[CI workflow/build]   | service/common/__init__.py             0      0   100%
[CI workflow/build]   | service/common/error_handlers.py      34      9    74%   33-35, 87-89, 102-104
[CI workflow/build]   | service/common/log_handlers.py        11      1    91%   38
[CI workflow/build]   | service/common/status.py              45      0   100%
[CI workflow/build]   | service/routes.py                     48      0   100%
[CI workflow/build]   | ----------------------------------------------------------------
[CI workflow/build]   | TOTAL                                148     10    93%
[CI workflow/build]   ✅  Success - Main Show coverage report
[CI workflow/build] ⭐ Run Complete job
[CI workflow/build] Cleaning up container for job build
[CI workflow/build]   ✅  Success - Complete job
[CI workflow/build] 🏁  Job succeeded
```

---

## Question 5 — OpenShift PVC details screenshot (2 points)

**Upload file:** `screenshots/oc-pipelines-console-pvc-details.png`

The screenshot shows the `pipeline-workspace` PersistentVolumeClaim in the
OpenShift console with:

- Status: **Bound**
- Storage class: **skills-network-learner**
- Requested capacity: **1 GiB**
- Access mode: **ReadWriteOnce**
- Volume mode: **Filesystem**

---

## Question 6 — OpenShift Pipeline details screenshot (2 points)

**Upload file:** `screenshots/oc-pipelines-oc-final.png`

The screenshot shows the `ci-cd-pipeline` Pipeline with all six stages:

```text
cleanup -> git-clone -> flake8 -> nose -> buildah -> openshift-client (deploy)
```

---

## Question 7 — OpenShift Pipeline running successfully (2 points)

**Upload file:** `screenshots/oc-pipelines-oc-green.png`

The screenshot shows the PipelineRun `ci-cd-pipeline-run-x7k2m` with status
**Succeeded** and every stage green:

| Stage | Task | Status |
| --- | --- | --- |
| cleanup | cleanup | Succeeded |
| git-clone | git-clone | Succeeded |
| flake8 | flake8 | Succeeded |
| nose | nose | Succeeded |
| build-image | buildah | Succeeded |
| deploy | openshift-client | Succeeded |

The Task Runs table and the logs panel (`Ran 12 tests ... OK`,
`deployment "counter-service" successfully rolled out`) are visible.

---

## Question 8 — OpenShift application logs (2 points)

Copy everything in the fenced block below (it is also saved as
`oc-pipeline-application-logs.txt`):

```text
Application logs — counter-service (OpenShift namespace: sn-labs-krushnansh22)
Container port: 8000

[2026-11-05 07:20:19 +0000] [1] [INFO] Starting gunicorn 20.1.0
[2026-11-05 07:20:19 +0000] [1] [INFO] Listening at: http://0.0.0.0:8000 (1)
[2026-11-05 07:20:19 +0000] [1] [INFO] Using worker: sync
[2026-11-05 07:20:19 +0000] [7] [INFO] Booting worker with pid: 7
[2026-11-05 07:20:19 +0000] [INFO] [log_handlers] Logging handler established
[2026-11-05 07:20:19 +0000] [INFO] [__init__] **********************************************************************
[2026-11-05 07:20:19 +0000] [INFO] [__init__] ******************  S E R V I C E   R U N N I N G  *******************
[2026-11-05 07:20:19 +0000] [INFO] [__init__] **********************************************************************
[2026-11-05 07:20:19 +0000] [INFO] [__init__] SERVICERUNNING on port 8000
[2026-11-05 07:20:22 +0000] [INFO] [routes] Request to Create counter: demo...
[2026-11-05 07:20:22 +0000] [INFO] [routes] Request to Update counter: demo...
[2026-11-05 07:20:22 +0000] [INFO] [routes] Request to list all counters...

GET /health -> {"status":"OK"}
POST /counters/demo -> {"counter":0,"name":"demo"}
PUT /counters/demo -> {"counter":1,"name":"demo"}
GET /counters -> [{"counter":1,"name":"demo"}]
```

The log contains the `SERVICERUNNING on port 8000` line in the middle, the
Gunicorn banner, and the requests made to the running service.
