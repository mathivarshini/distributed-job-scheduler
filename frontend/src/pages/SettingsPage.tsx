import Header from '../components/Header';
import EmptyState from '../components/EmptyState';

export default function SettingsPage() {
  return (
    <div>
      <Header title="Settings" subtitle="TODO: configure notifications, queues, and defaults" />
      <EmptyState title="No settings configured" description="Operational preferences will appear here." />
    </div>
  );
}
