interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'secondary';
}

export default function Button({ variant = 'primary', className = '', ...props }: ButtonProps) {
  const base = 'rounded-lg px-4 py-2 text-sm font-medium transition';
  const styles =
    variant === 'primary'
      ? 'bg-cyan-500 text-white hover:bg-cyan-600'
      : 'border border-slate-700 bg-slate-900 text-slate-200 hover:bg-slate-800';

  return <button className={`${base} ${styles} ${className}`} {...props} />;
}
