# Tekton Pipelines

This directory holds the Tekton resources for the final project.

| File | Purpose |
| --- | --- |
| `tasks.yml` | The `cleanup`, `flake8`, and `nose` tasks written for the project |
| `pipeline.yml` | The full six-stage pipeline (cleanup → clone → lint → test → build → deploy) |
| `pvc.yml` | The `pipeline-workspace` PersistentVolumeClaim |
| `pipelinerun.yml` | An example run; edit the repository and image values first |

The `git-clone`, `buildah`, and `openshift-client` tasks are installed from
Tekton Hub rather than committed here:

```bash
tkn hub install task git-clone
tkn hub install task buildah
tkn hub install task openshift-client
```

Apply everything:

```bash
oc apply -f .tekton/tasks.yml
oc apply -f .tekton/pipeline.yml
oc apply -f .tekton/pvc.yml
```

Then start a run from the OpenShift console (**Pipelines → ci-cd-pipeline →
Actions → Start**) or with `tkn`:

```bash
tkn pipeline start ci-cd-pipeline --showlog \
  --workspace name=shared-workspace,claimName=pipeline-workspace \
  --workspace name=dockerconfig,secret=registry-dockerconfig-secret \
  --param repo-url=https://github.com/YOUR_ACCOUNT/ci-cd-final-project.git \
  --param image-reference=image-registry.openshift-image-registry.svc:5000/$(oc project -q)/ci-cd-final-project:latest
```
