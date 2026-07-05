# Database Notes

## Naming Conventions

- Use lowercase snake_case for database columns and tables.
- Use descriptive names for entities and relationships.

## UUID Strategy

- Prefer UUID primary keys for distributed and horizontally scalable systems.

## Normalization Strategy

- Keep the schema normalized and avoid redundant data.
- Use lookup tables where appropriate.

## Indexing Strategy

- Create explicit indexes for frequently filtered and sorted fields.

## Migration Strategy

- Keep migrations small and reviewable.
- Use migration names that clearly describe the change.

## Soft Delete Strategy

- Use a soft-delete pattern where auditability matters.

## Timestamp Strategy

- Track created and updated timestamps for all major entities.
