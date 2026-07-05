import Header from '../components/Header';
import EmptyState from '../components/EmptyState';

export default function JobsPage() {
  return (
    <div>
      <Header title="Jobs" subtitle="TODO: browse, filter, and inspect jobs" />
      <EmptyState title="No jobs available" description="Job history and execution details will appear here." />
    </div>
  );
}
