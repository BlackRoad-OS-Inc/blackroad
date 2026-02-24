import Link from "next/link";

async function getStats() {
  try {
    const base = process.env.BLACKROAD_GATEWAY_URL || "http://127.0.0.1:8787";
    const [health, agentsRes, tasksRes, memRes] = await Promise.allSettled([
      fetch(`${base}/health`, { cache: "no-store" }).then(r => r.json()),
      fetch(`${base}/agents`, { cache: "no-store" }).then(r => r.json()),
      fetch(`${base}/tasks`, { cache: "no-store" }).then(r => r.json()),
      fetch(`${base}/memory?limit=1`, { cache: "no-store" }).then(r => r.json()),
    ]);
    return {
      gateway: health.status === "fulfilled" ? "online" : "offline",
      agents: agentsRes.status === "fulfilled" ? (agentsRes.value as Record<string, unknown[]>).agents?.length ?? 0 : 0,
      online: agentsRes.status === "fulfilled" ? ((agentsRes.value as Record<string, {status:string}[]>).agents || []).filter(a => a.status === "online").length : 0,
      tasks: tasksRes.status === "fulfilled" ? (tasksRes.value as Record<string, unknown[]>).tasks?.length ?? 0 : 0,
      memory: memRes.status === "fulfilled" ? (memRes.value as Record<string, number>).total ?? 0 : 0,
    };
  } catch {
    return { gateway: "offline", agents: 0, online: 0, tasks: 0, memory: 0 };
  }
}

const CARDS = [
  { href: "/agents", icon: "◈", label: "Agents", desc: "Fleet status and capabilities", color: "from-red-950 to-red-900/50 border-red-900" },
  { href: "/tasks", icon: "◉", label: "Tasks", desc: "Post and claim work items", color: "from-blue-950 to-blue-900/50 border-blue-900" },
  { href: "/memory", icon: "◫", label: "Memory", desc: "PS-SHA∞ chain viewer", color: "from-purple-950 to-purple-900/50 border-purple-900" },
  { href: "/chat", icon: "◎", label: "Chat", desc: "Talk to agent personas", color: "from-green-950 to-green-900/50 border-green-900" },
];

export default async function DashboardPage() {
  const stats = await getStats();

  const statItems = [
    { label: "Gateway", value: stats.gateway === "online" ? "Online" : "Offline", color: stats.gateway === "online" ? "text-green-400" : "text-red-400" },
    { label: "Agents Online", value: stats.online.toLocaleString(), color: "text-blue-400" },
    { label: "Active Tasks", value: stats.tasks.toLocaleString(), color: "text-yellow-400" },
    { label: "Memories", value: stats.memory.toLocaleString(), color: "text-purple-400" },
  ];

  return (
    <div className="min-h-screen bg-black text-white p-8">
      {/* Header */}
      <div className="mb-10">
        <h1 className="text-4xl font-bold mb-2">
          BlackRoad{" "}
          <span
            style={{
              background:
                "linear-gradient(135deg, #F5A623 0%, #FF1D6C 38.2%, #9C27B0 61.8%, #2979FF 100%)",
              WebkitBackgroundClip: "text",
              WebkitTextFillColor: "transparent",
            }}
          >
            OS
          </span>
        </h1>
        <p className="text-slate-400 text-lg">Your AI. Your Hardware. Your Rules.</p>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-4 gap-4 mb-10">
        {statItems.map(({ label, value, color }) => (
          <div
            key={label}
            className="bg-slate-900 rounded-xl p-5 border border-slate-800"
          >
            <div className={`text-2xl font-bold ${color}`}>{value}</div>
            <div className="text-sm text-slate-500 mt-1">{label}</div>
          </div>
        ))}
      </div>

      {/* Nav cards */}
      <div className="grid grid-cols-2 gap-4 mb-10">
        {CARDS.map(({ href, icon, label, desc, color }) => (
          <Link
            key={href}
            href={href}
            className={`bg-gradient-to-br ${color} border rounded-xl p-6 hover:scale-[1.02] transition-transform`}
          >
            <div className="text-3xl mb-3">{icon}</div>
            <div className="font-bold text-lg mb-1">{label}</div>
            <div className="text-sm text-slate-400">{desc}</div>
          </Link>
        ))}
      </div>

      {/* Fleet identity */}
      <div className="bg-slate-900 rounded-xl p-6 border border-slate-800">
        <h2 className="font-bold text-lg mb-4">Core Agent Fleet</h2>
        <div className="grid grid-cols-6 gap-3">
          {[
            { name: "LUCIDIA", role: "Philosopher", color: "text-red-400", dot: "bg-red-400" },
            { name: "ALICE", role: "Executor", color: "text-green-400", dot: "bg-green-400" },
            { name: "OCTAVIA", role: "Operator", color: "text-purple-400", dot: "bg-purple-400" },
            { name: "PRISM", role: "Analyst", color: "text-yellow-400", dot: "bg-yellow-400" },
            { name: "ECHO", role: "Librarian", color: "text-blue-400", dot: "bg-blue-400" },
            { name: "CIPHER", role: "Guardian", color: "text-slate-300", dot: "bg-slate-300" },
          ].map(({ name, role, color, dot }) => (
            <div key={name} className="text-center">
              <div className={`w-2 h-2 rounded-full ${dot} mx-auto mb-2`} />
              <div className={`font-semibold text-sm ${color}`}>{name}</div>
              <div className="text-xs text-slate-500">{role}</div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
