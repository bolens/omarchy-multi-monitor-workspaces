# Research decisions

- Use actual pinned-image diagnostics. Host-only diagnostics and previously silent disabled categories do not establish correctness.
- Prefer the real updated vendor toolchain for Process metadata; isolated old/new static controls established its repair without changing callbacks.
- Qt 6.12 adds a [Color singleton](https://doc.qt.io/qt-6/qml-qtquick-color.html), so use the official [Omarchy palette qualification fix](https://github.com/omacom/omarchy/commit/b83d3df0840504299d3099ebf391eb8110527edd) as the source basis. Preserve supported older behavior with explicit namespaces.
- Anonymous base-object fields lose their richer declared shape; [Qt's type rules](https://doc.qt.io/qt-6/qtqml-syntax-objectattributes.html#property-aliases-and-types) explain why an object-id alias is insufficient. A source-bound named declaration model is a conditional design, not accepted runtime evidence.
- Real fixture failures must be repaired before acceptance: private tmpfs execution permission, public initialization signals and event-loop completion are setup contracts. No timed waiting loop or unchanged retry is used.

All design choices preserve installed vendor files. Full source/runtime acceptance is pending; subsequent actual results belong in tasks rather than being inferred here.

Inspected baseline: `1c20a3e6198ffa2c0814f2c56ac53ca2a9221c01`, actual [native main pipeline](https://woodpecker.bolens.dev/repos/24/pipeline/8). A successful status did not establish warning cleanliness where broad categories were disabled. Corrected final-head and genuine-main evidence is still required.
