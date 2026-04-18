# Platform V7 Guide

This document explains the platformization layer introduced in V7.

## Main Additions
- `vps-cli`
- centralized config
- plugin-style service folders
- multi-project conventions
- service bootstrap helper
- config validation helper
- platform status helper

## Recommended Use
- keep low-level scripts for full control
- use `vps-cli` for repeated operational tasks
- use `config/platform.yml` as a human-readable source of platform defaults
- extend the platform gradually with plugins and service presets
