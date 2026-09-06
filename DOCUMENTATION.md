# Documentation

Monitor identity, workspace ownership, and persisted settings.

## Start here

| Need | Owning document |
| --- | --- |
| Use the project | [README.md](README.md) |
| Change the repository | [AGENTS.md](AGENTS.md) |
| Deliver or recover | [RELEASING.md](RELEASING.md) |
| Plan substantial changes | [.specify/memory/project-guide.md](.specify/memory/project-guide.md) |
| Non-negotiable constraints | [.specify/memory/constitution.md](.specify/memory/constitution.md) |

## Architecture

[ARCHITECTURE.md](ARCHITECTURE.md) owns monitor identity and workspace-bank allocation. Stable
identity must survive enumeration changes, hotplug, replacement, and ambiguous displays. Shared
service state and widget lifetimes cannot rely on attachment order.

## Deployment and recovery

[README](README.md) owns plugin installation and configuration. [RELEASING.md](RELEASING.md) owns
distribution and rollback. [TESTING.md](TESTING.md) separates portable model checks from QML and
live topology evidence. A repository validation run must not rearrange the live desktop.

## Database and state

There is no separate database service. [Service.qml](Service.qml) owns persisted settings and
pending writes. Normalize only owned fields and preserve unrelated shell state. After save failure,
show the failed or pending outcome rather than claiming the next reload will reproduce it.

## Documentation maintenance

Keep decisions, invariants, failure modes, and recovery requirements in the owning document. Link to
commands, defaults, schemas, and generated catalogs instead of copying them. Change the owner and
affected references together. Update this index when adding or moving a guide, and verify relative
links and heading anchors. Historical specs and audits describe their recorded revision, not current
runtime proof. A topic without an implementation stays explicitly unimplemented.

## Topic guides

- [README.md](README.md): installation, behavior, settings, and IPC
- [ARCHITECTURE.md](ARCHITECTURE.md): allocation and state ownership
- [TESTING.md](TESTING.md): local, QML, live, and stress validation
- [SECURITY.md](SECURITY.md): trust boundaries and vulnerability reporting
- [CONTRIBUTING.md](CONTRIBUTING.md): contribution requirements
- [RELEASING.md](RELEASING.md): versioning and release procedure
- [SUPPORT.md](SUPPORT.md): public and private report routing
- [NOTICE](NOTICE): upstream provenance and retained notices
