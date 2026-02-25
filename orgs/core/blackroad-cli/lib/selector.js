// BR-CLI Advanced Selector Engine
// Enables powerful target selection for distributed operations

class SelectorEngine {
    constructor(inventory) {
        this.inventory = inventory;
    }

    /**
     * Parse selector expression
     * Examples:
     *   - "role=pi,env=prod"
     *   - "role=pi|role=jetson"
     *   - "tag!=deprecated"
     *   - "percent=5"
     */
    parse(expression) {
        const filters = [];
        let limit = null;
        let percent = null;

        const parts = expression.split(',').map(p => p.trim());

        for (const part of parts) {
            if (part.startsWith('percent=')) {
                percent = parseInt(part.split('=')[1]);
            } else if (part.startsWith('limit=')) {
                limit = parseInt(part.split('=')[1]);
            } else {
                // Parse filter: field operator value
                const orParts = part.split('|');
                const orFilters = orParts.map(p => this.parseFilter(p));
                filters.push(...orFilters);
            }
        }

        return { filters, limit, percent };
    }

    parseFilter(filterStr) {
        let operator = '=';
        let field, value;

        if (filterStr.includes('!=')) {
            [field, value] = filterStr.split('!=');
            operator = '!=';
        } else if (filterStr.includes('=')) {
            [field, value] = filterStr.split('=');
            operator = '=';
        }

        return {
            field: field.trim(),
            operator,
            value: value.trim()
        };
    }

    /**
     * Resolve selector against inventory
     */
    resolve(expression) {
        const { filters, limit, percent } = this.parse(expression);
        
        let results = this.inventory.nodes || [];

        // Apply filters
        for (const filter of filters) {
            results = results.filter(node => this.matchFilter(node, filter));
        }

        // Apply percentage sampling (stable hash-based)
        if (percent) {
            const targetCount = Math.ceil(results.length * percent / 100);
            results = this.stableSample(results, targetCount);
        }

        // Apply limit
        if (limit) {
            results = results.slice(0, limit);
        }

        return results;
    }

    matchFilter(node, filter) {
        const nodeValue = node[filter.field];
        
        switch (filter.operator) {
            case '=':
                return nodeValue === filter.value;
            case '!=':
                return nodeValue !== filter.value;
            default:
                return false;
        }
    }

    stableSample(items, count) {
        // Use hash-based stable sampling
        const hashed = items.map(item => ({
            item,
            hash: this.simpleHash(JSON.stringify(item))
        }));
        
        hashed.sort((a, b) => a.hash - b.hash);
        return hashed.slice(0, count).map(h => h.item);
    }

    simpleHash(str) {
        let hash = 0;
        for (let i = 0; i < str.length; i++) {
            const char = str.charCodeAt(i);
            hash = ((hash << 5) - hash) + char;
            hash = hash & hash;
        }
        return Math.abs(hash);
    }
}

export default SelectorEngine;
