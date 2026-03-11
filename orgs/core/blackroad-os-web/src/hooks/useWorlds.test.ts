import { renderHook, waitFor, act } from '@testing-library/react';
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { useWorlds } from './useWorlds';

const MOCK_WORLDS = [
  { id: '1', filename: 'earth.json', date: '2026-01-01', type: 'world', name: 'Earth', url: '/worlds/earth' },
  { id: '2', filename: 'lore.md', date: '2026-01-02', type: 'lore', name: 'Origin', url: '/worlds/origin' },
  { id: '3', filename: 'gen.py', date: '2026-01-03', type: 'code', name: 'Generator', url: '/worlds/gen' },
];

describe('useWorlds', () => {
  beforeEach(() => {
    global.fetch = vi.fn();
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  it('fetches worlds on mount', async () => {
    (global.fetch as ReturnType<typeof vi.fn>).mockResolvedValueOnce({
      ok: true,
      json: async () => MOCK_WORLDS,
    });

    const { result } = renderHook(() => useWorlds());
    expect(result.current.loading).toBe(true);

    await waitFor(() => expect(result.current.loading).toBe(false));
    expect(result.current.artifacts).toHaveLength(3);
    expect(result.current.error).toBeNull();
  });

  it('computes counts correctly', async () => {
    (global.fetch as ReturnType<typeof vi.fn>).mockResolvedValueOnce({
      ok: true,
      json: async () => MOCK_WORLDS,
    });

    const { result } = renderHook(() => useWorlds());
    await waitFor(() => expect(result.current.loading).toBe(false));

    expect(result.current.counts).toEqual({
      total: 3,
      world: 1,
      lore: 1,
      code: 1,
    });
  });

  it('filters by type', async () => {
    (global.fetch as ReturnType<typeof vi.fn>).mockResolvedValueOnce({
      ok: true,
      json: async () => MOCK_WORLDS,
    });

    const { result } = renderHook(() => useWorlds({ filter: 'world' }));
    await waitFor(() => expect(result.current.loading).toBe(false));

    expect(result.current.artifacts).toHaveLength(1);
    expect(result.current.artifacts[0].name).toBe('Earth');
  });

  it('handles HTTP errors', async () => {
    (global.fetch as ReturnType<typeof vi.fn>).mockResolvedValueOnce({
      ok: false,
      status: 500,
    });

    const { result } = renderHook(() => useWorlds());
    await waitFor(() => expect(result.current.loading).toBe(false));

    expect(result.current.error).toBe('HTTP 500');
    expect(result.current.artifacts).toHaveLength(0);
  });

  it('handles network errors', async () => {
    (global.fetch as ReturnType<typeof vi.fn>).mockRejectedValueOnce(new Error('Network failure'));

    const { result } = renderHook(() => useWorlds());
    await waitFor(() => expect(result.current.loading).toBe(false));

    expect(result.current.error).toBe('Network failure');
  });

  it('handles data wrapped in { worlds: [...] }', async () => {
    (global.fetch as ReturnType<typeof vi.fn>).mockResolvedValueOnce({
      ok: true,
      json: async () => ({ worlds: MOCK_WORLDS }),
    });

    const { result } = renderHook(() => useWorlds());
    await waitFor(() => expect(result.current.loading).toBe(false));

    expect(result.current.artifacts).toHaveLength(3);
  });

  it('exposes refresh function', async () => {
    (global.fetch as ReturnType<typeof vi.fn>)
      .mockResolvedValueOnce({ ok: true, json: async () => [] })
      .mockResolvedValueOnce({ ok: true, json: async () => MOCK_WORLDS });

    const { result } = renderHook(() => useWorlds());
    await waitFor(() => expect(result.current.loading).toBe(false));
    expect(result.current.artifacts).toHaveLength(0);

    await act(async () => {
      await result.current.refresh();
    });

    expect(result.current.artifacts).toHaveLength(3);
  });

  it('sets lastFetch date after successful fetch', async () => {
    (global.fetch as ReturnType<typeof vi.fn>).mockResolvedValueOnce({
      ok: true,
      json: async () => MOCK_WORLDS,
    });

    const { result } = renderHook(() => useWorlds());
    await waitFor(() => expect(result.current.loading).toBe(false));

    expect(result.current.lastFetch).toBeInstanceOf(Date);
  });
});
