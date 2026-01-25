import { create } from 'zustand';
import { persist } from 'zustand/middleware';

interface User {
  id: string;
  email: string;
  name: string;
  workspaceId: string;
  role: 'admin' | 'member';
}

interface AuthState {
  user: User | null;
  token: string | null;
  isAuthenticated: boolean;
  login: (email: string, password: string) => Promise<void>;
  logout: () => void;
  signup: (email: string, password: string, name: string) => Promise<void>;
}

export const useAuthStore = create<AuthState>()(
  persist(
    (set) => ({
      user: null,
      token: null,
      isAuthenticated: false,

      login: async (email: string, password: string) => {
        // TODO: Replace with actual API call
        const mockUser: User = {
          id: '1',
          email,
          name: email.split('@')[0],
          workspaceId: 'default-workspace',
          role: 'admin',
        };

        const mockToken = 'mock-jwt-token';

        set({
          user: mockUser,
          token: mockToken,
          isAuthenticated: true,
        });
      },

      logout: () => {
        set({
          user: null,
          token: null,
          isAuthenticated: false,
        });
      },

      signup: async (email: string, password: string, name: string) => {
        // TODO: Replace with actual API call
        const mockUser: User = {
          id: '1',
          email,
          name,
          workspaceId: 'default-workspace',
          role: 'admin',
        };

        const mockToken = 'mock-jwt-token';

        set({
          user: mockUser,
          token: mockToken,
          isAuthenticated: true,
        });
      },
    }),
    {
      name: 'auth-storage',
    }
  )
);
