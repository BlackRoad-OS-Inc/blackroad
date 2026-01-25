/**
 * CRAFTING & BUILDING SYSTEM
 *
 * Gather resources, craft items, and build anything you can imagine.
 * Complete freedom to create structures, tools, and magical items.
 *
 * Philosophy: "YOU ARE A CREATOR. BUILD YOUR DREAMS INTO REALITY."
 */

import * as THREE from 'three';

// ===== RESOURCE TYPES =====
export const RESOURCES = {
    // Natural Resources
    wood: {
        id: 'wood',
        name: 'Wood',
        description: 'Sturdy timber from trees',
        emoji: '🪵',
        rarity: 'common',
        stackSize: 99,
        gatherable: true,
        sources: ['tree', 'forest']
    },
    stone: {
        id: 'stone',
        name: 'Stone',
        description: 'Solid rock material',
        emoji: '🪨',
        rarity: 'common',
        stackSize: 99,
        gatherable: true,
        sources: ['mountain', 'cave']
    },
    crystal: {
        id: 'crystal',
        name: 'Crystal',
        description: 'Glowing crystal shard',
        emoji: '💎',
        rarity: 'rare',
        stackSize: 50,
        gatherable: true,
        sources: ['crystal_cavern', 'mountain_peak']
    },
    sand: {
        id: 'sand',
        name: 'Sand',
        description: 'Fine desert sand',
        emoji: '⌛',
        rarity: 'common',
        stackSize: 99,
        gatherable: true,
        sources: ['desert', 'beach']
    },
    water: {
        id: 'water',
        name: 'Water',
        description: 'Pure water',
        emoji: '💧',
        rarity: 'common',
        stackSize: 10,
        gatherable: true,
        sources: ['ocean', 'river', 'rain']
    },
    fiber: {
        id: 'fiber',
        name: 'Plant Fiber',
        description: 'Woven plant fibers',
        emoji: '🌾',
        rarity: 'common',
        stackSize: 99,
        gatherable: true,
        sources: ['grass', 'plants']
    },

    // Processed Materials
    plank: {
        id: 'plank',
        name: 'Wood Plank',
        description: 'Processed wooden plank',
        emoji: '📏',
        rarity: 'common',
        stackSize: 99,
        craftable: true
    },
    brick: {
        id: 'brick',
        name: 'Stone Brick',
        description: 'Carved stone brick',
        emoji: '🧱',
        rarity: 'common',
        stackSize: 99,
        craftable: true
    },
    glass: {
        id: 'glass',
        name: 'Glass',
        description: 'Transparent glass pane',
        emoji: '🪟',
        rarity: 'uncommon',
        stackSize: 50,
        craftable: true
    },
    rope: {
        id: 'rope',
        name: 'Rope',
        description: 'Strong twisted rope',
        emoji: '🪢',
        rarity: 'common',
        stackSize: 50,
        craftable: true
    },

    // Magical Materials
    stardust: {
        id: 'stardust',
        name: 'Stardust',
        description: 'Shimmering cosmic dust',
        emoji: '✨',
        rarity: 'legendary',
        stackSize: 20,
        gatherable: true,
        sources: ['sky_island', 'night_sky']
    },
    essence: {
        id: 'essence',
        name: 'Life Essence',
        description: 'Pure concentrated life energy',
        emoji: '💚',
        rarity: 'epic',
        stackSize: 10,
        gatherable: true,
        sources: ['ancient_tree', 'garden']
    },
    dreamweave: {
        id: 'dreamweave',
        name: 'Dreamweave',
        description: 'Fabric woven from dreams',
        emoji: '🌈',
        rarity: 'legendary',
        stackSize: 5,
        craftable: true
    }
};

// ===== CRAFTING RECIPES =====
export const RECIPES = {
    // Basic Materials
    plank: {
        id: 'plank',
        output: { item: 'plank', quantity: 4 },
        ingredients: [
            { item: 'wood', quantity: 1 }
        ],
        craftingTime: 1,
        category: 'materials',
        unlocked: true
    },
    brick: {
        id: 'brick',
        output: { item: 'brick', quantity: 2 },
        ingredients: [
            { item: 'stone', quantity: 2 }
        ],
        craftingTime: 2,
        category: 'materials',
        unlocked: true
    },
    glass: {
        id: 'glass',
        output: { item: 'glass', quantity: 1 },
        ingredients: [
            { item: 'sand', quantity: 4 }
        ],
        craftingTime: 3,
        category: 'materials',
        unlocked: true
    },
    rope: {
        id: 'rope',
        output: { item: 'rope', quantity: 2 },
        ingredients: [
            { item: 'fiber', quantity: 5 }
        ],
        craftingTime: 2,
        category: 'materials',
        unlocked: true
    },

    // Tools
    axe: {
        id: 'axe',
        output: { item: 'axe', quantity: 1 },
        ingredients: [
            { item: 'wood', quantity: 3 },
            { item: 'stone', quantity: 2 }
        ],
        craftingTime: 5,
        category: 'tools',
        unlocked: true
    },
    pickaxe: {
        id: 'pickaxe',
        output: { item: 'pickaxe', quantity: 1 },
        ingredients: [
            { item: 'wood', quantity: 2 },
            { item: 'stone', quantity: 3 }
        ],
        craftingTime: 5,
        category: 'tools',
        unlocked: true
    },
    shovel: {
        id: 'shovel',
        output: { item: 'shovel', quantity: 1 },
        ingredients: [
            { item: 'wood', quantity: 2 },
            { item: 'stone', quantity: 1 }
        ],
        craftingTime: 4,
        category: 'tools',
        unlocked: true
    },

    // Building Blocks
    wooden_wall: {
        id: 'wooden_wall',
        output: { item: 'wooden_wall', quantity: 1 },
        ingredients: [
            { item: 'plank', quantity: 4 }
        ],
        craftingTime: 2,
        category: 'building',
        unlocked: true
    },
    stone_wall: {
        id: 'stone_wall',
        output: { item: 'stone_wall', quantity: 1 },
        ingredients: [
            { item: 'brick', quantity: 6 }
        ],
        craftingTime: 3,
        category: 'building',
        unlocked: true
    },
    crystal_wall: {
        id: 'crystal_wall',
        output: { item: 'crystal_wall', quantity: 1 },
        ingredients: [
            { item: 'crystal', quantity: 3 },
            { item: 'stone', quantity: 2 }
        ],
        craftingTime: 5,
        category: 'building',
        unlocked: false,
        requirement: { level: 5 }
    },
    window: {
        id: 'window',
        output: { item: 'window', quantity: 1 },
        ingredients: [
            { item: 'glass', quantity: 2 },
            { item: 'plank', quantity: 2 }
        ],
        craftingTime: 3,
        category: 'building',
        unlocked: true
    },
    door: {
        id: 'door',
        output: { item: 'door', quantity: 1 },
        ingredients: [
            { item: 'plank', quantity: 6 }
        ],
        craftingTime: 4,
        category: 'building',
        unlocked: true
    },

    // Magical Items
    love_crystal: {
        id: 'love_crystal',
        output: { item: 'love_crystal', quantity: 1 },
        ingredients: [
            { item: 'crystal', quantity: 5 },
            { item: 'essence', quantity: 3 },
            { item: 'stardust', quantity: 1 }
        ],
        craftingTime: 10,
        category: 'magical',
        unlocked: false,
        requirement: { level: 10 }
    },
    portal_stone: {
        id: 'portal_stone',
        output: { item: 'portal_stone', quantity: 1 },
        ingredients: [
            { item: 'crystal', quantity: 10 },
            { item: 'stardust', quantity: 5 }
        ],
        craftingTime: 15,
        category: 'magical',
        unlocked: false,
        requirement: { level: 15 }
    },
    dreamweave: {
        id: 'dreamweave',
        output: { item: 'dreamweave', quantity: 1 },
        ingredients: [
            { item: 'fiber', quantity: 10 },
            { item: 'stardust', quantity: 3 },
            { item: 'essence', quantity: 2 }
        ],
        craftingTime: 20,
        category: 'magical',
        unlocked: false,
        requirement: { level: 20 }
    }
};

// ===== BUILDING BLOCKS =====
export const BUILDING_BLOCKS = {
    wooden_wall: {
        id: 'wooden_wall',
        name: 'Wooden Wall',
        size: { x: 2, y: 3, z: 0.2 },
        color: 0x8B4513,
        material: 'wood',
        health: 100
    },
    stone_wall: {
        id: 'stone_wall',
        name: 'Stone Wall',
        size: { x: 2, y: 3, z: 0.3 },
        color: 0x808080,
        material: 'stone',
        health: 200
    },
    crystal_wall: {
        id: 'crystal_wall',
        name: 'Crystal Wall',
        size: { x: 2, y: 3, z: 0.2 },
        color: 0x9B59B6,
        material: 'crystal',
        health: 150,
        emissive: true
    },
    floor: {
        id: 'floor',
        name: 'Floor',
        size: { x: 2, y: 0.1, z: 2 },
        color: 0xA0826D,
        material: 'wood',
        health: 80
    },
    roof: {
        id: 'roof',
        name: 'Roof',
        size: { x: 2, y: 0.2, z: 2 },
        color: 0x654321,
        material: 'wood',
        health: 90
    },
    window: {
        id: 'window',
        name: 'Window',
        size: { x: 1.5, y: 2, z: 0.1 },
        color: 0x87CEEB,
        material: 'glass',
        health: 30,
        transparent: true
    },
    door: {
        id: 'door',
        name: 'Door',
        size: { x: 1, y: 2.5, z: 0.15 },
        color: 0x654321,
        material: 'wood',
        health: 60,
        interactive: true
    },
    stairs: {
        id: 'stairs',
        name: 'Stairs',
        size: { x: 2, y: 1, z: 2 },
        color: 0x8B4513,
        material: 'wood',
        health: 100
    },
    pillar: {
        id: 'pillar',
        name: 'Pillar',
        size: { x: 0.5, y: 3, z: 0.5 },
        color: 0x696969,
        material: 'stone',
        health: 250
    }
};

// ===== INVENTORY SYSTEM =====
export class Inventory {
    constructor(size = 40) {
        this.size = size;
        this.slots = new Array(size).fill(null);
        this.selectedSlot = 0;
    }

    addItem(itemId, quantity = 1) {
        const resource = RESOURCES[itemId];
        if (!resource) return false;

        // Try to stack with existing items
        for (let i = 0; i < this.size; i++) {
            const slot = this.slots[i];
            if (slot && slot.id === itemId && slot.quantity < resource.stackSize) {
                const canAdd = Math.min(quantity, resource.stackSize - slot.quantity);
                slot.quantity += canAdd;
                quantity -= canAdd;

                if (quantity === 0) return true;
            }
        }

        // Create new stacks
        while (quantity > 0) {
            const emptySlot = this.slots.findIndex(s => s === null);
            if (emptySlot === -1) return false; // Inventory full

            const stackAmount = Math.min(quantity, resource.stackSize);
            this.slots[emptySlot] = {
                id: itemId,
                quantity: stackAmount
            };
            quantity -= stackAmount;
        }

        return true;
    }

    removeItem(itemId, quantity = 1) {
        let remaining = quantity;

        for (let i = 0; i < this.size; i++) {
            const slot = this.slots[i];
            if (slot && slot.id === itemId) {
                const remove = Math.min(remaining, slot.quantity);
                slot.quantity -= remove;
                remaining -= remove;

                if (slot.quantity === 0) {
                    this.slots[i] = null;
                }

                if (remaining === 0) return true;
            }
        }

        return remaining === 0;
    }

    hasItem(itemId, quantity = 1) {
        let total = 0;
        for (const slot of this.slots) {
            if (slot && slot.id === itemId) {
                total += slot.quantity;
            }
        }
        return total >= quantity;
    }

    getItemCount(itemId) {
        let total = 0;
        for (const slot of this.slots) {
            if (slot && slot.id === itemId) {
                total += slot.quantity;
            }
        }
        return total;
    }

    getSelectedItem() {
        return this.slots[this.selectedSlot];
    }

    selectSlot(index) {
        if (index >= 0 && index < this.size) {
            this.selectedSlot = index;
        }
    }

    clear() {
        this.slots = new Array(this.size).fill(null);
    }
}

// ===== CRAFTING MANAGER =====
export class CraftingManager {
    constructor(inventory) {
        this.inventory = inventory;
        this.recipes = { ...RECIPES };
        this.currentCraft = null;
        this.craftProgress = 0;
    }

    canCraft(recipeId) {
        const recipe = this.recipes[recipeId];
        if (!recipe || !recipe.unlocked) return false;

        // Check ingredients
        for (const ingredient of recipe.ingredients) {
            if (!this.inventory.hasItem(ingredient.item, ingredient.quantity)) {
                return false;
            }
        }

        return true;
    }

    startCrafting(recipeId) {
        if (!this.canCraft(recipeId)) {
            return { success: false, message: 'Missing ingredients or recipe locked' };
        }

        const recipe = this.recipes[recipeId];

        // Remove ingredients
        for (const ingredient of recipe.ingredients) {
            this.inventory.removeItem(ingredient.item, ingredient.quantity);
        }

        this.currentCraft = {
            recipe: recipeId,
            timeRemaining: recipe.craftingTime,
            startTime: Date.now()
        };

        return { success: true, message: `Crafting ${recipe.output.item}...` };
    }

    updateCrafting(deltaTime) {
        if (!this.currentCraft) return null;

        this.currentCraft.timeRemaining -= deltaTime;
        this.craftProgress = 1 - (this.currentCraft.timeRemaining / this.recipes[this.currentCraft.recipe].craftingTime);

        if (this.currentCraft.timeRemaining <= 0) {
            return this.completeCrafting();
        }

        return null;
    }

    completeCrafting() {
        if (!this.currentCraft) return null;

        const recipe = this.recipes[this.currentCraft.recipe];
        const output = recipe.output;

        this.inventory.addItem(output.item, output.quantity);

        const result = {
            item: output.item,
            quantity: output.quantity
        };

        this.currentCraft = null;
        this.craftProgress = 0;

        return result;
    }

    cancelCrafting() {
        if (!this.currentCraft) return;

        // Refund ingredients
        const recipe = this.recipes[this.currentCraft.recipe];
        for (const ingredient of recipe.ingredients) {
            this.inventory.addItem(ingredient.item, ingredient.quantity);
        }

        this.currentCraft = null;
        this.craftProgress = 0;
    }

    unlockRecipe(recipeId) {
        if (this.recipes[recipeId]) {
            this.recipes[recipeId].unlocked = true;
            console.log(`📜 Recipe unlocked: ${recipeId}`);
        }
    }

    getAvailableRecipes() {
        return Object.values(this.recipes).filter(r => r.unlocked);
    }

    getCraftableRecipes() {
        return Object.values(this.recipes).filter(r => r.unlocked && this.canCraft(r.id));
    }
}

// ===== BUILDING SYSTEM =====
export class BuildingSystem {
    constructor(scene, inventory) {
        this.scene = scene;
        this.inventory = inventory;
        this.structures = [];
        this.placementMode = false;
        this.selectedBlock = null;
        this.previewMesh = null;
        this.gridSize = 1;
        this.snapToGrid = true;
    }

    enterPlacementMode(blockId) {
        if (!this.inventory.hasItem(blockId, 1)) {
            return { success: false, message: 'Not enough materials' };
        }

        this.placementMode = true;
        this.selectedBlock = blockId;
        this.createPreview(blockId);

        return { success: true, message: `Placing ${blockId}...` };
    }

    exitPlacementMode() {
        this.placementMode = false;
        this.selectedBlock = null;
        if (this.previewMesh) {
            this.scene.remove(this.previewMesh);
            this.previewMesh = null;
        }
    }

    createPreview(blockId) {
        const block = BUILDING_BLOCKS[blockId];
        if (!block) return;

        const geometry = new THREE.BoxGeometry(block.size.x, block.size.y, block.size.z);
        const material = new THREE.MeshStandardMaterial({
            color: block.color,
            transparent: true,
            opacity: 0.5,
            emissive: block.emissive ? block.color : 0x000000,
            emissiveIntensity: block.emissive ? 0.3 : 0
        });

        this.previewMesh = new THREE.Mesh(geometry, material);
        this.scene.add(this.previewMesh);
    }

    updatePreview(position, rotation = 0) {
        if (!this.previewMesh) return;

        if (this.snapToGrid) {
            position.x = Math.round(position.x / this.gridSize) * this.gridSize;
            position.y = Math.round(position.y / this.gridSize) * this.gridSize;
            position.z = Math.round(position.z / this.gridSize) * this.gridSize;
        }

        this.previewMesh.position.copy(position);
        this.previewMesh.rotation.y = rotation;
    }

    placeBlock(position, rotation = 0) {
        if (!this.placementMode || !this.selectedBlock) return null;

        if (!this.inventory.removeItem(this.selectedBlock, 1)) {
            return { success: false, message: 'Not enough materials' };
        }

        const block = BUILDING_BLOCKS[this.selectedBlock];
        const geometry = new THREE.BoxGeometry(block.size.x, block.size.y, block.size.z);

        let material;
        if (block.transparent) {
            material = new THREE.MeshPhysicalMaterial({
                color: block.color,
                transparent: true,
                transmission: 0.9,
                roughness: 0.1,
                metalness: 0
            });
        } else {
            material = new THREE.MeshStandardMaterial({
                color: block.color,
                roughness: 0.8,
                metalness: 0.2,
                emissive: block.emissive ? block.color : 0x000000,
                emissiveIntensity: block.emissive ? 0.3 : 0
            });
        }

        const mesh = new THREE.Mesh(geometry, material);
        mesh.position.copy(position);
        mesh.rotation.y = rotation;
        mesh.castShadow = true;
        mesh.receiveShadow = true;

        this.scene.add(mesh);

        const structure = {
            id: crypto.randomUUID(),
            type: this.selectedBlock,
            mesh,
            health: block.health,
            position: position.clone(),
            rotation,
            createdAt: Date.now()
        };

        this.structures.push(structure);

        console.log(`🏗️ Placed ${block.name} at`, position);

        return { success: true, structure };
    }

    removeBlock(structure) {
        const index = this.structures.indexOf(structure);
        if (index === -1) return false;

        this.scene.remove(structure.mesh);
        structure.mesh.geometry.dispose();
        structure.mesh.material.dispose();

        this.structures.splice(index, 1);

        // Refund material
        this.inventory.addItem(structure.type, 1);

        return true;
    }

    getNearestBlock(position, maxDistance = 3) {
        let nearest = null;
        let minDist = maxDistance;

        this.structures.forEach(structure => {
            const dist = position.distanceTo(structure.position);
            if (dist < minDist) {
                minDist = dist;
                nearest = structure;
            }
        });

        return nearest;
    }

    // Blueprint system
    saveBlueprint(name, structures) {
        const blueprint = {
            name,
            blocks: structures.map(s => ({
                type: s.type,
                position: s.position.clone(),
                rotation: s.rotation
            })),
            createdAt: Date.now()
        };

        return blueprint;
    }

    loadBlueprint(blueprint, originPosition) {
        const placed = [];

        blueprint.blocks.forEach(blockData => {
            const position = blockData.position.clone().add(originPosition);

            if (this.inventory.hasItem(blockData.type, 1)) {
                const result = this.placeBlock(position, blockData.rotation);
                if (result.success) {
                    placed.push(result.structure);
                }
            }
        });

        return placed;
    }

    getStructureCount() {
        return this.structures.length;
    }

    getTotalBlocks() {
        return this.structures.length;
    }
}

// ===== GATHERING SYSTEM =====
export class GatheringSystem {
    constructor(inventory) {
        this.inventory = inventory;
        this.gatheringSpeed = 1.0;
        this.bonuses = {
            wood: 1.0,
            stone: 1.0,
            crystal: 1.0
        };
    }

    gather(resourceType, quantity = 1) {
        const bonus = this.bonuses[resourceType] || 1.0;
        const amount = Math.floor(quantity * bonus * this.gatheringSpeed);

        if (this.inventory.addItem(resourceType, amount)) {
            console.log(`⛏️ Gathered ${amount}x ${resourceType}`);
            return { success: true, amount };
        }

        return { success: false, message: 'Inventory full' };
    }

    setBonus(resourceType, multiplier) {
        this.bonuses[resourceType] = multiplier;
    }

    setSpeed(speed) {
        this.gatheringSpeed = speed;
    }
}

export default {
    Inventory,
    CraftingManager,
    BuildingSystem,
    GatheringSystem,
    RESOURCES,
    RECIPES,
    BUILDING_BLOCKS
};
