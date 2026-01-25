export default function Home() {
  return (
    <main className="min-h-screen p-8">
      <h1 className="text-4xl font-bold mb-8">
        🌌 BlackRoad Ecosystem Dashboard
      </h1>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div className="p-6 border rounded-lg">
          <h2 className="text-2xl font-semibold">15</h2>
          <p className="text-gray-600">Organizations</p>
        </div>

        <div className="p-6 border rounded-lg">
          <h2 className="text-2xl font-semibold">113+</h2>
          <p className="text-gray-600">Repositories</p>
        </div>

        <div className="p-6 border rounded-lg">
          <h2 className="text-2xl font-semibold">17,681+</h2>
          <p className="text-gray-600">Files</p>
        </div>
      </div>

      <div className="mt-8">
        <h2 className="text-2xl font-bold mb-4">Organization Status</h2>
        <div className="space-y-2">
          <div className="p-4 border rounded flex justify-between items-center">
            <span>BlackRoad-OS</span>
            <span className="text-green-600">✅ 77 repos</span>
          </div>
          <div className="p-4 border rounded flex justify-between items-center">
            <span>BlackRoad-AI</span>
            <span className="text-green-600">✅ 3 repos</span>
          </div>
          <div className="p-4 border rounded flex justify-between items-center">
            <span>BlackRoad-Cloud</span>
            <span className="text-green-600">✅ 3 repos</span>
          </div>
        </div>
      </div>
    </main>
  )
}
