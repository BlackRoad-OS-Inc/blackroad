import { describe, it, expect } from 'vitest';
import { Router } from '../router';

describe('Router', () => {
  it('registers and dispatches GET routes', async () => {
    const router = new Router();
    router.get('/hello', async () => new Response('world'));

    const req = new Request('https://example.com/hello', { method: 'GET' });
    const res = await router.handle(req, {});
    expect(res).not.toBeNull();
    expect(await res!.text()).toBe('world');
  });

  it('registers and dispatches POST routes', async () => {
    const router = new Router();
    router.post('/submit', async () => new Response('ok'));

    const req = new Request('https://example.com/submit', { method: 'POST' });
    const res = await router.handle(req, {});
    expect(res).not.toBeNull();
    expect(await res!.text()).toBe('ok');
  });

  it('returns null for unregistered routes', async () => {
    const router = new Router();
    const req = new Request('https://example.com/missing', { method: 'GET' });
    const res = await router.handle(req, {});
    expect(res).toBeNull();
  });

  it('distinguishes methods on the same path', async () => {
    const router = new Router();
    router.get('/data', async () => new Response('get-data'));
    router.post('/data', async () => new Response('post-data'));

    const getReq = new Request('https://example.com/data', { method: 'GET' });
    const postReq = new Request('https://example.com/data', { method: 'POST' });

    expect(await (await router.handle(getReq, {}))!.text()).toBe('get-data');
    expect(await (await router.handle(postReq, {}))!.text()).toBe('post-data');
  });
});
