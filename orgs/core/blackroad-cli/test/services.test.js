import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import {
  services,
  getAllServices,
  getServiceBySlug,
  getRailwayServices,
  dashboards,
} from '../lib/services.js';

describe('services registry', () => {
  describe('services object', () => {
    it('has all four categories', () => {
      assert.ok(services.core);
      assert.ok(services.infrastructure);
      assert.ok(services.services);
      assert.ok(services.web);
    });

    it('each service has required fields', () => {
      const all = getAllServices();
      for (const svc of all) {
        assert.ok(svc.name, `service missing name: ${JSON.stringify(svc)}`);
        assert.ok(svc.slug, `service missing slug: ${JSON.stringify(svc)}`);
        assert.ok(svc.url, `service missing url: ${JSON.stringify(svc)}`);
        assert.equal(typeof svc.railway, 'boolean', `railway should be boolean for ${svc.slug}`);
      }
    });

    it('slugs are unique', () => {
      const all = getAllServices();
      const slugs = all.map((s) => s.slug);
      const unique = new Set(slugs);
      assert.equal(slugs.length, unique.size, 'duplicate slugs found');
    });
  });

  describe('getAllServices()', () => {
    it('returns all services from every category', () => {
      const all = getAllServices();
      const expected =
        services.core.length +
        services.infrastructure.length +
        services.services.length +
        services.web.length;
      assert.equal(all.length, expected);
    });

    it('returns an array', () => {
      assert.ok(Array.isArray(getAllServices()));
    });
  });

  describe('getServiceBySlug()', () => {
    it('finds a known service', () => {
      const svc = getServiceBySlug('api');
      assert.ok(svc);
      assert.equal(svc.slug, 'api');
      assert.equal(svc.name, 'API');
    });

    it('returns undefined for unknown slug', () => {
      const svc = getServiceBySlug('nonexistent-service');
      assert.equal(svc, undefined);
    });

    it('finds services from different categories', () => {
      assert.ok(getServiceBySlug('blackroad')); // core
      assert.ok(getServiceBySlug('api-gateway')); // infrastructure
      assert.ok(getServiceBySlug('agents')); // services
      assert.ok(getServiceBySlug('docs')); // web
    });
  });

  describe('getRailwayServices()', () => {
    it('returns only railway-deployed services', () => {
      const rw = getRailwayServices();
      assert.ok(rw.length > 0);
      assert.ok(rw.every((s) => s.railway === true));
    });

    it('excludes non-railway services', () => {
      const rw = getRailwayServices();
      const all = getAllServices();
      const nonRailway = all.filter((s) => !s.railway);
      assert.ok(nonRailway.length > 0, 'should have some non-railway services');
      for (const svc of nonRailway) {
        assert.ok(
          !rw.find((r) => r.slug === svc.slug),
          `${svc.slug} should not be in railway services`
        );
      }
    });
  });

  describe('dashboards', () => {
    it('has all expected dashboard URLs', () => {
      assert.ok(dashboards.railway);
      assert.ok(dashboards.cloudflare);
      assert.ok(dashboards.github);
      assert.ok(dashboards.status);
      assert.ok(dashboards.actions);
    });

    it('URLs are valid HTTPS', () => {
      for (const [key, url] of Object.entries(dashboards)) {
        assert.ok(url.startsWith('https://'), `${key} dashboard URL should be HTTPS`);
      }
    });
  });
});
