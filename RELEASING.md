# Release playbook

Releases use Semantic Versioning and annotated `vX.Y.Z` tags on `main`.

1. Start from an up-to-date branch and choose a version appropriate to the
   compatibility impact.
2. Update the single authoritative version in `manifest.json`.
3. Move completed changes from `Unreleased` into a dated `CHANGELOG.md`
   section and update comparison links.
4. Run `MMW_QML_TESTS=never npm test`, then the live and stress validation from
   [TESTING.md](TESTING.md) on an Omarchy workstation.
5. Open a pull request and require CI to pass before merging.
6. Tag the validated `main` commit as `vX.Y.Z`. The release workflow verifies
   the tag and publishes a checksummed, provenance-attested source archive.

Never move a published tag. Fix a broken release forward with a new patch
version. Verify the archive retains `manifest.json`, `README.md`, `LICENSE`,
`NOTICE`, and `preview.png` and excludes maintainer-only files.

Verify the published provenance after the workflow finishes:

```sh
gh attestation verify "omarchy-multi-monitor-workspaces-$version.tar.gz" \
  --repo bolens/omarchy-multi-monitor-workspaces
```
