"use client";
import { useState } from "react";
import { useTasks } from "@blackroad/sdk";

interface Task {
  id: string;
  title: string;
  description: string;
  status: "available" | "claimed" | "completed" | "failed";
  priority: "low" | "medium" | "high" | "critical";
  agent?: string;
  posted_at: string;
  completed_at?: string;
}

const PRIORITY_COLOR: Record<string, string> = {
  critical: "bg-red-900 text-red-300", high: "bg-orange-900 text-orange-300",
  medium: "bg-yellow-900 text-yellow-300", low: "bg-zinc-800 text-zinc-400",
};
const COLUMNS: Array<{ key: Task["status"]; label: string; color: string }> = [
  { key: "available", label: "Available", color: "border-blue-700" },
  { key: "claimed",   label: "In Progress", color: "border-yellow-600" },
  { key: "completed", label: "Completed", color: "border-green-700" },
];

export default function TasksPage() {
  const { tasks, loading, error, post, claim, complete } = useTasks();
  const [showNew, setShowNew] = useState(false);
  const [form, setForm] = useState({ title: "", description: "", priority: "medium" });

  const handlePost = async (e: React.FormEvent) => {
    e.preventDefault();
    await post(form.title, form.description, form.priority as Task["priority"]);
    setForm({ title: "", description: "", priority: "medium" });
    setShowNew(false);
  };

  const byStatus = (status: Task["status"]) =>
    tasks.filter((t: Task) => t.status === status);

  return (
    <div className="p-6 space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-white">Task Marketplace</h1>
          <p className="text-sm text-zinc-400 mt-1">{tasks.length} total tasks across all agents</p>
        </div>
        <button onClick={() => setShowNew(!showNew)} className="bg-violet-600 hover:bg-violet-500 text-white text-sm px-4 py-2 rounded-lg font-medium">
          + New Task
        </button>
      </div>

      {showNew && (
        <form onSubmit={handlePost} className="bg-zinc-900 border border-zinc-700 rounded-xl p-5 space-y-3">
          <h2 className="text-sm font-semibold text-zinc-300">Post New Task</h2>
          <input
            value={form.title} onChange={(e) => setForm({ ...form, title: e.target.value })}
            placeholder="Task title" required
            className="w-full bg-zinc-800 border border-zinc-700 rounded-lg px-3 py-2 text-sm text-white"
          />
          <textarea
            value={form.description} onChange={(e) => setForm({ ...form, description: e.target.value })}
            placeholder="Description" rows={2}
            className="w-full bg-zinc-800 border border-zinc-700 rounded-lg px-3 py-2 text-sm text-white resize-none"
          />
          <div className="flex gap-3">
            <select value={form.priority} onChange={(e) => setForm({ ...form, priority: e.target.value })}
              className="bg-zinc-800 border border-zinc-700 rounded-lg px-3 py-2 text-sm text-white">
              <option value="low">Low</option><option value="medium">Medium</option>
              <option value="high">High</option><option value="critical">Critical</option>
            </select>
            <button type="submit" className="ml-auto bg-violet-600 text-white text-sm px-4 py-2 rounded-lg">Post Task</button>
          </div>
        </form>
      )}

      {loading && <p className="text-zinc-500 text-sm">Loading tasks...</p>}
      {error && <p className="text-red-400 text-sm">{error}</p>}

      <div className="grid grid-cols-3 gap-4">
        {COLUMNS.map(({ key, label, color }) => (
          <div key={key} className={`border-t-2 ${color} pt-3`}>
            <div className="flex items-center justify-between mb-3">
              <h3 className="text-sm font-semibold text-zinc-300">{label}</h3>
              <span className="text-xs text-zinc-500 bg-zinc-800 px-2 py-0.5 rounded-full">
                {byStatus(key).length}
              </span>
            </div>
            <div className="space-y-2">
              {byStatus(key).map((task: Task) => (
                <div key={task.id} className="bg-zinc-900 border border-zinc-800 rounded-xl p-3 space-y-2">
                  <p className="text-white text-sm font-medium">{task.title}</p>
                  {task.description && <p className="text-zinc-500 text-xs line-clamp-2">{task.description}</p>}
                  <div className="flex items-center justify-between">
                    <span className={`text-xs px-2 py-0.5 rounded-full font-medium ${PRIORITY_COLOR[task.priority]}`}>
                      {task.priority}
                    </span>
                    {task.agent && <span className="text-xs text-violet-400 font-mono">{task.agent}</span>}
                  </div>
                  {key === "available" && (
                    <button onClick={() => claim(task.id)} className="w-full text-xs bg-zinc-800 hover:bg-zinc-700 text-zinc-300 py-1 rounded-lg">
                      Claim
                    </button>
                  )}
                  {key === "claimed" && (
                    <button onClick={() => complete(task.id, "Completed via dashboard")} className="w-full text-xs bg-green-900 hover:bg-green-800 text-green-300 py-1 rounded-lg">
                      Mark Complete
                    </button>
                  )}
                </div>
              ))}
              {byStatus(key).length === 0 && (
                <p className="text-zinc-600 text-xs text-center py-4">No tasks</p>
              )}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
