import Header from '../components/Header';
import EmptyState from '../components/EmptyState';

export default function ProjectsPage() {
  return (
    <div>
      <Header title="Projects" subtitle="TODO: list and manage projects" />
      <EmptyState title="No projects yet" description="Create your first project when the backend is connected." />
    </div>
  );
}
