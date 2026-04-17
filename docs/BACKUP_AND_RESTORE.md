# Backup and Restore Notes

This starter kit includes backup script templates for:
- PostgreSQL
- MySQL
- Redis
- SQL Server

## Recommended Policy
- daily scheduled backups
- manual backup before risky changes
- keep at least 7 to 14 days of backup retention
- test restore regularly

## Key Principle
A backup is not trustworthy until you have tested a restore.

## Suggested Restore Practice
- restore into a staging database or temporary environment
- validate the service starts correctly
- validate the application can connect if relevant
- document restore time and issues

## Shared Backups Folder
Expected root:

```text
/opt/vps/backups/
```
