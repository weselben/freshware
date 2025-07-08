# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

### Added
-   **`FRESHWARE_CLEANUP_OLD_THEMES` Environment Variable:** Introduced a new environment variable to control the automatic removal of old theme data.
    -   **Explanation:** This feature allows users to enable or disable the cleanup of theme folders older than 90 days. By default, if this variable is not defined or set to anything other than `true`, no data will be removed. Setting it to `true` will activate the cleanup process, helping to manage disk space in environments where themes might accumulate.
-   **Custom Parameters for Worker and Tasker:** Added `WORKER_CUSTOM_PARAMS` and `TASKER_CUSTOM_PARAMS` environment variables.
    -   **Explanation:** These variables provide full customizability for the `php bin/console` commands executed by the worker and tasker processes. Users can now pass additional arguments (e.g., `--verbose`, `--env=prod`) directly through these environment variables, allowing for more flexible debugging and operational control without modifying the `entrypoint.sh` script.

### Changed
-   **Worker and Tasker Restart Logic:** Modified the behavior of worker and tasker processes.
    -   **Explanation:** Previously, these processes would continuously restart within the container upon exit. Now, if a worker or tasker process exits with an error (non-zero exit code), the entire Docker container will terminate. This allows container orchestration systems (like Docker Swarm or Kubernetes) to handle the restart of a fresh container, providing a more robust and predictable recovery mechanism for critical failures, while still allowing in-container restarts for graceful exits.
-   **`FRESHWARE_VERSION` Increment:** Updated the `FRESHWARE_VERSION` from `0.2.8` to `0.2.9` in `Dockerfile` and `docker-compose.yml`.
    -   **Explanation:** This version bump reflects the recent feature additions and changes to the project, adhering to semantic versioning principles.
