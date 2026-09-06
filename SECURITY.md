# Security

[Documentation](DOCUMENTATION.md)

## Supported version

Security fixes are provided for the latest release on the `main` branch.

## Design

The plugin has no network access, privileged helper, filesystem backend, or direct subprocess object. Workspace actions are numeric IDs produced by the bounded model and passed through Omarchy's existing bar runner with shell quoting. IPC JSON is parsed defensively and sanitized before persistence.

## Reporting

Use GitHub's private vulnerability reporting before public disclosure. Do not
include credentials, private paths, monitor serials, or unrelated logs in a
public issue.

## Release security checklist

- Preserve every upstream copyright notice and the complete MIT license.
- Confirm release archives contain `LICENSE` and `NOTICE` and exclude tests,
  workflows, local caches, and maintainer scripts.
- Run the complete validation suite and inspect dependency-action updates.
- Verify the GitHub artifact attestation for the release archive.
- Confirm IPC bounds, workspace-ID quoting, and settings persistence guards.
