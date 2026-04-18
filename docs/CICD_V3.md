# CI/CD V3 Guide

This document explains the V3 deployment model included in this starter kit.

## Main Additions in V3
- production and staging workflow separation
- reusable deployment workflow
- manual deployment workflow
- rollback workflow
- concurrency protection
- environment-aware app template

## Recommended Branch Strategy
- `develop` → staging
- `main` → production

## Recommended GitHub Environments
- `staging`
- `production`

## Recommended Secrets
- `VPS_HOST`
- `VPS_USER`
- `VPS_SSH_KEY`
- `VPS_PORT`

## Suggested Deploy Pattern
1. Push to branch
2. GitHub Actions calls reusable workflow
3. SSH into VPS
4. Reset to target branch
5. Run optional backup
6. Deploy containers
7. Run optional migration
8. Run health check
9. Mark deployment successful or fail visibly

## Rollback
Use the rollback workflow or the app rollback script to redeploy a known good tag or commit.

## Important Advice
- keep production `.env` files on the VPS
- do not overwrite secrets casually from CI
- treat migrations carefully
- test health endpoints as part of deployment
