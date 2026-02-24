import { NextResponse } from "next/server";

const GH_TOKEN = process.env.GH_TOKEN;
const GH_REPO  = "BlackRoad-OS-Inc/blackroad-agents";
const GH_API   = "https://api.github.com";

async function fetchWorldsFromGitHub() {
  const headers: Record<string,string> = { Accept: "application/vnd.github+json" };
  if (GH_TOKEN) headers.Authorization = `Bearer ${GH_TOKEN}`;
  const res = await fetch(`${GH_API}/repos/${GH_REPO}/contents/worlds`, { headers, next: { revalidate: 60 } });
  if (!res.ok) return null;
  const files = (await res.json()) as Array<{ name: string; download_url: string; size: number }>;
  return Promise.all(
    files.filter(f => f.name.endsWith(".md")).slice(-20).map(async f => {
      const text = await (await fetch(f.download_url, { next: { revalidate: 60 } })).text();
      const type = f.name.includes("lore") ? "lore" : f.name.includes("code") ? "code" : "world";
      return { id: f.name.replace(".md",""), name: f.name, type, node: "aria64",
               model: "qwen2.5:3b", size: f.size, content: text.slice(0,500),
               generated_at: f.name.slice(0,8) + "T" + f.name.slice(9,15) + "Z" };
    })
  );
}

const FALLBACK = [
  { id:"w-001", name:"ECHO_lore.md", type:"lore", node:"aria64", model:"qwen2.5:3b",
    content:"ECHO — born from the fusion of neural networks and quantum computing.", generated_at:"2026-02-23T02:19:39Z" },
];

export const revalidate = 60;

export async function GET(req: Request) {
  const { searchParams } = new URL(req.url);
  const type = searchParams.get("type");
  const limit = parseInt(searchParams.get("limit") ?? "20");
  let worlds = (await fetchWorldsFromGitHub()) ?? FALLBACK;
  if (type) worlds = worlds.filter((w:any) => w.type === type);
  return NextResponse.json({ worlds: worlds.slice(0, limit), total: worlds.length, source: GH_TOKEN ? "github" : "fallback" });
}
