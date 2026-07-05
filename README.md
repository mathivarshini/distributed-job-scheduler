# Distributed Job Scheduling Platform

A production-inspired distributed job scheduling platform with separate backend, worker, frontend, database, and documentation layers.

## Project Overview

This repository contains a modular foundation for a distributed job scheduling platform capable of handling immediate, delayed, scheduled, recurring, and batch jobs across multiple workers.

## Tech Stack

- Backend: Node.js, Express.js, TypeScript, Prisma, PostgreSQL
- Worker: Node.js, TypeScript
- Frontend: React, TypeScript, Vite, Tailwind CSS
- DevOps: Docker, Docker Compose, GitHub Actions

## Architecture

- backend-api: REST APIs, authentication, queue management, job control
- worker-service: job polling, claiming, execution, retries, heartbeats
- frontend: dashboard, monitoring, queue administration, job exploration
- database: Prisma schema, migrations, seed data
- docs: architecture, API, ERD, design decisions

## Folder Structure

```text
distributed-job-scheduler/
  backend-api/
  worker-service/
  frontend/
  database/
  docs/
  docker/
  scripts/
  .github/workflows/
```

## Docker Setup

### Prerequisites

- Docker Desktop or Docker Engine with Docker Compose v2
- Node.js is optional for local development outside containers

### Environment Files

Copy the example files as needed before starting the stack:

```bash
cp .env.example .env
cp backend-api/.env.example backend-api/.env
cp worker-service/.env.example worker-service/.env
cp frontend/.env.example frontend/.env
```

### Start the full stack

```bash
docker compose up --build
```

### Useful commands

```bash
docker compose up --build
docker compose down
docker compose logs -f backend-api
docker compose ps
```

### Service endpoints

- Backend API: http://localhost:4000
- Frontend: http://localhost:3000
- PostgreSQL: localhost:5432

## Development Commands

- Backend: `docker compose up backend-api`
- Worker: `docker compose up worker-service`
- Frontend: `docker compose up frontend`
- Database only: `docker compose up postgres`

## Future Phases

- Authentication and authorization
- Queue and worker orchestration
- Job execution engine
- Real-time dashboard updates
- Advanced monitoring and metrics
