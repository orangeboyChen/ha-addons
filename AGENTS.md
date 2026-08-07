# Project Guide

## Overview

This repository contains private Home Assistant Apps (formerly called add-ons).
Each app is a Home Assistant wrapper around a multi-architecture Docker image or
an app-specific Docker build. The repository currently provides `ddns-go`, which
uses the upstream `ghcr.io/jeessy2/ddns-go` image and exposes its web interface through
Home Assistant Ingress.

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
   Docker image, set `image` to the upstream multi-architecture image and set
   `version` to the exact Docker tag.
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

For a locally built app, add the required Dockerfile and ensure its runtime
command persists state under Home Assistant's always-writable `/data` path.
Do not assume that Home Assistant options are automatically passed as command
line flags or environment variables; wire them into the image explicitly.

## Upstream Update Action

`.github/workflows/update-ddns-go.yml` runs every 30 minutes and can also be
started manually. It reads every entry from the root `addons.json`, queries that
entry's GitHub `releases/latest` endpoint, reads the image repository from the
app's `config.yaml`, tries the release tag and its common `v`-prefix variant in
the implied registry, reads
the current version from the app's `config.yaml`, and updates only that app when
the image tag changes. The update commit contains a summary title and one body
line per app showing the old and new image tags.

When adding a new app to the registry, declare its GitHub release repository.
Set the app's `image` field in `config.yaml`; images prefixed with `ghcr.io/`
are checked through GHCR, while unqualified image names are treated as Docker
Hub repositories. The updater tries both `v1.2.3` and `1.2.3` tag forms, so a
GitHub release tag does not have to equal the image tag.

The workflow requires repository Actions permissions that allow `contents: write`.
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
