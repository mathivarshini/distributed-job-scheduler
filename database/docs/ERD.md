# ER Diagram

```mermaid
erDiagram
  User ||--o{ Organization : owns
  User ||--o{ OrganizationMember : belongs_to
  Organization ||--o{ OrganizationMember : has
  Organization ||--o{ Project : contains
  User ||--o{ Project : creates
  Project ||--o{ Queue : contains
  RetryPolicy ||--o{ Queue : applies_to
  Queue ||--o{ Job : contains
  Job ||--o| ScheduledJob : has
  Job ||--o| DeadLetterQueue : may_be_moved_to
  Worker ||--o{ WorkerHeartbeat : emits
  Worker ||--o{ JobExecution : runs
  Job ||--o{ JobExecution : has
  JobExecution ||--o{ JobLog : produces
```

## Relationship Summary

- Each organization has one owner and many members.
- Each project belongs to one organization and may have many queues.
- Each queue belongs to one project and can use one retry policy.
- Each job belongs to one queue and can produce many execution attempts.
- Each execution attempt can produce many logs.
