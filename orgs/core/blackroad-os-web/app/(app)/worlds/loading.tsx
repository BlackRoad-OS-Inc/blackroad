export default function Loading() {
  return (
    <div className="animate-pulse space-y-4 p-6">
      <div className="h-8 bg-gray-200 rounded w-48" />
      <div className="h-32 bg-gray-200 rounded" />
      <div className="space-y-2">
        {[...Array(5)].map((_, i) => (
          <div key={i} className="h-6 bg-gray-200 rounded" />
        ))}
      </div>
    </div>
  )
}
