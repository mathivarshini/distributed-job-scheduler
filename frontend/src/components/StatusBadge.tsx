interface StatusBadgeProps {
  status: string;
}

export default function StatusBadge({ status }: StatusBadgeProps) {
  const styles = {
    running: 'bg-emerald-500/15 text-emerald-400',
    queued: 'bg-cyan-500/15 text-cyan-400',
    failed: 'bg-rose-500/15 text-rose-400',
    paused: 'bg-amber-500/15 text-amber-400',
  } as Record<string, string>;

  return (
    <span className={`rounded-full px-2.5 py-1 text-xs font-medium ${styles[status] ?? 'bg-slate-800 text-slate-300'}`}>
      {status}
    </span>
  );
}
