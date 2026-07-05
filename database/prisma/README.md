# Prisma Database Workspace

## Purpose

This directory contains the Prisma workspace used by the backend service for future database development.

## Prisma

Prisma is configured with a PostgreSQL datasource and a client generator.

## Migration Workflow

1. Update the schema file.
2. Run `npx prisma migrate dev --name <change-name>`.
3. Review the generated migration files.

## Seed Workflow

1. Update `seed.ts` with seed logic.
2. Run `npx prisma db seed`.

## Folder Responsibilities

- `schema.prisma`: Prisma schema definition
- `migrations/`: migration files
- `seed.ts`: seed entry point

## Best Practices

- Keep the schema minimal and explicit.
- Use UUID primary keys for distributed systems.
- Add indexes for query-heavy fields.
- Avoid introducing business logic into the database layer.
