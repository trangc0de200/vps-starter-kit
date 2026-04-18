# CI/CD V3 Guide

The reusable workflow SSHes into the server, changes to the target app directory, resets the repository to the target branch, optionally runs backup, rebuilds and starts containers, optionally runs migrations, and optionally runs health checks.
