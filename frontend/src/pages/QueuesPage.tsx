import Header from '../components/Header';
import EmptyState from '../components/EmptyState';

export default function QueuesPage() {
  return (
    <div>
      <Header title="Queues" subtitle="TODO: manage queue policies and concurrency" />
      <EmptyState title="No queues configured" description="Queue configuration will appear here once the API is wired up." />
    </div>
  );
}
