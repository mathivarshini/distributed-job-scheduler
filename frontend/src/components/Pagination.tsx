interface PaginationProps {
  page: number;
  totalPages: number;
}

export default function Pagination({ page, totalPages }: PaginationProps) {
  return (
    <div className="mt-4 flex items-center justify-between text-sm text-slate-400">
      <span>Page {page} of {totalPages}</span>
      <div className="flex gap-2">
        <button className="rounded border border-slate-700 px-3 py-1 hover:bg-slate-800">Previous</button>
        <button className="rounded border border-slate-700 px-3 py-1 hover:bg-slate-800">Next</button>
      </div>
    </div>
  );
}
