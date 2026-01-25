import axios, { AxiosInstance } from 'axios';
import { loadConfig } from './config';

let apiClient: AxiosInstance | null = null;

export async function getApiClient(): Promise<AxiosInstance> {
  if (apiClient) return apiClient;

  const config = await loadConfig();

  apiClient = axios.create({
    baseURL: config.apiUrl,
    headers: {
      'Content-Type': 'application/json',
      ...(config.apiKey && { Authorization: `Bearer ${config.apiKey}` }),
    },
  });

  return apiClient;
}

export function resetApiClient() {
  apiClient = null;
}
