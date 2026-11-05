# GitHub Actions Workflows

This directory holds the Continuous Integration workflow for the final project.

`workflow.yml` runs on every push and pull request to `main`:

1. checks out the repository,
2. installs `requirements.txt` inside a `python:3.9` container,
3. lints the `service` package with `flake8`,
4. runs the unit tests with `nose`,
5. prints the coverage report.

The workflow can also be started by hand from the **Actions** tab
(`workflow_dispatch`).
