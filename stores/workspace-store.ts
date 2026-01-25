import { create } from 'zustand';

interface Workspace {
  id: string;
  name: string;
  plan: 'free' | 'pro' | 'enterprise';
  memberCount: number;
}

interface WorkspaceState {
  currentWorkspace: Workspace | null;
  workspaces: Workspace[];
  setCurrentWorkspace: (workspace: Workspace) => void;
  fetchWorkspaces: () => Promise<void>;
}

export const useWorkspaceStore = create<WorkspaceState>((set) => ({
  currentWorkspace: null,
  workspaces: [],

  setCurrentWorkspace: (workspace) => {
    set({ currentWorkspace: workspace });
  },

  fetchWorkspaces: async () => {
    // TODO: Replace with actual API call
    const mockWorkspaces: Workspace[] = [
      {
        id: 'default-workspace',
        name: 'My Workspace',
        plan: 'pro',
        memberCount: 1,
      },
    ];

    set({
      workspaces: mockWorkspaces,
      currentWorkspace: mockWorkspaces[0],
    });
  },
}));
