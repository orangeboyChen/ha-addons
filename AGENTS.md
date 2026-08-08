# Project Guide

## Overview

This repository contains private Home Assistant Apps (formerly called add-ons).
Each app is a Home Assistant wrapper around a multi-architecture Docker image or
an app-specific Docker build. The repository currently provides `ddns-go`, which
publishes a derived image based on upstream `ghcr.io/jeessy2/ddns-go` and
exposes its web interface through Home Assistant Ingress.

Keep this repository focused on Home Assistant packaging and repository
automation. Do not copy upstream application source code into this repository
unless an app explicitly requires a local build.

## Repository Structure

```text
addons.json                         Root app registry and upstream repositories
<addon>/config.yaml                 Home Assistant app metadata
.github/workflows/update-ddns-go.yml Scheduled upstream version updater
README.md                           English repository index
README.zh-CN.md                     Chinese translation of the repository index
LICENSE                             MIT license for this repository
```

The root `addons.json` is the single registry for automated updates. It contains
one entry per app with its relative `path` and upstream GitHub `repository`.
The current app version is stored only in that app's `config.yaml`; do not
duplicate it in `addons.json` or in a second per-app version file.

## Adding an App

1. Create a directory at the repository root named after the app slug.
2. Add a valid Home Assistant `config.yaml` in that directory. For a remote
   Docker image, set `image` to the target add-on image and set `version` to
   the exact Docker tag.
3. Declare supported architectures, ports, startup behavior, persistence,
   Ingress, and security settings in `config.yaml`. Only add `options` and
   `schema` when the container actually consumes `/data/options.json`.
4. Register the app in `addons.json`:

   ```json
   {
     "path": "example-app",
     "release_repository": "owner/example-app"
   }
   ```

5. Add app-specific documentation, translations, icons, or an AppArmor profile
   only when they are needed by the app. Do not add unrelated root README prose;
   the root `Add-ons` section is an index of links.
6. Validate the metadata and test the app locally before opening a pull request.

For a derived app image, add the required Dockerfile and ensure its runtime
command persists state under Home Assistant's always-writable `/data` path.
Keep the final runtime-stage `FROM` image tied to the app's upstream image tag;
the updater uses that image to find releases. Derived images must accept the
`UPSTREAM_IMAGE_TAG` build argument for the upstream Docker image tag and the
`UPSTREAM_RELEASE_TAG` build argument for the source checkout. These values can
differ. The published `ha-addons-*` tag and `config.yaml` version are the
upstream image tag without a leading `v`.
Do not assume that Home Assistant options are automatically passed as command
line flags or environment variables; wire them into the image explicitly.

## Upstream Update Action

`.github/workflows/update-ddns-go.yml` runs every 30 minutes and can also be
started manually. It reads every entry from the root `addons.json`, queries that
entry's GitHub `releases/latest` endpoint, reads the image repository from the
app's Dockerfile (or `config.yaml` when no Dockerfile exists), tries the release
tag and its common `v`-prefix variant in the implied registry, reads the current version from the
app's `config.yaml`, and updates only that app when the upstream image tag
changes. It removes a leading `v` only for the published add-on image tag and
`config.yaml` version; the upstream `FROM` retains its exact tag. Missing target
images are built as well. The build matrix is expanded
from each app's `config.yaml` `arch` list: `amd64` runs on native
`ubuntu-24.04`, and `aarch64` runs on native `ubuntu-24.04-arm`. Each changed
app and declared architecture pair is an independent job; per-app manifest jobs
combine only the declared architectures before the version commit is created.
The commit contains a summary title and one body line per app showing the old
and new image tags.

An app without a `Dockerfile` uses its configured upstream `image` directly and
is not built by the workflow. The workflow fails instead of committing if such
an image tag is missing.

When adding a new app to the registry, declare its GitHub release repository.
Set the app's target `image` in `config.yaml` and its upstream image in the
final runtime-stage `FROM` line of `Dockerfile`; upstream images prefixed with
`ghcr.io/` are checked through GHCR, while unqualified names are treated as
Docker Hub repositories. The updater tries both `v1.2.3` and `1.2.3` tag forms,
so a GitHub release tag does not have to equal the image tag.

The workflow requires repository Actions permissions that allow `contents: write`
and `packages: write`.
It checks out the triggering branch and pushes back to that branch with the
workflow token.

## Validation

Before committing changes, run at least:

```bash
ruby -e 'require "json"; require "yaml"; JSON.parse(File.read("addons.json")); YAML.load_file("ddns-go/config.yaml"); YAML.load_file(".github/workflows/update-ddns-go.yml")'
git diff --check
```

Also verify that every `addons.json` path exists, has a `config.yaml`, and that
the app version exactly matches the Docker tag used by its `image`.

## Commit Convention

Use English Conventional Commits. The subject must follow:

```text
<type>(<scope>): <imperative description>
```

Common types are `feat`, `fix`, `chore`, `docs`, `refactor`, `test`, and `ci`.
Use a scope when it clarifies the affected app or workflow, for example:

```text
feat(ddns-go): add Home Assistant ingress
ci(updater): sync upstream app versions
docs: update repository guide
```

Keep the subject concise and written in the imperative mood. Use an English
body for additional context when the change needs explanation. Do not mix
unrelated changes in one commit.
