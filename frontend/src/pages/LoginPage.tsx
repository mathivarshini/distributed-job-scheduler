import Header from '../components/Header';

export default function LoginPage() {
  return (
    <div className="min-h-screen bg-slate-950 p-8 text-slate-100">
      <div className="mx-auto max-w-xl rounded-2xl border border-slate-800 bg-slate-900 p-8">
        <Header title="Login" subtitle="TODO: auth form and validation" />
      </div>
    </div>
  );
}
