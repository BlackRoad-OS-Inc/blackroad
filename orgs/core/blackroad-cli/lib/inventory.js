// BR-CLI Inventory Management System
// Manages nodes, agents, and services registry

import fs from 'fs';
import path from 'path';
import os from 'os';
import yaml from 'js-yaml';

class Inventory {
    constructor() {
        this.inventoryDir = path.join(os.homedir(), '.blackroad', 'inventory');
        this.nodesFile = path.join(this.inventoryDir, 'nodes.yaml');
        this.agentsFile = path.join(this.inventoryDir, 'agents.yaml');
        this.servicesFile = path.join(this.inventoryDir, 'services.yaml');
        
        this.nodes = [];
        this.agents = [];
        this.services = [];
        
        this.ensureInventoryDir();
        this.load();
    }

    ensureInventoryDir() {
        if (!fs.existsSync(this.inventoryDir)) {
            fs.mkdirSync(this.inventoryDir, { recursive: true });
        }
    }

    /**
     * Load inventory from disk
     */
    load() {
        try {
            if (fs.existsSync(this.nodesFile)) {
                const content = fs.readFileSync(this.nodesFile, 'utf-8');
                this.nodes = yaml.load(content) || [];
            }
            
            if (fs.existsSync(this.agentsFile)) {
                const content = fs.readFileSync(this.agentsFile, 'utf-8');
                this.agents = yaml.load(content) || [];
            }
            
            if (fs.existsSync(this.servicesFile)) {
                const content = fs.readFileSync(this.servicesFile, 'utf-8');
                this.services = yaml.load(content) || [];
            }
        } catch (error) {
            console.error('Failed to load inventory:', error.message);
        }
    }

    /**
     * Save inventory to disk
     */
    save() {
        try {
            fs.writeFileSync(this.nodesFile, yaml.dump(this.nodes));
            fs.writeFileSync(this.agentsFile, yaml.dump(this.agents));
            fs.writeFileSync(this.servicesFile, yaml.dump(this.services));
        } catch (error) {
            console.error('Failed to save inventory:', error.message);
        }
    }

    /**
     * Add a node to inventory
     */
    addNode(node) {
        const existing = this.nodes.find(n => n.name === node.name);
        if (existing) {
            Object.assign(existing, node);
        } else {
            this.nodes.push(node);
        }
        this.save();
    }

    /**
     * Remove a node from inventory
     */
    removeNode(name) {
        this.nodes = this.nodes.filter(n => n.name !== name);
        this.save();
    }

    /**
     * Get node by name
     */
    getNode(name) {
        return this.nodes.find(n => n.name === name);
    }

    /**
     * Add an agent to inventory
     */
    addAgent(agent) {
        const existing = this.agents.find(a => a.name === agent.name);
        if (existing) {
            Object.assign(existing, agent);
        } else {
            this.agents.push(agent);
        }
        this.save();
    }

    /**
     * Add a service to inventory
     */
    addService(service) {
        const existing = this.services.find(s => s.name === service.name);
        if (existing) {
            Object.assign(existing, service);
        } else {
            this.services.push(service);
        }
        this.save();
    }

    /**
     * Auto-discover nodes on network
     */
    async discover() {
        // Placeholder for network discovery
        console.log('Discovering nodes on network...');
        // Would use nmap, mdns, or other discovery mechanisms
    }

    /**
     * Get inventory summary
     */
    summary() {
        return {
            nodes: this.nodes.length,
            agents: this.agents.length,
            services: this.services.length,
            roles: [...new Set(this.nodes.map(n => n.role))],
            environments: [...new Set(this.nodes.map(n => n.env))]
        };
    }
}

export default Inventory;
