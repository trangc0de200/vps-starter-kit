# Security Guide

This document provides the baseline security model used by the starter kit.

## Public Port Philosophy

Recommended baseline:

- 22/tcp for SSH
- 80/tcp for HTTP
- 443/tcp for HTTPS
- 81/tcp only if you intentionally expose the Nginx Proxy Manager admin UI

## Rules

- use SSH keys
- avoid public database exposure
- review UFW regularly
- keep monitoring and admin dashboards protected
- disable SSH password login only after key access is confirmed
