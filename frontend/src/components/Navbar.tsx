export default function Navbar() {
  return (
    <header className="border-b border-slate-800 bg-slate-900/80 px-6 py-4">
      <div className="flex items-center justify-between">
        <div>
          <p className="text-xl font-semibold">Distributed Job Scheduler</p>
          <p className="text-sm text-slate-400">Operations Console</p>
        </div>
        <div className="text-sm text-slate-400">TODO: user menu</div>
      </div>
    </header>
  );
}
