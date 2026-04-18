# CI/CD V3 Guide

The reusable workflow:
1. SSHes into the server
2. changes to the target app directory
3. resets the repository to the target branch
4. optionally runs backup
5. rebuilds and starts containers
6. optionally runs migrations
7. optionally runs health checks
