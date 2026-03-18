---
title: Project Overview
---

# Project Overview

This document provides a high-level description of the project for Kiro to use as context when generating code, answering questions, or making suggestions.

## Purpose

Describe the primary goal of this project here. What problem does it solve? Who are the users?

## Technology Stack

List the main technologies, frameworks, and languages used:

- **Runtime / Language**: (e.g., Node 20 / TypeScript, Python 3.11, Go 1.22, .NET 8)
- **Framework**: (e.g., Express, FastAPI, Gin, ASP.NET Core)
- **Database**: (e.g., PostgreSQL, DynamoDB, MongoDB)
- **Infrastructure**: (e.g., AWS, Docker, Kubernetes)

## Repository Layout

Describe the top-level folder structure so Kiro understands where things live:

```
/
├── src/           # Application source code
├── tests/         # Automated tests
├── docs/          # Documentation
├── scripts/       # Utility scripts
└── infra/         # Infrastructure-as-code (if applicable)
```

## Key Conventions

- Branch naming: `feat/<ticket>-short-description`, `fix/<ticket>-short-description`
- Commit style: Conventional Commits (`feat:`, `fix:`, `chore:`, `docs:`, etc.)
- Pull requests require at least one approving review before merge.
