-- CreateExtension
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- CreateEnum
CREATE TYPE "MemberRole" AS ENUM ('OWNER', 'ADMIN', 'MEMBER');
CREATE TYPE "QueueStatus" AS ENUM ('ACTIVE', 'PAUSED', 'DISABLED');
CREATE TYPE "RetryStrategy" AS ENUM ('FIXED_DELAY', 'LINEAR_BACKOFF', 'EXPONENTIAL_BACKOFF');
CREATE TYPE "JobPriority" AS ENUM ('LOW', 'NORMAL', 'HIGH', 'CRITICAL');
CREATE TYPE "JobStatus" AS ENUM ('QUEUED', 'SCHEDULED', 'CLAIMED', 'RUNNING', 'COMPLETED', 'FAILED', 'RETRYING', 'DEAD_LETTER');
CREATE TYPE "WorkerStatus" AS ENUM ('STARTING', 'IDLE', 'BUSY', 'PAUSED', 'STOPPING', 'OFFLINE');
CREATE TYPE "ExecutionStatus" AS ENUM ('CLAIMED', 'RUNNING', 'COMPLETED', 'FAILED', 'RETRYING', 'CANCELLED');
CREATE TYPE "LogLevel" AS ENUM ('DEBUG', 'INFO', 'WARN', 'ERROR');

-- CreateTable
CREATE TABLE "User" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "email" VARCHAR(255) NOT NULL,
    "name" VARCHAR(255) NOT NULL,
    "passwordHash" VARCHAR(255) NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "User_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Organization" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "name" VARCHAR(255) NOT NULL,
    "slug" VARCHAR(255) NOT NULL,
    "ownerId" UUID NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Organization_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "OrganizationMember" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "organizationId" UUID NOT NULL,
    "userId" UUID NOT NULL,
    "role" "MemberRole" NOT NULL DEFAULT 'MEMBER',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "OrganizationMember_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Project" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "organizationId" UUID NOT NULL,
    "createdById" UUID,
    "name" VARCHAR(255) NOT NULL,
    "description" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Project_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "RetryPolicy" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "name" VARCHAR(255) NOT NULL,
    "strategy" "RetryStrategy" NOT NULL DEFAULT 'FIXED_DELAY',
    "maxAttempts" INTEGER NOT NULL DEFAULT 3,
    "initialDelayMs" INTEGER NOT NULL DEFAULT 1000,
    "maxDelayMs" INTEGER NOT NULL DEFAULT 30000,
    "backoffMultiplier" DOUBLE PRECISION NOT NULL DEFAULT 2.0,
    "jitterMs" INTEGER,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "RetryPolicy_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Queue" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "projectId" UUID NOT NULL,
    "retryPolicyId" UUID,
    "name" VARCHAR(255) NOT NULL,
    "description" TEXT,
    "status" "QueueStatus" NOT NULL DEFAULT 'ACTIVE',
    "priority" "JobPriority" NOT NULL DEFAULT 'NORMAL',
    "maxConcurrency" INTEGER NOT NULL DEFAULT 1,
    "isPaused" BOOLEAN NOT NULL DEFAULT false,
    "statsPending" INTEGER NOT NULL DEFAULT 0,
    "statsProcessing" INTEGER NOT NULL DEFAULT 0,
    "statsCompleted" INTEGER NOT NULL DEFAULT 0,
    "statsFailed" INTEGER NOT NULL DEFAULT 0,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Queue_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Job" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "queueId" UUID NOT NULL,
    "name" VARCHAR(255) NOT NULL,
    "payload" JSONB NOT NULL,
    "metadata" JSONB NOT NULL,
    "priority" "JobPriority" NOT NULL DEFAULT 'NORMAL',
    "status" "JobStatus" NOT NULL DEFAULT 'QUEUED',
    "currentAttempt" INTEGER NOT NULL DEFAULT 0,
    "maxAttempts" INTEGER NOT NULL DEFAULT 3,
    "scheduledFor" TIMESTAMP(6),
    "delayMs" INTEGER NOT NULL DEFAULT 0,
    "cronExpression" VARCHAR(255),
    "batchId" VARCHAR(255),
    "idempotencyKey" VARCHAR(255),
    "timeoutMs" INTEGER NOT NULL DEFAULT 30000,
    "workerId" VARCHAR(255),
    "lastError" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "claimedAt" TIMESTAMP(6),
    "startedAt" TIMESTAMP(6),
    "completedAt" TIMESTAMP(6),
    "failedAt" TIMESTAMP(6),

    CONSTRAINT "Job_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ScheduledJob" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "jobId" UUID NOT NULL,
    "nextRunAt" TIMESTAMP(6),
    "cronExpression" VARCHAR(255),
    "isRecurring" BOOLEAN NOT NULL DEFAULT false,
    "lastRunAt" TIMESTAMP(6),
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "ScheduledJob_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "DeadLetterQueue" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "jobId" UUID NOT NULL,
    "failureReason" TEXT NOT NULL,
    "failureCount" INTEGER NOT NULL DEFAULT 1,
    "movedToDlqAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "lastError" TEXT,
    "retryAllowed" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "DeadLetterQueue_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Worker" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "name" VARCHAR(255) NOT NULL,
    "hostname" VARCHAR(255) NOT NULL,
    "processId" INTEGER NOT NULL,
    "version" VARCHAR(64) NOT NULL,
    "status" "WorkerStatus" NOT NULL DEFAULT 'STARTING',
    "maxConcurrency" INTEGER NOT NULL DEFAULT 1,
    "currentRunningJobs" INTEGER NOT NULL DEFAULT 0,
    "totalJobsProcessed" INTEGER NOT NULL DEFAULT 0,
    "totalSuccessCount" INTEGER NOT NULL DEFAULT 0,
    "totalFailureCount" INTEGER NOT NULL DEFAULT 0,
    "lastHeartbeatAt" TIMESTAMP(6),
    "registeredAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Worker_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "WorkerHeartbeat" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "workerId" UUID NOT NULL,
    "heartbeatAt" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "cpuUsage" REAL,
    "memoryUsage" REAL,
    "activeJobs" INTEGER NOT NULL DEFAULT 0,
    "queueName" VARCHAR(255),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "WorkerHeartbeat_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "JobExecution" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "jobId" UUID NOT NULL,
    "workerId" UUID,
    "attemptNumber" INTEGER NOT NULL DEFAULT 1,
    "executionStatus" "ExecutionStatus" NOT NULL DEFAULT 'CLAIMED',
    "startedAt" TIMESTAMP(6),
    "completedAt" TIMESTAMP(6),
    "durationMs" INTEGER,
    "exitCode" INTEGER,
    "failureReason" TEXT,
    "retryScheduledAt" TIMESTAMP(6),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "JobExecution_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "JobLog" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "executionId" UUID NOT NULL,
    "level" "LogLevel" NOT NULL DEFAULT 'INFO',
    "message" TEXT NOT NULL,
    "metadata" JSONB NOT NULL,
    "timestamp" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "JobLog_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "User_email_key" ON "User"("email");
CREATE INDEX "User_email_idx" ON "User"("email");

-- CreateIndex
CREATE UNIQUE INDEX "Organization_slug_key" ON "Organization"("slug");
CREATE INDEX "Organization_ownerId_idx" ON "Organization"("ownerId");
CREATE INDEX "Organization_slug_idx" ON "Organization"("slug");

-- CreateIndex
CREATE UNIQUE INDEX "OrganizationMember_organizationId_userId_key" ON "OrganizationMember"("organizationId", "userId");
CREATE INDEX "OrganizationMember_organizationId_role_idx" ON "OrganizationMember"("organizationId", "role");
CREATE INDEX "OrganizationMember_userId_organizationId_idx" ON "OrganizationMember"("userId", "organizationId");

-- CreateIndex
CREATE INDEX "Project_organizationId_idx" ON "Project"("organizationId");
CREATE INDEX "Project_createdById_idx" ON "Project"("createdById");
CREATE INDEX "Project_organizationId_name_idx" ON "Project"("organizationId", "name");

-- CreateIndex
CREATE INDEX "RetryPolicy_isActive_strategy_idx" ON "RetryPolicy"("isActive", "strategy");
CREATE INDEX "RetryPolicy_name_idx" ON "RetryPolicy"("name");

-- CreateIndex
CREATE INDEX "Queue_projectId_idx" ON "Queue"("projectId");
CREATE INDEX "Queue_status_idx" ON "Queue"("status");
CREATE INDEX "Queue_priority_idx" ON "Queue"("priority");
CREATE INDEX "Queue_projectId_status_idx" ON "Queue"("projectId", "status");
CREATE INDEX "Queue_projectId_priority_idx" ON "Queue"("projectId", "priority");
CREATE UNIQUE INDEX "Queue_projectId_name_key" ON "Queue"("projectId", "name");

-- CreateIndex
CREATE UNIQUE INDEX "Job_idempotencyKey_key" ON "Job"("idempotencyKey");
CREATE INDEX "Job_queueId_idx" ON "Job"("queueId");
CREATE INDEX "Job_status_idx" ON "Job"("status");
CREATE INDEX "Job_priority_idx" ON "Job"("priority");
CREATE INDEX "Job_scheduledFor_idx" ON "Job"("scheduledFor");
CREATE INDEX "Job_createdAt_idx" ON "Job"("createdAt");
CREATE INDEX "Job_cronExpression_idx" ON "Job"("cronExpression");
CREATE INDEX "Job_batchId_idx" ON "Job"("batchId");
CREATE INDEX "Job_queueId_status_idx" ON "Job"("queueId", "status");
CREATE INDEX "Job_queueId_priority_status_idx" ON "Job"("queueId", "priority", "status");

-- CreateIndex
CREATE UNIQUE INDEX "ScheduledJob_jobId_key" ON "ScheduledJob"("jobId");
CREATE INDEX "ScheduledJob_nextRunAt_idx" ON "ScheduledJob"("nextRunAt");
CREATE INDEX "ScheduledJob_isActive_nextRunAt_idx" ON "ScheduledJob"("isActive", "nextRunAt");
CREATE INDEX "ScheduledJob_cronExpression_idx" ON "ScheduledJob"("cronExpression");

-- CreateIndex
CREATE UNIQUE INDEX "DeadLetterQueue_jobId_key" ON "DeadLetterQueue"("jobId");
CREATE INDEX "DeadLetterQueue_movedToDlqAt_idx" ON "DeadLetterQueue"("movedToDlqAt");
CREATE INDEX "DeadLetterQueue_retryAllowed_movedToDlqAt_idx" ON "DeadLetterQueue"("retryAllowed", "movedToDlqAt");

-- CreateIndex
CREATE INDEX "Worker_status_idx" ON "Worker"("status");
CREATE INDEX "Worker_lastHeartbeatAt_idx" ON "Worker"("lastHeartbeatAt");
CREATE INDEX "Worker_hostname_idx" ON "Worker"("hostname");
CREATE INDEX "Worker_name_idx" ON "Worker"("name");

-- CreateIndex
CREATE INDEX "WorkerHeartbeat_workerId_idx" ON "WorkerHeartbeat"("workerId");
CREATE INDEX "WorkerHeartbeat_heartbeatAt_idx" ON "WorkerHeartbeat"("heartbeatAt");
CREATE INDEX "WorkerHeartbeat_workerId_heartbeatAt_idx" ON "WorkerHeartbeat"("workerId", "heartbeatAt");

-- CreateIndex
CREATE INDEX "JobExecution_jobId_idx" ON "JobExecution"("jobId");
CREATE INDEX "JobExecution_workerId_idx" ON "JobExecution"("workerId");
CREATE INDEX "JobExecution_executionStatus_idx" ON "JobExecution"("executionStatus");
CREATE INDEX "JobExecution_startedAt_idx" ON "JobExecution"("startedAt");
CREATE INDEX "JobExecution_completedAt_idx" ON "JobExecution"("completedAt");
CREATE INDEX "JobExecution_jobId_executionStatus_idx" ON "JobExecution"("jobId", "executionStatus");
CREATE INDEX "JobExecution_jobId_attemptNumber_idx" ON "JobExecution"("jobId", "attemptNumber");

-- CreateIndex
CREATE INDEX "JobLog_executionId_idx" ON "JobLog"("executionId");
CREATE INDEX "JobLog_level_idx" ON "JobLog"("level");
CREATE INDEX "JobLog_timestamp_idx" ON "JobLog"("timestamp");

-- AddForeignKey
ALTER TABLE "Organization"
    ADD CONSTRAINT "Organization_ownerId_fkey"
    FOREIGN KEY ("ownerId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "OrganizationMember"
    ADD CONSTRAINT "OrganizationMember_organizationId_fkey"
    FOREIGN KEY ("organizationId") REFERENCES "Organization"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "OrganizationMember"
    ADD CONSTRAINT "OrganizationMember_userId_fkey"
    FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Project"
    ADD CONSTRAINT "Project_organizationId_fkey"
    FOREIGN KEY ("organizationId") REFERENCES "Organization"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Project"
    ADD CONSTRAINT "Project_createdById_fkey"
    FOREIGN KEY ("createdById") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Queue"
    ADD CONSTRAINT "Queue_projectId_fkey"
    FOREIGN KEY ("projectId") REFERENCES "Project"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Queue"
    ADD CONSTRAINT "Queue_retryPolicyId_fkey"
    FOREIGN KEY ("retryPolicyId") REFERENCES "RetryPolicy"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Job"
    ADD CONSTRAINT "Job_queueId_fkey"
    FOREIGN KEY ("queueId") REFERENCES "Queue"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ScheduledJob"
    ADD CONSTRAINT "ScheduledJob_jobId_fkey"
    FOREIGN KEY ("jobId") REFERENCES "Job"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "DeadLetterQueue"
    ADD CONSTRAINT "DeadLetterQueue_jobId_fkey"
    FOREIGN KEY ("jobId") REFERENCES "Job"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "WorkerHeartbeat"
    ADD CONSTRAINT "WorkerHeartbeat_workerId_fkey"
    FOREIGN KEY ("workerId") REFERENCES "Worker"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "JobExecution"
    ADD CONSTRAINT "JobExecution_jobId_fkey"
    FOREIGN KEY ("jobId") REFERENCES "Job"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "JobExecution"
    ADD CONSTRAINT "JobExecution_workerId_fkey"
    FOREIGN KEY ("workerId") REFERENCES "Worker"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "JobLog"
    ADD CONSTRAINT "JobLog_executionId_fkey"
    FOREIGN KEY ("executionId") REFERENCES "JobExecution"("id") ON DELETE CASCADE ON UPDATE CASCADE;
