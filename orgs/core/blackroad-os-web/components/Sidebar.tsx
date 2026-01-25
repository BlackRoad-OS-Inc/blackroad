'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import {
  MessageSquare,
  Bot,
  Shield,
  Settings,
  Plus,
  LogOut,
  LayoutDashboard,
  Activity
} from 'lucide-react';
import { useAuthStore } from '@/stores/auth-store';
import { useWorkspaceStore } from '@/stores/workspace-store';
import { cn } from '@/lib/cn';

export default function Sidebar() {
  const pathname = usePathname();
  const logout = useAuthStore((state) => state.logout);
  const currentWorkspace = useWorkspaceStore((state) => state.currentWorkspace);

  const navigation = [
    {
      name: 'Dashboard',
      href: '/workspace',
      icon: LayoutDashboard,
    },
    {
      name: 'Conversations',
      href: '/conversations',
      icon: MessageSquare,
    },
    {
      name: 'Agents',
      href: '/agents',
      icon: Bot,
    },
    {
      name: 'Monitoring',
      href: '/monitoring',
      icon: Activity,
    },
    {
      name: 'Governance',
      href: '/governance',
      icon: Shield,
    },
    {
      name: 'Settings',
      href: '/settings',
      icon: Settings,
    },
  ];

  return (
    <div className="flex h-screen w-64 flex-col bg-black border-r border-white/10">
      {/* Logo & Workspace header */}
      <div className="p-5 border-b border-white/10">
        <Link href="/" className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-amber-500 via-[#FF1D6C] to-violet-600 flex items-center justify-center">
            <span className="text-white font-bold text-lg">B</span>
          </div>
          <div>
            <h1 className="text-lg font-semibold text-white">
              BlackRoad<span className="bg-gradient-to-r from-[#FF1D6C] to-[#2979FF] bg-clip-text text-transparent"> OS</span>
            </h1>
            <p className="text-xs text-gray-500">
              {currentWorkspace?.name || 'Workspace'}
            </p>
          </div>
        </Link>
      </div>

      {/* New conversation button */}
      <div className="p-4">
        <Link
          href="/workspace?new=true"
          className="group flex items-center justify-center gap-2 w-full px-4 py-3 bg-gradient-to-r from-[#FF1D6C] to-violet-600 hover:from-[#FF1D6C]/90 hover:to-violet-600/90 rounded-xl text-sm font-medium transition-all hover:shadow-lg hover:shadow-[#FF1D6C]/25"
        >
          <Plus className="h-4 w-4" />
          New Conversation
        </Link>
      </div>

      {/* Navigation */}
      <nav className="flex-1 px-3 space-y-1 overflow-y-auto">
        {navigation.map((item) => {
          const isActive = pathname === item.href || pathname.startsWith(item.href + '/');
          return (
            <Link
              key={item.name}
              href={item.href}
              className={cn(
                'flex items-center gap-3 px-4 py-3 rounded-xl text-sm font-medium transition-all',
                isActive
                  ? 'bg-white/10 text-white'
                  : 'text-gray-400 hover:bg-white/5 hover:text-white'
              )}
            >
              <item.icon className={cn(
                'h-5 w-5 transition-colors',
                isActive ? 'text-[#FF1D6C]' : ''
              )} />
              {item.name}
              {isActive && (
                <div className="ml-auto w-1.5 h-1.5 rounded-full bg-[#FF1D6C]" />
              )}
            </Link>
          );
        })}
      </nav>

      {/* User footer */}
      <div className="border-t border-white/10 p-4">
        <button
          onClick={logout}
          className="flex items-center gap-3 px-4 py-3 w-full rounded-xl text-sm font-medium text-gray-400 hover:bg-white/5 hover:text-white transition-all"
        >
          <LogOut className="h-5 w-5" />
          Sign out
        </button>
      </div>
    </div>
  );
}
