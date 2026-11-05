# AI-Graded Submission Guide — Hit Counter Service (CI/CD)

Course: **Continuous Integration and Continuous Delivery (CI/CD)**
Final assignment: **CI/CD Tools and Practices — Final Project**
Submission type: **AI-graded screenshots + repository link + short answers**

This guide takes you from the lab terminal to a submitted final project:
a Flask **Hit Counter Service**, a **GitHub Actions** CI workflow, and a
**Tekton pipeline on OpenShift** that clones, lints, tests, builds, and deploys
the service. Every task lists the command, the output to look for, and the
screenshot to capture.

---

## 1. What the project asks for

You are the developer of a small REST service. Two deliverables are graded:

1. **Continuous Integration** — a GitHub Actions workflow in
   `.github/workflows/workflow.yml` that lints the code and runs the unit tests
   on every push.
2. **Continuous Delivery** — Tekton tasks in `.tekton/tasks.yml` (at minimum
   `cleanup` and `nose`) and a pipeline built in the OpenShift console:
   `cleanup → git-clone → flake8 → nose → buildah → openshift-client`.

The graded evidence is:

- a screenshot of the **GitHub Actions run** with all steps green,
- a screenshot of the **Tekton pipeline graph** in the OpenShift console,
- a screenshot of the **PipelineRun logs** (tests passing),
- a screenshot of the **deployed service** answering on its Route,
- the GitHub repository URL,
- short written answers about CI/CD.

The completed implementation is already in this folder. If you are working in
the IBM lab, copy these files into your clone of
`ibm-developer-skills-network/vselh-ci-cd-final-project-template` (or use this
folder directly). The repository is expected to be named
`ci-cd-final-project`.

---

## 2. Before you start

Open the Skills Network lab terminal and confirm the tools:

```bash
python3 --version
git --version
oc version
tkn version
```

In the lab, `oc` is already logged in to your OpenShift project
(`sn-labs-<username>`). Confirm it:

```bash
oc whoami
oc project -q
```

Set up the environment:

```bash
cd "Continuous Integration and Continuous Delivery (CI-CD)"
bash bin/setup.sh
exit          # open a new shell so the virtualenv is active
```

Then, in the new shell:

```bash
cd "Continuous Integration and Continuous Delivery (CI-CD)"
python3 --version
python -c "from service import app; print(app.name)"
```

Expected:

```
Python 3.9.x
service
```

**Screenshot 1 — environment ready.** Capture the terminal showing the
`setup.sh` finishing and the `python -c` output.

> If you are not in the lab, `python3 -m venv .venv && source .venv/bin/activate
> && pip install -r requirements.txt` is enough. The pins in `requirements.txt`
> are the ones the IBM template uses.

---

## 3. Task 1 — Understand the starting point

The template ships with:

- `service/__init__.py` — the Flask app,
- `service/routes.py` — the counter REST API,
- `service/common/` — status codes, logging, and JSON error handlers,
- `tests/test_routes.py` — the unit tests,
- empty `.github/workflows/workflow.yml` and `.tekton/tasks.yml` for you to fill in.

In this completed version every file is implemented. Read them in this order so
you can explain them:

1. `service/routes.py` — `GET /health`, `GET /`, `GET/POST /counters`, and
   `GET/PUT/DELETE /counters/<name>`.
2. `service/common/error_handlers.py` — turns `404`, `405`, and `409` into JSON.
3. `tests/test_routes.py` — 12 tests covering the full HTTP contract.
4. `.github/workflows/workflow.yml` — the CI job.
5. `.tekton/tasks.yml` — the `cleanup`, `flake8`, and `nose` tasks.
6. `.tekton/pipeline.yml` — the same pipeline you build in the UI, as YAML.

**What to say if asked:** the routes own HTTP semantics, the tests describe the
contract, the GitHub workflow enforces the contract on every push, and the
Tekton pipeline turns a passing commit into a running container.

---

## 4. Task 2 — Complete the GitHub Actions workflow

`.github/workflows/workflow.yml` must contain four things, in order:

1. **Checkout** — `actions/checkout` must run before anything reads the source.
2. **Install dependencies** — `pip install -r requirements.txt`.
3. **Lint with flake8** — two passes: a blocking one for real errors
   (`E9,F63,F7,F82`) and a style one (`--max-complexity=10
   --max-line-length=127`).
4. **Run unit tests with nose** — `nosetests` with coverage.

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

Two details that matter:

- `--cover-package=service`, **not** `app`. The package in this project is
  `service`, so covering `app` produces an empty report.
- `container: python:3.9` runs the job in the lab's Python version. Use the
  full image (not `-slim`) so that `actions/checkout` has `git` available.

Run the same checks locally before pushing:

```bash
bash scripts/run-ci.sh
```

Expected: flake8 prints no findings and nose ends with `OK`.

**Screenshot 2 — local lint + tests passing.**

---

## 5. Task 3 — Push and watch the workflow

Create a repository from the IBM template (**Use this template**), copy this
project into it, and push:

```bash
git add .
git commit -m "Add CI workflow and Tekton pipeline"
git push origin main
```

Open **Actions → CI workflow → build**. Every step must be green:

```
✓ Set up job
✓ Initialize containers
✓ Checkout
✓ Install dependencies
✓ Lint with flake8
✓ Run unit tests with nose
✓ Show coverage report
✓ Complete job
```

To prove the workflow really gates the code, you can also start it by hand
(**Run workflow**, enabled by `workflow_dispatch`).

**Screenshot 3 — GitHub Actions run, all steps green.** Make sure the job name
`build` and the step names are readable.

---

## 6. Task 4 — Write the Tekton tasks

`.tekton/tasks.yml` defines the tasks the pipeline uses. Two are required by the
assignment; the third (`flake8`) is the lint stage that runs between them.

### `cleanup`

Empties the shared workspace so every run starts from a clean checkout:

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

The `${VAR:?}` form makes the script abort if the variable is empty, so it can
never run `rm -rf /`.

### `flake8`

```yaml
apiVersion: tekton.dev/v1beta1
kind: Task
metadata:
  name: flake8
spec:
  description: This task lints the Python source with flake8.
  workspaces:
    - name: source
  params:
    - name: args
      type: string
      default: "--count --max-complexity=10 --max-line-length=127 --statistics"
  steps:
    - name: flake8
      image: python:3.9-slim
      workingDir: $(workspaces.source.path)
      script: |
        #!/bin/bash
        set -e
        python -m pip install --upgrade pip wheel
        pip install flake8
        flake8 service $(params.args)
```

### `nose`

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

Each task declares a `source` workspace and receives its path through
`$(workspaces.source.path)`. That is what lets the pipeline mount the same PVC
into every stage.

Validate the YAML locally:

```bash
bash scripts/validate-ci-cd.sh
```

Expected last line:

```
ALL CI/CD YAML CHECKS PASSED
```

**Screenshot 4 — the task YAML and the validator passing.**

---

## 7. Task 5 — Install the Hub tasks and apply the project tasks

Three stages reuse community tasks instead of hand-written ones:

```bash
tkn hub install task git-clone
tkn hub install task buildah
tkn hub install task openshift-client
```

Then apply your own tasks and the pipeline:

```bash
oc apply -f .tekton/tasks.yml
oc apply -f .tekton/pipeline.yml
oc apply -f .tekton/pvc.yml
```

Check them:

```bash
oc get tasks
oc get pipeline
oc get pvc pipeline-workspace
```

Expected: `cleanup`, `flake8`, `nose`, `git-clone`, `buildah`, and
`openshift-client` in the task list; `ci-cd-pipeline` in the pipeline list; and
the PVC `Bound`.

**Screenshot 5 — `oc get tasks` and `oc get pipeline`.**

---

## 8. Task 6 — Create the workspace, secret, and permissions

### Persistent volume

```bash
oc get pvc pipeline-workspace
```

If it does not exist:

```bash
oc apply -f .tekton/pvc.yml
```

### Registry credentials

For the OpenShift internal registry, the `pipeline` service account can push
once it has the image-builder role:

```bash
oc policy add-role-to-user system:image-builder \
  "system:serviceaccount:$(oc project -q):pipeline"
```

For an external registry such as quay.io, create the secret the pipeline
expects:

```bash
oc create secret docker-registry registry-dockerconfig-secret \
  --docker-server=quay.io \
  --docker-username="$QUAY_USER" \
  --docker-password="$QUAY_TOKEN" \
  --docker-email="$QUAY_EMAIL"
```

### Deploy permissions

```bash
oc policy add-role-to-user edit \
  "system:serviceaccount:$(oc project -q):pipeline"
```

Without `edit`, the final `openshift-client` stage fails with `forbidden` when
it tries to apply the Deployment.

**Screenshot 6 — PVC `Bound` and the role bindings.**

---

## 9. Task 7 — Build the pipeline in the OpenShift console

This is the part the grader looks at most closely. Open
**Pipelines → Create → Pipeline** and add the stages in this order:

| # | Stage name | Task | Workspace |
| --- | --- | --- | --- |
| 1 | `cleanup` | `cleanup` | `shared-workspace` |
| 2 | `git-clone` | `git-clone` | `shared-workspace` |
| 3 | `flake8` | `flake8` | `shared-workspace` |
| 4 | `nose` | `nose` | `shared-workspace` |
| 5 | `buildah` | `buildah` | `shared-workspace` + `dockerconfig` |
| 6 | `openshift-client` | `openshift-client` | `shared-workspace` |

Name the pipeline `ci-cd-pipeline`. The stages must be sequential — each one
`runAfter` the previous — so a failure stops the pipeline before an image is
pushed.

Stage parameters:

- **git-clone** — `url` = your repository, `revision` = `main`,
  `deleteExisting` = `true`.
- **flake8** — `args` =
  `--count --max-complexity=10 --max-line-length=127 --statistics`.
- **nose** — `args` =
  `-v --with-spec --spec-color --with-coverage --cover-package=service`.
- **buildah** — `IMAGE` = your image reference, `DOCKERFILE` = `./Dockerfile`,
  `CONTEXT` = `.`, `TLSVERIFY` = `false`, `FORMAT` = `docker`.
- **openshift-client** — `SCRIPT`:

  ```bash
  set -e
  echo "Deploying <image> ..."
  sed -i "s|IMAGE_PLACEHOLDER|<image>|g" openshift/deployment.yaml
  oc apply -f openshift/service.yaml
  oc apply -f openshift/deployment.yaml
  oc apply -f openshift/route.yaml
  oc rollout status deployment/counter-service --timeout=180s
  ```

The `sed` is what replaces `IMAGE_PLACEHOLDER` in `openshift/deployment.yaml`
with the image the pipeline just built.

**Screenshot 7 — the pipeline graph with all six stages.** The console shows
them left to right, each connected to the next.

> `.tekton/pipeline.yml` already contains this pipeline as YAML. Applying it is
> equivalent to building it in the UI; use whichever the lab asks for, but
> capture the graph either way.

---

## 10. Task 8 — Start the pipeline

From the console: **Pipelines → ci-cd-pipeline → Actions → Start**, choose:

- workspace `shared-workspace` → PVC `pipeline-workspace`,
- workspace `dockerconfig` → secret `registry-dockerconfig-secret`,
- `repo-url` → `https://github.com/<you>/ci-cd-final-project.git`,
- `revision` → `main`,
- `image-reference` →
  `image-registry.openshift-image-registry.svc:5000/<project>/ci-cd-final-project:latest`.

Or from the terminal:

```bash
export REPO_URL="https://github.com/$GITHUB_ACCOUNT/ci-cd-final-project.git"
export IMAGE_REFERENCE="image-registry.openshift-image-registry.svc:5000/$(oc project -q)/ci-cd-final-project:latest"
bash scripts/deploy-openshift.sh
```

Watch the run:

```bash
tkn pipelinerun list
tkn pipelinerun logs -f --last
```

Expected, in order:

```
[cleanup]        Removing all files from /workspace/source ...
[git-clone]      Cloning into '/workspace/source'...
[flake8]         (no output — clean)
[nose]           test_create_counters ... ok
                 test_health ... ok
                 ...
                 Ran 12 tests in ...s
                 OK
[build-image]    Successfully tagged .../ci-cd-final-project:latest
[deploy]         deployment "counter-service" successfully rolled out
```

**Screenshot 8 — the PipelineRun with all six stages succeeded, and the nose
output showing `OK`.**

If a stage fails, the logs of that stage say why — see the troubleshooting
table.

---

## 11. Task 9 — Verify the deployment

```bash
oc get pods
oc get svc counter-service
oc get route counter-service
```

Then exercise the running service through its Route:

```bash
ROUTE="https://$(oc get route counter-service -o jsonpath='{.spec.host}')"
bash scripts/smoke-test.sh "$ROUTE"
```

Or by hand:

```bash
curl -s "$ROUTE/health"
# {"status":"OK"}

curl -s -X POST "$ROUTE/counters/demo"
# {"counter":0,"name":"demo"}

curl -s -X PUT "$ROUTE/counters/demo"
# {"counter":1,"name":"demo"}

curl -s "$ROUTE/counters"
# [{"counter":1,"name":"demo"}]
```

The pod listens on **8000**; the Service maps port 80 to 8000 and the Route
publishes it over HTTPS.

**Screenshot 9 — the Route URL and the JSON responses.** A browser tab on
`<route>/` showing the service information is also good evidence.

---

## 12. Task 10 — Simulate the pipeline without a cluster (optional)

If the cluster is slow or you want to rehearse, run the same six stages
locally:

```bash
bash scripts/simulate-pipeline.sh
```

It creates a temporary workspace, copies the source into it, runs flake8,
runs nose (or `unittest` when nose is missing), builds the image if Docker is
available, and prints the `oc` commands the deploy stage would run. Set
`SKIP_BUILD=1` to skip the image build.

**Screenshot 10 — the simulated pipeline finishing.**

---

## 13. Submit

Before you submit, confirm:

- [ ] `.github/workflows/workflow.yml` has Checkout → Install → flake8 → nose.
- [ ] The GitHub Actions run is green (Screenshot 3).
- [ ] `.tekton/tasks.yml` defines `cleanup`, `flake8`, and `nose`.
- [ ] `bash scripts/validate-ci-cd.sh` prints `ALL CI/CD YAML CHECKS PASSED`.
- [ ] The OpenShift pipeline shows all six stages (Screenshot 7).
- [ ] The PipelineRun succeeded and the nose stage printed `OK`.
- [ ] The Deployment rolled out and the Route answers `/health`.
- [ ] The repository is pushed to GitHub.
- [ ] `README.md` explains how to install, run, test, and deploy.
- [ ] Screenshots 1–9 are uploaded.

### Repository contents checklist

```
.github/workflows/workflow.yml   CI: lint + test on every push/PR
.tekton/tasks.yml                cleanup, flake8, nose
.tekton/pipeline.yml             six-stage pipeline
.tekton/pvc.yml                  pipeline-workspace
.tekton/pipelinerun.yml          example run
openshift/deployment.yaml        counter-service Deployment (port 8000)
openshift/service.yaml           Service (80 -> 8000)
openshift/route.yaml             public Route
service/                         app, routes, common utilities
tests/                           route tests
requirements.txt
setup.cfg
Makefile
Dockerfile
Procfile
.flaskenv
README.md
SUBMISSION_GUIDE.md
```

---

## 14. Ready-to-paste answers

**What is Continuous Integration?**
> CI is the practice of merging every developer's work into a shared branch
> several times a day and automatically building and testing each change. Here,
> GitHub Actions checks out the code, lints it with flake8, and runs the nose
> suite on every push and pull request, so a broken commit is caught in minutes
> instead of at release time.

**What is Continuous Delivery?**
> Continuous Delivery keeps the main branch in a state that is always ready to
> deploy. Every change that passes CI is automatically built into a container
> image and pushed to a registry; releasing it is a one-click decision. In this
> project the Tekton pipeline does that with the `buildah` stage.

**What is Continuous Deployment, and how is it different?**
> Continuous Deployment goes one step further: every change that passes the
> pipeline is deployed to production with no human approval. This project is
> closer to Continuous Deployment because the `openshift-client` stage applies
> the manifests and waits for `oc rollout status` automatically.

**Why does `cleanup` run first?**
> The workspace is a persistent volume reused by every run. If old files
> survive, `git clone` can fail or the build can pick up stale source. Clearing
> the workspace first makes every run reproducible.

**Why lint before test?**
> Lint failures are cheap and fast to detect. Running flake8 before nose means
> a syntax error or undefined name is reported in seconds, before spending time
> installing dependencies and running the whole suite.

**Why test before build?**
> Building and pushing an image is the expensive, externally visible step. If
> the tests fail, the pipeline stops before a broken image reaches the registry
> or the cluster.

**What does the `nose` Tekton task do?**
> It mounts the shared workspace, installs `requirements.txt` in a
> `python:3.9-slim` container, and runs `nosetests` from the workspace root.
> Because the task receives `$(workspaces.source.path)`, it does not care where
> the volume is mounted.

**What is a Tekton `Task` versus a `Pipeline`?**
> A `Task` is a sequence of steps that run in one pod, such as "run nose". A
> `Pipeline` is a directed graph of tasks with workspaces and parameters; here
> it wires cleanup → git-clone → flake8 → nose → buildah → openshift-client.

**What is a `PipelineRun`?**
> It is one execution of a Pipeline. It supplies the parameter values and binds
> the workspaces (the PVC and the registry secret) for that run.

**Why use a `PersistentVolumeClaim` as the workspace?**
> Tekton tasks run in separate pods, so they cannot share a local directory.
> A PVC gives every stage the same files: the clone writes the source, flake8
> and nose read it, and buildah builds from it.

**What does `sed -i "s|IMAGE_PLACEHOLDER|...|g"` do?**
> `openshift/deployment.yaml` is committed with a placeholder image so the
> repository is not tied to one registry. The deploy stage substitutes the
> image that `buildah` just pushed, then applies the manifest, so the
> Deployment always references the exact build under test.

**What does `oc rollout status` add?**
> It blocks until the new pod is running and ready. Without it the pipeline
> would report success as soon as the manifests were applied, even if the
> container crashed on startup.

**Why does the pipeline service account need `edit` and `system:image-builder`?**
> `system:image-builder` lets it push to the internal registry, and `edit` lets
> it create and update Deployments, Services, and Routes in the namespace.

---

## 15. Troubleshooting

| Symptom | Fix |
| --- | --- |
| `ModuleNotFoundError: service` | Run from the project root with the venv active. |
| GitHub Actions: `flake8: command not found` | The "Install dependencies" step must run before the lint step. |
| GitHub Actions: coverage report is empty | Use `--cover-package=service`, not `app`. |
| `no matches for kind "Task"` | Install the Hub tasks (`git-clone`, `buildah`, `openshift-client`) first. |
| Pipeline stuck in `Pending` | The PVC must be `Bound`; check `oc get pvc`. |
| `cleanup` fails with permission denied | The task must run as `runAsUser: 0` to delete files owned by other stages. |
| `buildah` cannot push | Check `registry-dockerconfig-secret` and the image-builder role. |
| `deploy` fails with `forbidden` | Grant the `pipeline` service account `edit` in the namespace. |
| `sed: can't read openshift/deployment.yaml` | The workspace is empty — `git-clone` ran after `cleanup` but did not finish, or the wrong branch was requested. |
| Pod `ImagePullBackOff` | The image tag does not exist, or the registry secret is missing. |
| Route returns 503 | The pod is not ready; check `oc logs deployment/counter-service` and the `/health` probe on port 8000. |
| Tests pass locally but fail in the pipeline | The pipeline installs `requirements.txt` fresh; check for a missing dependency or a file that is gitignored. |
