# Database Design

## Purpose

This database stores the core domain entities for the distributed job scheduling platform, including organizations, projects, queues, retry policies, jobs, execution history, and worker telemetry.

## Tables

### User

- Purpose: Represents an application user.
- Primary key: id
- Foreign keys: None
- Notes: Stores authentication identity and profile data.

### Organization

- Purpose: Groups users and projects.
- Primary key: id
- Foreign keys: ownerId -> User.id
- Notes: Uses a restricted owner delete rule to preserve ownership integrity.

### OrganizationMember

- Purpose: Links users to organizations with a role.
- Primary key: id
- Foreign keys: organizationId -> Organization.id, userId -> User.id
- Notes: Supports membership and role-based access control.

### Project

- Purpose: Organizes queues and work under an organization.
- Primary key: id
- Foreign keys: organizationId -> Organization.id, createdById -> User.id
- Notes: Projects are scoped to one organization.

### RetryPolicy

- Purpose: Defines retry behavior that can be reused by queues.
- Primary key: id
- Foreign keys: None
- Notes: Designed for shared policy reuse.

### Queue

- Purpose: Represents a queue of jobs for a project.
- Primary key: id
- Foreign keys: projectId -> Project.id, retryPolicyId -> RetryPolicy.id
- Notes: Supports queue-level status and priority filtering.

### Job

- Purpose: Stores the lifecycle state for work items.
- Primary key: id
- Foreign keys: queueId -> Queue.id
- Notes: Supports immediate, delayed, scheduled, recurring, and batch-oriented work patterns.

### ScheduledJob

- Purpose: Stores scheduling metadata for a job.
- Primary key: id
- Foreign keys: jobId -> Job.id
- Notes: Used for delayed or recurring job planning.

### DeadLetterQueue

- Purpose: Stores jobs that reached terminal failure.
- Primary key: id
- Foreign keys: jobId -> Job.id
- Notes: Helps preserve failed work for inspection and replay.

### Worker

- Purpose: Represents a worker process capable of claiming and processing jobs.
- Primary key: id
- Foreign keys: None
- Notes: Tracks runtime capacity and health.

### WorkerHeartbeat

- Purpose: Stores worker health telemetry.
- Primary key: id
- Foreign keys: workerId -> Worker.id
- Notes: Optimized for monitoring dashboards and heartbeat polling.

### JobExecution

- Purpose: Records each attempt of a job execution.
- Primary key: id
- Foreign keys: jobId -> Job.id, workerId -> Worker.id
- Notes: Supports retries and execution history.

### JobLog

- Purpose: Stores structured execution logs.
- Primary key: id
- Foreign keys: executionId -> JobExecution.id
- Notes: Designed for detailed debugging and monitoring.

## Relationships

- One organization has many projects.
- One project has many queues.
- One queue has many jobs.
- One job has zero or one scheduled-job record.
- One job has zero or one dead-letter record.
- One worker has many heartbeats.
- One worker has many executions.
- One job has many executions.
- One execution has many logs.

## Primary Keys

All primary keys use UUIDs.

## Foreign Keys

Foreign keys are defined for ownership, memberships, queue ownership, job ownership, execution ownership, and logging relationships.

## Indexes

The schema includes indexes for lookup, dashboard filtering, worker monitoring, scheduled execution discovery, and execution history.

## Cascade Rules

- Organization deletion cascades to projects and memberships.
- Project deletion cascades to queues.
- Queue deletion cascades to jobs.
- Job deletion cascades to scheduled metadata, DLQ entries, and executions.
- Worker deletion cascades to heartbeats and orphaned execution references.
- Execution deletion cascades to logs.

## Normalization

The schema follows Third Normal Form by separating organizational ownership, membership relations, queue configuration, job state, execution attempts, and runtime telemetry into distinct entities.

## Performance Considerations

- Queue lookups are indexed by project and status.
- Job polling is optimized through queue/status and queue/priority/status indexes.
- Scheduled jobs are indexable by next run time and activity state.
- Worker monitoring uses heartbeat indexes by worker and time.
- Execution history is indexed by job, worker, and execution status.

## Scalability Considerations

- UUIDs avoid hotspotting and support distributed systems.
- JSON columns keep flexible payload and metadata structures without schema churn.
- Additional partitioning or archival strategies may be beneficial for very large job and log tables over time.
