# Testing

Run `npm test`. On a live Wayland session this also launches short-lived exact-path QML harnesses and verifies that the persistent Quickshell inventory is unchanged afterward. Set `MMW_QML_TESTS=never` for static-only validation or `always` to require runtime coverage.

Runtime harnesses are killed by their exact temporary config path; they never use global Quickshell termination.

After deploying, run `npm run verify:live` for panel, topology, allocation-snapshot, bank, and IPC health checks. Run `npm run verify:stress` for a reversible live test of glyph persistence, 100 alternating monitor-panel cycles, exact settings restoration, and persistent Quickshell process identity. The stress verifier always closes the panel and attempts restoration through an exit trap.

Pure tests exercise deterministic attach-order permutations and 1, 2, 3, 8, 16, 32, 64, and 100 attached outputs—the full bounded bank range. The real QML service harness adds 32 presentations, removes alternating outputs, checks non-overlap and exact topology invalidation, and retains the current replacement across stale teardown.

The service harness also covers rapid cross-monitor panel ownership, detached-widget routing rejection, queued writes racing an entry removal, retained intent, and recovery against a newer reappeared entry without overwriting its unrelated fields.

Replacement tests use distinct old and new widget objects, require the displaced panel to close, and verify that stale teardown cannot remove the successor. Error-lifetime tests require successful IPC to preserve an unresolved persistence failure and unhealthy status until a real commit succeeds.
