'use client';

import { Bell, Search, ChevronDown } from 'lucide-react';
import { useAuthStore } from '@/stores/auth-store';
import { useWorkspaceStore } from '@/stores/workspace-store';

export default function AppHeader() {
  const user = useAuthStore((state) => state.user);
  const currentWorkspace = useWorkspaceStore((state) => state.currentWorkspace);

  return (
    <header className="sticky top-0 z-10 border-b border-white/10 bg-black/80 backdrop-blur-xl">
      <div className="flex h-16 items-center justify-between px-6">
        {/* Page title & workspace info */}
        <div>
          <h2 className="text-lg font-semibold text-white">
            {currentWorkspace?.name || 'Dashboard'}
          </h2>
          <p className="text-sm text-gray-500">
            <span className="inline-flex items-center gap-1.5">
              <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse" />
              {currentWorkspace?.plan?.toUpperCase() || 'FREE'} Plan
            </span>
          </p>
        </div>

        {/* Search bar */}
        <div className="hidden md:flex flex-1 max-w-md mx-8">
          <div className="relative w-full">
            <Search className="absolute left-4 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-500" />
            <input
              type="text"
              placeholder="Search agents, conversations..."
              className="w-full pl-11 pr-4 py-2.5 bg-white/5 border border-white/10 rounded-xl text-sm text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-[#FF1D6C]/50 focus:border-transparent transition-all"
            />
            <kbd className="absolute right-4 top-1/2 -translate-y-1/2 hidden sm:inline-flex items-center gap-1 px-2 py-1 text-xs text-gray-500 bg-white/5 rounded border border-white/10">
              ⌘K
            </kbd>
          </div>
        </div>

        {/* Right side actions */}
        <div className="flex items-center gap-4">
          {/* Notifications */}
          <button className="relative p-2.5 rounded-xl bg-white/5 hover:bg-white/10 transition-colors">
            <Bell className="h-5 w-5 text-gray-400" />
            <span className="absolute top-1.5 right-1.5 w-2 h-2 rounded-full bg-[#FF1D6C]" />
          </button>

          {/* User menu */}
          <button className="flex items-center gap-3 px-3 py-2 rounded-xl hover:bg-white/5 transition-colors">
            <div className="h-9 w-9 rounded-xl bg-gradient-to-br from-[#FF1D6C] to-violet-600 flex items-center justify-center text-white text-sm font-semibold">
              {user?.name?.[0]?.toUpperCase() || 'U'}
            </div>
            <div className="hidden sm:block text-left">
              <p className="text-sm font-medium text-white">{user?.name || 'User'}</p>
              <p className="text-xs text-gray-500">{user?.email || 'user@example.com'}</p>
            </div>
            <ChevronDown className="h-4 w-4 text-gray-500 hidden sm:block" />
          </button>
        </div>
      </div>
    </header>
  );
}
