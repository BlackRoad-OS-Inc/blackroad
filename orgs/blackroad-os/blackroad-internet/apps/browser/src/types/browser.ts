export interface Tab {
  id: string;
  url: string;
  title: string;
  favicon?: string;
  isLoading: boolean;
}

export interface PageInfo {
  url: string;
  title: string;
  is_secure: boolean;
  is_search: boolean;
}

export interface BrowserSettings {
  verification_enabled: boolean;
  sidebar_position: "left" | "right";
  theme: "dark" | "light";
  default_search: string;
}
