import Header from '../components/Header';
import EmptyState from '../components/EmptyState';

export default function WorkersPage() {
  return (
    <div>
      <Header title="Workers" subtitle="TODO: monitor worker heartbeat and status" />
      <EmptyState title="No workers connected" description="Worker health and activity will be surfaced here." />
    </div>
  );
}
