export default function StudioLoading() {
  return (
    <div className="p-6 space-y-8 animate-pulse">
      <div>
        <div className="h-8 w-24 bg-gray-200 rounded" />
        <div className="h-4 w-64 bg-gray-100 rounded mt-2" />
      </div>
      <div className="rounded-2xl h-24 bg-gray-200" />
      <div className="space-y-2">
        {[...Array(6)].map((_, i) => (
          <div key={i} className="h-12 bg-gray-100 rounded-xl" />
        ))}
      </div>
    </div>
  )
}
