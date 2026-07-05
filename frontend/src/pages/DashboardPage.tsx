import Header from '../components/Header';
import EmptyState from '../components/EmptyState';

export default function DashboardPage() {
  return (
    <div>
      <Header title="Dashboard" subtitle="Overview of queues, workers, and recent activity" />
      <div className="grid gap-4 md:grid-cols-3">
        <div className="rounded-xl border border-slate-800 bg-slate-900 p-4">
          <p className="text-sm text-slate-400">Active Workers</p>
          <p className="mt-2 text-2xl font-semibold">0</p>
        </div>
        <div className="rounded-xl border border-slate-800 bg-slate-900 p-4">
          <p className="text-sm text-slate-400">Queued Jobs</p>
          <p className="mt-2 text-2xl font-semibold">0</p>
        </div>
        <div className="rounded-xl border border-slate-800 bg-slate-900 p-4">
          <p className="text-sm text-slate-400">Paused Queues</p>
          <p className="mt-2 text-2xl font-semibold">0</p>
        </div>
      </div>
      <div className="mt-6">
        <EmptyState title="No live activity yet" description="TODO: connect Socket.IO and chart widgets." />
      </div>
    </div>
  );
}
