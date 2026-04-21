# CI/CD V3 Guide

This document explains the reusable GitHub Actions deployment model.

## Flow

1. SSH to the VPS
2. enter app directory
3. reset to target branch
4. optionally back up
5. rebuild and start containers
6. optionally run migration
7. optionally run health checks
