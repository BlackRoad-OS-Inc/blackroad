import { Palette, Type, Layers } from 'lucide-react'

// Server component that fetches from studio.blackroad.io/brand
async function getBrandData() {
  try {
    const resp = await fetch('https://studio.blackroad.io/brand', { next: { revalidate: 3600 } })
    if (resp.ok) return (await resp.json()).brand
  } catch {}
  return null
}

export default async function StudioPage() {
  const brand = await getBrandData()

  const colors = [
    { name: 'Black', hex: '#000000', cls: 'bg-black' },
    { name: 'White', hex: '#FFFFFF', cls: 'bg-white border' },
    { name: 'Amber', hex: '#F5A623', cls: 'bg-amber-400' },
    { name: 'Hot Pink', hex: '#FF1D6C', cls: 'bg-pink-500' },
    { name: 'Electric Blue', hex: '#2979FF', cls: 'bg-blue-500' },
    { name: 'Violet', hex: '#9C27B0', cls: 'bg-purple-600' },
  ]

  const spacings = [
    { name: 'xs', value: '8px', ratio: '1' },
    { name: 'sm', value: '13px', ratio: 'φ¹' },
    { name: 'md', value: '21px', ratio: 'φ²' },
    { name: 'lg', value: '34px', ratio: 'φ³' },
    { name: 'xl', value: '55px', ratio: 'φ⁴' },
  ]

  return (
    <div className="p-6 space-y-8">
      <div>
        <h1 className="text-2xl font-bold">Studio</h1>
        <p className="text-gray-500 text-sm mt-1">BlackRoad OS Design System — Brand guidelines &amp; components</p>
      </div>

      {/* Brand Gradient */}
      <div
        className="rounded-2xl overflow-hidden h-24"
        style={{ background: 'linear-gradient(135deg, #F5A623 0%, #FF1D6C 38.2%, #9C27B0 61.8%, #2979FF 100%)' }}
      />

      {/* Colors */}
      <section>
        <h2 className="font-semibold mb-3 flex items-center gap-2">
          <Palette className="w-4 h-4" /> Brand Colors
        </h2>
        <div className="grid grid-cols-3 sm:grid-cols-6 gap-3">
          {colors.map((c) => (
            <div key={c.name} className="text-center">
              <div className={`${c.cls} w-full aspect-square rounded-xl mb-2`} />
              <div className="text-xs font-medium">{c.name}</div>
              <div className="text-xs text-gray-400 font-mono">{c.hex}</div>
            </div>
          ))}
        </div>
      </section>

      {/* Spacing */}
      <section>
        <h2 className="font-semibold mb-3 flex items-center gap-2">
          <Layers className="w-4 h-4" /> Spacing — Golden Ratio (φ = 1.618)
        </h2>
        <div className="space-y-2">
          {spacings.map((s) => (
            <div key={s.name} className="flex items-center gap-4">
              <span className="text-sm font-mono w-8 text-gray-500">{s.name}</span>
              <div className="bg-pink-500 rounded" style={{ width: s.value, height: '20px' }} />
              <span className="text-sm text-gray-600">{s.value}</span>
              <span className="text-xs text-gray-400 ml-auto">{s.ratio}</span>
            </div>
          ))}
        </div>
      </section>

      {/* Typography */}
      <section>
        <h2 className="font-semibold mb-3 flex items-center gap-2">
          <Type className="w-4 h-4" /> Typography
        </h2>
        <div className="space-y-3 bg-gray-50 rounded-xl p-4">
          {(
            [
              ['3xl', '2rem', 'Display'],
              ['2xl', '1.618rem', 'Heading'],
              ['xl', '1.25rem', 'Subheading'],
              ['base', '1rem', 'Body'],
              ['sm', '0.875rem', 'Caption'],
            ] as [string, string, string][]
          ).map(([size, val, label]) => (
            <div key={size} className="flex items-baseline gap-4">
              <span className="text-xs text-gray-400 w-16 font-mono">
                {size} / {val}
              </span>
              <span style={{ fontSize: val, lineHeight: 1.618 }} className="font-semibold">
                {label} — BlackRoad OS
              </span>
            </div>
          ))}
        </div>
      </section>

      {/* CSS Variables */}
      <section>
        <h2 className="font-semibold mb-3">CSS Variables</h2>
        <div className="bg-gray-900 text-green-400 rounded-xl p-4 text-xs font-mono overflow-x-auto">
          <pre>{`@import url('https://studio.blackroad.io/css-vars');

/* Then use: */
color: var(--hot-pink);
background: var(--gradient-brand);
padding: var(--space-md);`}</pre>
        </div>
      </section>
    </div>
  )
}
