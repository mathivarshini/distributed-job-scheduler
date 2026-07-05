import { PrismaClient } from '@prisma/client';
import { MemberRole, QueueStatus, RetryStrategy, JobPriority, JobStatus, WorkerStatus, ExecutionStatus, LogLevel } from '@prisma/client';

const prisma = new PrismaClient({
  datasourceUrl: process.env.DATABASE_URL ?? 'postgresql://postgres:postgres@localhost:5432/job_scheduler',
});

async function main(): Promise<void> {
  await prisma.$connect();

  await prisma.organizationMember.deleteMany();
  await prisma.jobLog.deleteMany();
  await prisma.jobExecution.deleteMany();
  await prisma.workerHeartbeat.deleteMany();
  await prisma.deadLetterQueue.deleteMany();
  await prisma.scheduledJob.deleteMany();
  await prisma.job.deleteMany();
  await prisma.queue.deleteMany();
  await prisma.retryPolicy.deleteMany();
  await prisma.project.deleteMany();
  await prisma.organization.deleteMany();
  await prisma.user.deleteMany();
  await prisma.worker.deleteMany();

  const users = await prisma.$transaction([
    prisma.user.create({ data: { email: 'owner@example.com', name: 'Taylor Owner', passwordHash: 'hashed-owner' } }),
    prisma.user.create({ data: { email: 'admin@example.com', name: 'Avery Admin', passwordHash: 'hashed-admin' } }),
    prisma.user.create({ data: { email: 'member@example.com', name: 'Morgan Member', passwordHash: 'hashed-member' } }),
  ]);

  const organization = await prisma.organization.create({
    data: {
      name: 'Northwind Labs',
      slug: 'northwind-labs',
      ownerId: users[0].id,
    },
  });

  await prisma.organizationMember.createMany({
    data: [
      { organizationId: organization.id, userId: users[0].id, role: MemberRole.OWNER },
      { organizationId: organization.id, userId: users[1].id, role: MemberRole.ADMIN },
      { organizationId: organization.id, userId: users[2].id, role: MemberRole.MEMBER },
    ],
  });

  const projects = await prisma.$transaction([
    prisma.project.create({ data: { organizationId: organization.id, createdById: users[0].id, name: 'Platform API', description: 'Core backend services' } }),
    prisma.project.create({ data: { organizationId: organization.id, createdById: users[1].id, name: 'Analytics Dash', description: 'Reporting workflows' } }),
  ]);

  const retryPolicies = await prisma.$transaction([
    prisma.retryPolicy.create({ data: { name: 'Default Retry', strategy: RetryStrategy.EXPONENTIAL_BACKOFF, maxAttempts: 4, initialDelayMs: 1000, maxDelayMs: 20000, backoffMultiplier: 2, jitterMs: 250, isActive: true } }),
    prisma.retryPolicy.create({ data: { name: 'Fast Retry', strategy: RetryStrategy.FIXED_DELAY, maxAttempts: 3, initialDelayMs: 500, maxDelayMs: 5000, backoffMultiplier: 1.5, jitterMs: 50, isActive: true } }),
    prisma.retryPolicy.create({ data: { name: 'Standby Retry', strategy: RetryStrategy.LINEAR_BACKOFF, maxAttempts: 2, initialDelayMs: 2000, maxDelayMs: 10000, backoffMultiplier: 1.2, jitterMs: 100, isActive: false } }),
  ]);

  const queues = await prisma.$transaction([
    prisma.queue.create({ data: { projectId: projects[0].id, retryPolicyId: retryPolicies[0].id, name: 'emails', description: 'Email delivery', status: QueueStatus.ACTIVE, priority: JobPriority.HIGH, maxConcurrency: 4, isPaused: false } }),
    prisma.queue.create({ data: { projectId: projects[0].id, retryPolicyId: retryPolicies[1].id, name: 'reports', description: 'Reporting queue', status: QueueStatus.ACTIVE, priority: JobPriority.NORMAL, maxConcurrency: 2, isPaused: false } }),
    prisma.queue.create({ data: { projectId: projects[1].id, retryPolicyId: retryPolicies[0].id, name: 'sync', description: 'System sync', status: QueueStatus.PAUSED, priority: JobPriority.CRITICAL, maxConcurrency: 3, isPaused: true } }),
    prisma.queue.create({ data: { projectId: projects[1].id, retryPolicyId: retryPolicies[2].id, name: 'audit', description: 'Audit trail', status: QueueStatus.DISABLED, priority: JobPriority.LOW, maxConcurrency: 1, isPaused: false } }),
  ]);

  const jobs = [] as Array<Awaited<ReturnType<typeof prisma.job.create>>>;
  for (let index = 0; index < 25; index += 1) {
    const queue = queues[index % queues.length];
    const status = index % 5 === 0 ? JobStatus.FAILED : index % 4 === 0 ? JobStatus.COMPLETED : index % 3 === 0 ? JobStatus.RETRYING : JobStatus.QUEUED;
    const shouldTrackTiming = status === JobStatus.COMPLETED || status === JobStatus.FAILED;
    const created = await prisma.job.create({
      data: {
        queueId: queue.id,
        name: `job-${index + 1}`,
        payload: { id: index + 1 },
        metadata: { source: 'seed' },
        priority: index % 2 === 0 ? JobPriority.HIGH : JobPriority.NORMAL,
        status,
        currentAttempt: index % 3,
        maxAttempts: 4,
        scheduledFor: index % 2 === 0 ? new Date(Date.now() + index * 60000) : null,
        delayMs: index * 100,
        cronExpression: index % 6 === 0 ? '0 * * * *' : null,
        batchId: index % 7 === 0 ? `batch-${index + 1}` : null,
        idempotencyKey: index % 8 === 0 ? `idem-${index + 1}` : null,
        timeoutMs: 30000,
        workerId: index % 5 === 0 ? 'worker-seed' : null,
        lastError: status === JobStatus.FAILED ? 'Simulated failure' : null,
        claimedAt: shouldTrackTiming ? new Date() : null,
        startedAt: shouldTrackTiming ? new Date() : null,
        completedAt: status === JobStatus.COMPLETED ? new Date() : null,
        failedAt: status === JobStatus.FAILED ? new Date() : null,
      },
    });
    jobs.push(created);
  }

  const scheduledJobs = await prisma.$transaction([
    prisma.scheduledJob.create({ data: { jobId: jobs[0].id, nextRunAt: new Date(Date.now() + 5 * 60000), cronExpression: '*/5 * * * *', isRecurring: true, lastRunAt: null, isActive: true } }),
    prisma.scheduledJob.create({ data: { jobId: jobs[1].id, nextRunAt: new Date(Date.now() + 15 * 60000), cronExpression: null, isRecurring: false, lastRunAt: new Date(), isActive: true } }),
    prisma.scheduledJob.create({ data: { jobId: jobs[2].id, nextRunAt: new Date(Date.now() + 30 * 60000), cronExpression: '0 0 * * *', isRecurring: true, lastRunAt: new Date(), isActive: false } }),
    prisma.scheduledJob.create({ data: { jobId: jobs[3].id, nextRunAt: new Date(Date.now() + 60 * 60000), cronExpression: null, isRecurring: false, lastRunAt: null, isActive: true } }),
    prisma.scheduledJob.create({ data: { jobId: jobs[4].id, nextRunAt: new Date(Date.now() + 90 * 60000), cronExpression: '0 12 * * 1', isRecurring: true, lastRunAt: new Date(), isActive: true } }),
  ]);

  await prisma.deadLetterQueue.createMany({
    data: [
      { jobId: jobs[5].id, failureReason: 'Persistent processing error', failureCount: 2, lastError: 'Simulated terminal failure', retryAllowed: false },
      { jobId: jobs[6].id, failureReason: 'Payload validation failed', failureCount: 3, lastError: 'Invalid payload', retryAllowed: false },
    ],
  });

  const workers = await prisma.$transaction([
    prisma.worker.create({ data: { name: 'worker-alpha', hostname: 'worker-1', processId: 1001, version: '1.0.0', status: WorkerStatus.BUSY, maxConcurrency: 4, currentRunningJobs: 2, totalJobsProcessed: 120, totalSuccessCount: 115, totalFailureCount: 5, lastHeartbeatAt: new Date() } }),
    prisma.worker.create({ data: { name: 'worker-beta', hostname: 'worker-2', processId: 1002, version: '1.0.0', status: WorkerStatus.IDLE, maxConcurrency: 2, currentRunningJobs: 0, totalJobsProcessed: 80, totalSuccessCount: 76, totalFailureCount: 4, lastHeartbeatAt: new Date() } }),
    prisma.worker.create({ data: { name: 'worker-gamma', hostname: 'worker-3', processId: 1003, version: '1.0.0', status: WorkerStatus.OFFLINE, maxConcurrency: 3, currentRunningJobs: 0, totalJobsProcessed: 40, totalSuccessCount: 37, totalFailureCount: 3, lastHeartbeatAt: new Date(Date.now() - 600000) } }),
  ]);

  await prisma.workerHeartbeat.createMany({
    data: [
      { workerId: workers[0].id, heartbeatAt: new Date(), cpuUsage: 42.3, memoryUsage: 61.2, activeJobs: 2, queueName: 'emails' },
      { workerId: workers[0].id, heartbeatAt: new Date(Date.now() - 30000), cpuUsage: 39.1, memoryUsage: 58.8, activeJobs: 1, queueName: 'emails' },
      { workerId: workers[1].id, heartbeatAt: new Date(), cpuUsage: 18.7, memoryUsage: 30.2, activeJobs: 0, queueName: 'reports' },
    ],
  });

  const executions = await prisma.$transaction([
    prisma.jobExecution.create({ data: { jobId: jobs[7].id, workerId: workers[0].id, attemptNumber: 1, executionStatus: ExecutionStatus.COMPLETED, startedAt: new Date(), completedAt: new Date(Date.now() + 2000), durationMs: 2000, exitCode: 0, failureReason: null, retryScheduledAt: null } }),
    prisma.jobExecution.create({ data: { jobId: jobs[8].id, workerId: workers[1].id, attemptNumber: 1, executionStatus: ExecutionStatus.FAILED, startedAt: new Date(), completedAt: new Date(Date.now() + 1500), durationMs: 1500, exitCode: 1, failureReason: 'Timeout', retryScheduledAt: new Date(Date.now() + 60000) } }),
    prisma.jobExecution.create({ data: { jobId: jobs[9].id, workerId: workers[2].id, attemptNumber: 2, executionStatus: ExecutionStatus.RETRYING, startedAt: new Date(), completedAt: null, durationMs: null, exitCode: null, failureReason: 'Transient error', retryScheduledAt: new Date(Date.now() + 30000) } }),
  ]);

  await prisma.jobLog.createMany({
    data: [
      { executionId: executions[0].id, level: LogLevel.INFO, message: 'Completed successfully', metadata: { step: 'finish' } },
      { executionId: executions[1].id, level: LogLevel.ERROR, message: 'Execution timed out', metadata: { attempt: 1 } },
      { executionId: executions[2].id, level: LogLevel.WARN, message: 'Retry scheduled', metadata: { retryInMs: 30000 } },
    ],
  });

  console.log('Seed data inserted successfully.');
}

main()
  .catch((error) => {
    console.error(error);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
