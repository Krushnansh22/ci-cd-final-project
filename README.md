# Hit Counter Service — CI/CD Final Project

Course: **Continuous Integration and Continuous Delivery (CI/CD)**
(IBM DevOps and Software Engineering, Course 12)
Final project: **CI/CD Tools and Practices**

A small Flask microservice with a complete delivery pipeline:

- **Continuous Integration** with **GitHub Actions** — lint and unit tests on
  every push and pull request.
- **Continuous Delivery/Deployment** with **Tekton on OpenShift** — clone,
  lint, test, build a container image, and deploy the service to a cluster.

This is the completed version of the IBM template
`ibm-developer-skills-network/vselh-ci-cd-final-project-template`.

---

## The application

The service is a **RESTful hit counter**. It keeps counters in memory and
exposes a small JSON API.

| Method | Path | Description | Success |
| --- | --- | --- | --- |
| GET | `/health` | Health check | 200 |
| GET | `/` | Service information | 200 |
| GET | `/counters` | List every counter | 200 |
| POST | `/counters/{name}` | Create a counter at 0 | 201 + `Location` |
| GET | `/counters/{name}` | Read a counter | 200 |
| PUT | `/counters/{name}` | Increment a counter | 200 |
| DELETE | `/counters/{name}` | Delete a counter | 204 |

Errors are returned as JSON: `400`, `404`, `405`, `409`, and `415` all have
handlers in `service/common/error_handlers.py`.

### Example

```bash
curl -X POST http://localhost:8000/counters/demo
# {"counter":0,"name":"demo"}

curl -X PUT http://localhost:8000/counters/demo
# {"counter":1,"name":"demo"}

curl http://localhost:8000/counters
# [{"counter":1,"name":"demo"}]
```

---

## Repository layout

```
.
├── .github/workflows/workflow.yml   # CI: lint + test on every push/PR
├── .tekton/
│   ├── tasks.yml                    # cleanup, flake8, nose Tekton tasks
│   ├── pipeline.yml                 # the six-stage delivery pipeline
│   ├── pvc.yml                      # shared workspace PVC
│   └── pipelinerun.yml              # example run
├── openshift/
│   ├── deployment.yaml              # counter-service Deployment
│   ├── service.yaml                 # ClusterIP Service
│   └── route.yaml                   # public Route
├── service/
│   ├── __init__.py                  # Flask app factory
│   ├── routes.py                    # counter REST API
│   └── common/
│       ├── status.py                # named HTTP status codes
│       ├── log_handlers.py          # gunicorn-compatible logging
│       └── error_handlers.py        # JSON error responses
├── tests/test_routes.py             # unit tests
├── bin/setup.sh                     # lab environment bootstrap
├── scripts/
│   ├── run-ci.sh                    # same checks as GitHub Actions
│   ├── simulate-pipeline.sh         # run the Tekton stages locally
│   ├── validate-ci-cd.sh            # validate all pipeline YAML
│   ├── deploy-openshift.sh          # apply resources and start a run
│   └── smoke-test.sh                # curl a deployed service
├── Dockerfile
├── Procfile
├── requirements.txt
├── setup.cfg
├── Makefile
├── README.md
└── SUBMISSION_GUIDE.md
```

---

## Continuous Integration — GitHub Actions

`.github/workflows/workflow.yml` runs on `push`, `pull_request`, and manual
`workflow_dispatch`.

```
build (ubuntu-latest, container: python:3.9)
  1. Checkout
  2. Install dependencies
  3. Lint with flake8
  4. Run unit tests with nose
  5. Show coverage report
```

The lint step has two passes, matching the IBM lab:

1. A **blocking** pass for real errors (`E9`, `F63`, `F7`, `F82`).
2. A **style** pass with a complexity limit of 10 and a line length of 127.

The test step runs `nosetests` with coverage on the `service` package.

### Run the same checks locally

```bash
pip install -r requirements.txt
bash scripts/run-ci.sh
```

or:

```bash
make lint
make test
```

---

## Continuous Delivery — Tekton on OpenShift

`.tekton/pipeline.yml` defines six stages:

```
cleanup -> git-clone -> flake8 -> nose -> build-image -> deploy
```

| Stage | Task | What it does |
| --- | --- | --- |
| `cleanup` | `cleanup` (this repo) | Empties the shared workspace |
| `git-clone` | `git-clone` (Tekton Hub) | Clones the repository into the workspace |
| `flake8` | `flake8` (this repo) | Lints the source |
| `nose` | `nose` (this repo) | Installs dependencies and runs the unit tests |
| `build-image` | `buildah` (Tekton Hub) | Builds and pushes the container image |
| `deploy` | `openshift-client` (Tekton Hub) | Applies the OpenShift manifests and waits for the rollout |

`cleanup` and `nose` are the two tasks written for the final project;
`flake8` is added so lint failures stop the pipeline before an image is built.

### Why these stages are ordered this way

- **cleanup first** guarantees the workspace never contains files from a
  previous run, which would make the build non-reproducible.
- **lint before test** fails fast: a syntax error is cheaper to report than a
  full test run.
- **test before build** prevents a broken image from ever reaching the
  registry.
- **build before deploy** means the Deployment always references an image that
  exists.
- **deploy last** waits for `oc rollout status`, so the pipeline is only green
  when the new pod is actually serving traffic.

### Pipeline resources

| Resource | Name | Notes |
| --- | --- | --- |
| Pipeline | `ci-cd-pipeline` | `.tekton/pipeline.yml` |
| Tasks | `cleanup`, `flake8`, `nose` | `.tekton/tasks.yml` |
| Hub tasks | `git-clone`, `buildah`, `openshift-client` | installed with `tkn hub` |
| PVC | `pipeline-workspace` | `.tekton/pvc.yml` |
| Secret | `registry-dockerconfig-secret` | registry push credentials |

---

## Local development

### 1. Set up the environment (lab)

```bash
bash bin/setup.sh
exit          # open a new shell so the virtualenv is active
```

### 2. Install dependencies (any machine)

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

### 3. Run the service

```bash
flask run --host 0.0.0.0 --port 8000
```

or:

```bash
honcho start
```

Open <http://localhost:8000/health>.

### 4. Run the tests

```bash
nosetests -v --with-spec --spec-color --with-coverage --cover-package=service
```

### 5. Simulate the pipeline without a cluster

`scripts/simulate-pipeline.sh` runs every stage locally:

```bash
bash scripts/simulate-pipeline.sh
```

It creates a temporary workspace, copies the source into it (the
`git-clone` stage), runs flake8, runs nose, builds the image if Docker is
available, and prints the `oc` commands the deploy stage would run.

Set `SKIP_BUILD=1` to skip the image build.

### 6. Validate the pipeline YAML

```bash
bash scripts/validate-ci-cd.sh
```

This parses every YAML file, checks the GitHub Actions steps, checks the
Tekton task names, and verifies the six pipeline stages and their `runAfter`
order.

---

## Deploying to OpenShift

These are the steps performed in the lab. They assume you are logged in with
`oc` and are in your project namespace.

### 1. Install the Tekton Hub tasks

```bash
tkn hub install task git-clone
tkn hub install task buildah
tkn hub install task openshift-client
```

### 2. Apply the project resources

```bash
oc apply -f .tekton/tasks.yml
oc apply -f .tekton/pipeline.yml
oc apply -f .tekton/pvc.yml
```

### 3. Create the registry secret

For an external registry such as quay.io:

```bash
oc create secret docker-registry registry-dockerconfig-secret \
  --docker-server=quay.io \
  --docker-username="$QUAY_USER" \
  --docker-password="$QUAY_TOKEN" \
  --docker-email="$QUAY_EMAIL"
```

For the OpenShift internal registry, the `pipeline` service account can push
directly. Grant it the image builder role:

```bash
oc policy add-role-to-user system:image-builder \
  "system:serviceaccount:$(oc project -q):pipeline"
```

### 4. Grant deploy permissions

```bash
oc policy add-role-to-user edit \
  "system:serviceaccount:$(oc project -q):pipeline"
```

### 5. Start the pipeline

With the helper script:

```bash
export REPO_URL="https://github.com/$GITHUB_ACCOUNT/ci-cd-final-project.git"
export IMAGE_REFERENCE="image-registry.openshift-image-registry.svc:5000/$(oc project -q)/ci-cd-final-project:latest"
bash scripts/deploy-openshift.sh
```

Or from the OpenShift console: **Pipelines → ci-cd-pipeline → Actions → Start**,
choose the `pipeline-workspace` PVC and the `registry-dockerconfig-secret`, and
fill in the three parameters.

### 6. Verify the deployment

```bash
oc get pods
oc get route counter-service
bash scripts/smoke-test.sh "https://$(oc get route counter-service -o jsonpath='{.spec.host}')"
```

---

## Troubleshooting

| Symptom | Fix |
| --- | --- |
| `flake8: command not found` | `pip install -r requirements.txt` inside the virtualenv. |
| `ModuleNotFoundError: service` | Run commands from the repository root. |
| GitHub Actions fails at checkout | Make sure the workflow has `actions/checkout` before any step that uses the source. |
| `no matches for kind "Task"` | Install the Hub tasks (`git-clone`, `buildah`, `openshift-client`) first. |
| Pipeline stuck in `Pending` | The PVC must be `Bound`; check `oc get pvc`. |
| `buildah` cannot push | Check the `registry-dockerconfig-secret` and the image-builder role. |
| `deploy` fails with `forbidden` | Grant the `pipeline` service account `edit` in the namespace. |
| Pod `ImagePullBackOff` | The image tag in `openshift/deployment.yaml` does not exist, or the registry secret is missing. |
| Route returns 503 | The pod is not ready; check `oc logs deployment/counter-service` and the `/health` probe. |

---

## License

The original lab template is Copyright 2023 IBM Corporation / Skills Network
and is distributed under the Apache License 2.0. This completed version keeps
the same license and attribution.
