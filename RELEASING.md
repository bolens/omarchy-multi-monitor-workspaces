# Release playbook

[Documentation](DOCUMENTATION.md)

Releases use Semantic Versioning and signed annotated `vX.Y.Z` tags on `main`.

## Prepare and validate

1. Start from an up-to-date branch and choose a version appropriate to the
   compatibility impact.
2. Update the single authoritative version in `manifest.json`.
3. Move completed changes from `Unreleased` into a dated `CHANGELOG.md`
   section and update comparison links.
4. Run `MMW_QML_TESTS=never npm test`, then the live and stress validation from
   [TESTING.md](TESTING.md) on an Omarchy workstation.

## Review and publish

1. Open a pull request, require CI and review conversations to pass, then
   squash-merge it and delete the branch. Never push directly to `main` or
   bypass protection.
2. Tag the validated `main` commit as `vX.Y.Z`. The release workflow verifies
   the tag and publishes a checksummed, provenance-attested source archive.

## Verify and recover

Never move a published tag. Fix a broken release forward with a new patch
version. Verify the archive retains `manifest.json`, `README.md`, `LICENSE`,
`NOTICE`, and `preview.png` and excludes maintainer-only files.

Verify the published provenance after the workflow finishes:

```sh
gh attestation verify "omarchy-multi-monitor-workspaces-$version.tar.gz" \
  --repo bolens/omarchy-multi-monitor-workspaces
```

Confirm the checksum, archive contents, clean install/update path, Pages release
display, and marketplace listing. Preserve the tag SHA, CI run, digest, and
attestation result as release evidence.

Fleet policy: <https://github.com/bolens/.github/blob/main/RELEASING.md>.

## Source lint

The Source lint workflow checks maintained python, javascript, css files selected by
[`.github/source-lint.json`](.github/source-lint.json) on every pull request
and push to `main`. Existing native checks remain part of the merge gate.
Use the [shared local reproduction instructions](https://github.com/bolens/.github/blob/7603518f305fb76f7bb1b9979f2692521f633b82/docs/source-lint.md)
with the same tooling revision pinned in
[the workflow](.github/workflows/source-lint.yml). Review exclusions when adding
source files; generated and imported files retain their native validation.
Require the new check to pass on the current PR head before merging.
