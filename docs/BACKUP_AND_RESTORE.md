# Backup and Restore Notes

This starter kit includes backup script templates for:
- PostgreSQL
- MySQL
- Redis
- SQL Server

## Recommended Policy
- daily scheduled backups
- weekly retained backups
- monthly retained backups
- manual backup before risky changes
- regular restore testing

## Key Principle
A backup is not trustworthy until you have tested a restore.

## Suggested Restore Practice
- restore into a staging database or temporary environment
- validate the service starts correctly
- validate the application can connect if relevant
- document restore time and issues

## Suggested Directory Logic
You may later separate backup tiers like:
- `/opt/vps/backups/daily`
- `/opt/vps/backups/weekly`
- `/opt/vps/backups/monthly`

## Shared Backup Helpers
This version adds shared helpers for:
- backup verification
- retention cleanup
- off-site sync placeholders

## Shared Backups Folder
Expected root:

```text
/opt/vps/backups/
```
