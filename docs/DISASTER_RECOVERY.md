# Disaster Recovery Notes

This document outlines a practical disaster recovery approach for the starter kit.

## Minimum Recovery Readiness
- backups exist
- retention is defined
- restore commands are documented
- restore has been tested at least once
- production secrets are available
- DNS and domain mappings are documented

## Recommended Recovery Levels

### Level 1 - Single Service Restore
Examples:
- restore PostgreSQL from backup
- restore MySQL dump
- restore Redis snapshot
- restore SQL Server backup

### Level 2 - App + Database Recovery
Examples:
- restore app code to known tag
- restore matching database backup
- run health checks

### Level 3 - Full VPS Recovery
Examples:
- provision new VPS
- run bootstrap script
- restore infrastructure config
- restore DB backups
- redeploy apps
- validate DNS and SSL

## Important Advice
Disaster recovery is not complete until you have:
- documented the steps
- timed the restore
- verified the application is usable afterwards
