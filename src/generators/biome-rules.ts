/**
 * Biome Constraint Rules
 * Defines what features can exist in each biome
 * Based on WORLD_GENERATION.md specification
 */

import { BiomeType, BiomeConstraints } from '../types/chunk';

export const BIOME_RULES: Record<BiomeType, BiomeConstraints> = {
  TROPICAL_RAINFOREST: {
    biomeType: 'TROPICAL_RAINFOREST',
    validFeatures: [
      'tropical_tree',
      'palm_tree',
      'giant_tree',
      'jungle_vine',
      'river',
      'waterfall',
      'clearing',
      'jungle_floor',
      'canopy',
      'agent_home',
    ],
    elevationRange: [0, 500],
    moistureRange: [0.7, 1.0],
    temperatureRange: [24, 32],
    vegetationDensity: 0.9,
    allowWater: true,
    allowStructures: true,
  },

  TEMPERATE_FOREST: {
    biomeType: 'TEMPERATE_FOREST',
    validFeatures: [
      'oak_tree',
      'maple_tree',
      'birch_tree',
      'pine_tree',
      'stream',
      'glade',
      'forest_path',
      'fallen_log',
      'agent_home',
    ],
    elevationRange: [0, 800],
    moistureRange: [0.4, 0.8],
    temperatureRange: [8, 20],
    vegetationDensity: 0.7,
    allowWater: true,
    allowStructures: true,
  },

  BOREAL_TAIGA: {
    biomeType: 'BOREAL_TAIGA',
    validFeatures: [
      'spruce_tree',
      'fir_tree',
      'frozen_lake',
      'snow_patch',
      'rocky_ground',
      'agent_home',
    ],
    elevationRange: [0, 600],
    moistureRange: [0.3, 0.6],
    temperatureRange: [-15, 5],
    vegetationDensity: 0.5,
    allowWater: true,
    allowStructures: true,
  },

  TUNDRA: {
    biomeType: 'TUNDRA',
    validFeatures: [
      'shrub',
      'permafrost',
      'rock',
      'ice_patch',
      'low_plant',
      'agent_home',
    ],
    elevationRange: [0, 400],
    moistureRange: [0.2, 0.4],
    temperatureRange: [-30, 0],
    vegetationDensity: 0.2,
    allowWater: true,
    allowStructures: true,
  },

  DESERT_HOT: {
    biomeType: 'DESERT_HOT',
    validFeatures: [
      'cactus',
      'joshua_tree',
      'desert_palm',
      'sand_dune',
      'rock_formation',
      'oasis',
      'agent_home',
    ],
    elevationRange: [0, 600],
    moistureRange: [0.0, 0.2],
    temperatureRange: [30, 50],
    vegetationDensity: 0.1,
    allowWater: false,
    allowStructures: true,
  },

  DESERT_COLD: {
    biomeType: 'DESERT_COLD',
    validFeatures: [
      'shrub',
      'sage',
      'rock_outcrop',
      'gravel_plain',
      'agent_home',
    ],
    elevationRange: [200, 1200],
    moistureRange: [0.0, 0.2],
    temperatureRange: [-20, 15],
    vegetationDensity: 0.05,
    allowWater: false,
    allowStructures: true,
  },

  SAVANNA: {
    biomeType: 'SAVANNA',
    validFeatures: [
      'acacia_tree',
      'baobab_tree',
      'tall_grass',
      'watering_hole',
      'rock_outcrop',
      'agent_home',
    ],
    elevationRange: [0, 500],
    moistureRange: [0.2, 0.5],
    temperatureRange: [20, 35],
    vegetationDensity: 0.3,
    allowWater: true,
    allowStructures: true,
  },

  GRASSLAND: {
    biomeType: 'GRASSLAND',
    validFeatures: [
      'grass_tree',
      'tall_grass',
      'rolling_hill',
      'scattered_tree',
      'wildflower_patch',
      'agent_home',
    ],
    elevationRange: [0, 400],
    moistureRange: [0.3, 0.6],
    temperatureRange: [10, 25],
    vegetationDensity: 0.4,
    allowWater: true,
    allowStructures: true,
  },

  MEDITERRANEAN: {
    biomeType: 'MEDITERRANEAN',
    validFeatures: [
      'olive_tree',
      'cypress_tree',
      'cork_oak',
      'scrubland',
      'rocky_terrain',
      'coastal_cliff',
      'agent_home',
    ],
    elevationRange: [0, 600],
    moistureRange: [0.3, 0.5],
    temperatureRange: [12, 28],
    vegetationDensity: 0.5,
    allowWater: true,
    allowStructures: true,
  },

  MOUNTAIN: {
    biomeType: 'MOUNTAIN',
    validFeatures: [
      'alpine_pine',
      'alpine_fir',
      'cliff_face',
      'rocky_peak',
      'alpine_meadow',
      'snow_cap',
      'agent_home',
    ],
    elevationRange: [800, 3000],
    moistureRange: [0.3, 0.7],
    temperatureRange: [-20, 10],
    vegetationDensity: 0.3,
    allowWater: true,
    allowStructures: true,
  },

  ICE_SHEET: {
    biomeType: 'ICE_SHEET',
    validFeatures: [
      'ice_field',
      'crevasse',
      'frozen_lake',
      'ice_formation',
      'agent_home',
    ],
    elevationRange: [0, 200],
    moistureRange: [0.8, 1.0],
    temperatureRange: [-60, -20],
    vegetationDensity: 0.0,
    allowWater: true,
    allowStructures: false,
  },

  WETLAND: {
    biomeType: 'WETLAND',
    validFeatures: [
      'mangrove',
      'cypress_swamp',
      'willow_tree',
      'marsh',
      'standing_water',
      'mud_flat',
      'agent_home',
    ],
    elevationRange: [0, 50],
    moistureRange: [0.8, 1.0],
    temperatureRange: [15, 30],
    vegetationDensity: 0.7,
    allowWater: true,
    allowStructures: true,
  },

  OCEAN: {
    biomeType: 'OCEAN',
    validFeatures: [
      'wave',
      'reef',
      'deep_trench',
      'seamount',
    ],
    elevationRange: [-1000, 0],
    moistureRange: [1.0, 1.0],
    temperatureRange: [2, 30],
    vegetationDensity: 0.0,
    allowWater: true,
    allowStructures: false,
  },
};

/**
 * Get biome constraints
 */
export function getBiomeConstraints(biome: BiomeType): BiomeConstraints {
  return BIOME_RULES[biome];
}

/**
 * Check if a feature is valid for a biome
 */
export function isFeatureValid(biome: BiomeType, feature: string): boolean {
  const constraints = BIOME_RULES[biome];
  return constraints.validFeatures.includes(feature);
}

/**
 * Blend constraints between two biomes
 * Used for transition zones at biome boundaries
 */
export function blendBiomeConstraints(
  biomeA: BiomeType,
  biomeB: BiomeType,
  weight: number // 0 = all A, 1 = all B
): BiomeConstraints {
  const constraintsA = BIOME_RULES[biomeA];
  const constraintsB = BIOME_RULES[biomeB];

  return {
    biomeType: weight < 0.5 ? biomeA : biomeB,
    validFeatures: [
      ...constraintsA.validFeatures,
      ...constraintsB.validFeatures,
    ],
    elevationRange: [
      constraintsA.elevationRange[0] * (1 - weight) + constraintsB.elevationRange[0] * weight,
      constraintsA.elevationRange[1] * (1 - weight) + constraintsB.elevationRange[1] * weight,
    ],
    moistureRange: [
      constraintsA.moistureRange[0] * (1 - weight) + constraintsB.moistureRange[0] * weight,
      constraintsA.moistureRange[1] * (1 - weight) + constraintsB.moistureRange[1] * weight,
    ],
    temperatureRange: [
      constraintsA.temperatureRange[0] * (1 - weight) + constraintsB.temperatureRange[0] * weight,
      constraintsA.temperatureRange[1] * (1 - weight) + constraintsB.temperatureRange[1] * weight,
    ],
    vegetationDensity:
      constraintsA.vegetationDensity * (1 - weight) + constraintsB.vegetationDensity * weight,
    allowWater: constraintsA.allowWater || constraintsB.allowWater,
    allowStructures: constraintsA.allowStructures && constraintsB.allowStructures,
  };
}
