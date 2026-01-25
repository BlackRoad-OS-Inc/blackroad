import assert from 'node:assert/strict';
import test from 'node:test';

import { ModuleLoader } from '../module-loader.js';

test('buildDependencyGraph maps dependencies and dependents', () => {
    const loader = new ModuleLoader();
    const configs = [
        { name: 'a', deps: [] },
        { name: 'b', deps: ['a'] },
        { name: 'c', deps: ['b'] },
        { name: 'wild', deps: ['*'] }
    ];

    const graph = loader.buildDependencyGraph(configs);

    assert.deepEqual(graph.get('b').deps, ['a']);
    assert.deepEqual(graph.get('a').dependents, ['b']);
    assert.deepEqual(graph.get('wild').deps, []);
});

test('topologicalSort orders dependencies before dependents', () => {
    const loader = new ModuleLoader();
    const configs = [
        { name: 'a', deps: [] },
        { name: 'b', deps: ['a'] },
        { name: 'c', deps: ['b'] }
    ];
    const graph = loader.buildDependencyGraph(configs);
    const order = loader.topologicalSort(graph);

    assert.ok(order.includes('a'));
    assert.ok(order.includes('b'));
    assert.ok(order.includes('c'));
    assert.ok(order.indexOf('a') < order.indexOf('b'));
    assert.ok(order.indexOf('b') < order.indexOf('c'));
});

test('topologicalSort throws on cycles', () => {
    const loader = new ModuleLoader();
    const graph = new Map([
        ['a', { deps: ['b'], dependents: [] }],
        ['b', { deps: ['a'], dependents: [] }]
    ]);

    assert.throws(() => loader.topologicalSort(graph), /Circular dependency/);
});

test('loadModule returns module and runs init', async () => {
    const loader = new ModuleLoader();
    const fixtureUrl = new URL('./fixtures/test-module.js', import.meta.url);

    const loadedModule = await loader.loadModule({
        name: 'fixture',
        path: fixtureUrl.href,
        deps: []
    });

    assert.equal(loadedModule.name, 'fixture');
    assert.equal(loadedModule.initialized, true);
});

test('loadModule returns placeholder for missing module', async () => {
    const loader = new ModuleLoader();
    const missingUrl = new URL('./fixtures/does-not-exist.js', import.meta.url);

    const loadedModule = await loader.loadModule({
        name: 'missing',
        path: missingUrl.href,
        deps: []
    });

    assert.equal(loadedModule.placeholder, true);
    assert.equal(loadedModule.name, 'missing');
});
