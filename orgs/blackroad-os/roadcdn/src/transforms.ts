/**
 * Image Transformation Module for RoadCDN
 *
 * Advanced image processing with:
 * - Resizing
 * - Format conversion
 * - Filters
 * - Watermarks
 * - Smart cropping
 */

interface TransformOptions {
  width?: number;
  height?: number;
  fit?: 'contain' | 'cover' | 'fill' | 'inside' | 'outside';
  format?: 'jpeg' | 'png' | 'webp' | 'avif' | 'gif';
  quality?: number; // 1-100
  blur?: number; // 0-250
  sharpen?: number; // 0-10
  brightness?: number; // -100 to 100
  contrast?: number; // -100 to 100
  saturation?: number; // -100 to 100
  grayscale?: boolean;
  rotate?: 0 | 90 | 180 | 270;
  flip?: boolean;
  flop?: boolean;
  watermark?: WatermarkOptions;
  crop?: CropOptions;
}

interface WatermarkOptions {
  text?: string;
  image?: string;
  position?: 'center' | 'top-left' | 'top-right' | 'bottom-left' | 'bottom-right';
  opacity?: number; // 0-1
  scale?: number; // 0-1
}

interface CropOptions {
  x: number;
  y: number;
  width: number;
  height: number;
}

interface TransformResult {
  url: string;
  width: number;
  height: number;
  format: string;
  size: number;
  cached: boolean;
}

/**
 * Parse transform options from URL query params
 */
export function parseTransformParams(url: URL): TransformOptions {
  const params = url.searchParams;
  const options: TransformOptions = {};

  if (params.has('w')) options.width = parseInt(params.get('w')!);
  if (params.has('h')) options.height = parseInt(params.get('h')!);
  if (params.has('fit')) options.fit = params.get('fit') as any;
  if (params.has('f')) options.format = params.get('f') as any;
  if (params.has('q')) options.quality = parseInt(params.get('q')!);
  if (params.has('blur')) options.blur = parseInt(params.get('blur')!);
  if (params.has('sharpen')) options.sharpen = parseFloat(params.get('sharpen')!);
  if (params.has('brightness')) options.brightness = parseInt(params.get('brightness')!);
  if (params.has('contrast')) options.contrast = parseInt(params.get('contrast')!);
  if (params.has('saturation')) options.saturation = parseInt(params.get('saturation')!);
  if (params.has('grayscale')) options.grayscale = params.get('grayscale') === 'true';
  if (params.has('rotate')) options.rotate = parseInt(params.get('rotate')!) as any;
  if (params.has('flip')) options.flip = params.get('flip') === 'true';
  if (params.has('flop')) options.flop = params.get('flop') === 'true';

  // Watermark
  if (params.has('wm-text') || params.has('wm-image')) {
    options.watermark = {
      text: params.get('wm-text') || undefined,
      image: params.get('wm-image') || undefined,
      position: (params.get('wm-pos') as any) || 'bottom-right',
      opacity: parseFloat(params.get('wm-opacity') || '0.5'),
      scale: parseFloat(params.get('wm-scale') || '0.2'),
    };
  }

  // Crop
  if (params.has('crop')) {
    const [x, y, w, h] = params.get('crop')!.split(',').map(Number);
    options.crop = { x, y, width: w, height: h };
  }

  return options;
}

/**
 * Generate cache key for transformed image
 */
export function generateCacheKey(path: string, options: TransformOptions): string {
  const optStr = JSON.stringify(options);
  const hash = simpleHash(optStr);
  return `transform:${path}:${hash}`;
}

function simpleHash(str: string): string {
  let hash = 0;
  for (let i = 0; i < str.length; i++) {
    const char = str.charCodeAt(i);
    hash = ((hash << 5) - hash) + char;
    hash = hash & hash;
  }
  return Math.abs(hash).toString(36);
}

/**
 * Build Cloudflare Image Resizing URL
 * Uses cf.image or /cdn-cgi/image/
 */
export function buildCFImageUrl(
  originalUrl: string,
  options: TransformOptions,
): string {
  const params: string[] = [];

  if (options.width) params.push(`width=${options.width}`);
  if (options.height) params.push(`height=${options.height}`);
  if (options.fit) params.push(`fit=${options.fit}`);
  if (options.format) params.push(`format=${options.format}`);
  if (options.quality) params.push(`quality=${options.quality}`);
  if (options.blur) params.push(`blur=${options.blur}`);
  if (options.sharpen) params.push(`sharpen=${options.sharpen}`);
  if (options.brightness) params.push(`brightness=${options.brightness / 100}`);
  if (options.contrast) params.push(`contrast=${options.contrast / 100}`);
  if (options.saturation) params.push(`saturation=${options.saturation / 100}`);
  if (options.grayscale) params.push('saturation=0');
  if (options.rotate) params.push(`rotate=${options.rotate}`);

  const transformString = params.join(',');

  // Cloudflare Image Resizing format
  const url = new URL(originalUrl);
  return `${url.origin}/cdn-cgi/image/${transformString}${url.pathname}`;
}

/**
 * Preset transformations
 */
export const PRESETS: Record<string, TransformOptions> = {
  thumbnail: {
    width: 150,
    height: 150,
    fit: 'cover',
    format: 'webp',
    quality: 80,
  },
  small: {
    width: 320,
    fit: 'inside',
    format: 'webp',
    quality: 85,
  },
  medium: {
    width: 800,
    fit: 'inside',
    format: 'webp',
    quality: 85,
  },
  large: {
    width: 1920,
    fit: 'inside',
    format: 'webp',
    quality: 90,
  },
  avatar: {
    width: 200,
    height: 200,
    fit: 'cover',
    format: 'webp',
    quality: 85,
  },
  og: {
    width: 1200,
    height: 630,
    fit: 'cover',
    format: 'png',
    quality: 95,
  },
  blur_preview: {
    width: 20,
    height: 20,
    blur: 20,
    format: 'webp',
    quality: 30,
  },
  grayscale_thumb: {
    width: 200,
    height: 200,
    fit: 'cover',
    grayscale: true,
    format: 'webp',
    quality: 80,
  },
};

/**
 * Get preset by name
 */
export function getPreset(name: string): TransformOptions | null {
  return PRESETS[name] || null;
}

/**
 * Validate transform options
 */
export function validateOptions(options: TransformOptions): string[] {
  const errors: string[] = [];

  if (options.width && (options.width < 1 || options.width > 10000)) {
    errors.push('Width must be between 1 and 10000');
  }

  if (options.height && (options.height < 1 || options.height > 10000)) {
    errors.push('Height must be between 1 and 10000');
  }

  if (options.quality && (options.quality < 1 || options.quality > 100)) {
    errors.push('Quality must be between 1 and 100');
  }

  if (options.blur && (options.blur < 0 || options.blur > 250)) {
    errors.push('Blur must be between 0 and 250');
  }

  if (options.rotate && ![0, 90, 180, 270].includes(options.rotate)) {
    errors.push('Rotate must be 0, 90, 180, or 270');
  }

  return errors;
}

/**
 * Generate srcset for responsive images
 */
export function generateSrcSet(
  originalUrl: string,
  widths: number[] = [320, 640, 960, 1280, 1920],
  options: Partial<TransformOptions> = {},
): string {
  return widths
    .map(w => {
      const url = buildCFImageUrl(originalUrl, { ...options, width: w });
      return `${url} ${w}w`;
    })
    .join(', ');
}

/**
 * Generate picture element sources
 */
export function generatePictureSources(
  originalUrl: string,
  options: Partial<TransformOptions> = {},
): {
  avif: string;
  webp: string;
  fallback: string;
} {
  return {
    avif: buildCFImageUrl(originalUrl, { ...options, format: 'avif' }),
    webp: buildCFImageUrl(originalUrl, { ...options, format: 'webp' }),
    fallback: buildCFImageUrl(originalUrl, { ...options, format: 'jpeg' }),
  };
}

/**
 * Estimate transformed image size
 */
export function estimateSize(
  originalSize: number,
  originalWidth: number,
  originalHeight: number,
  options: TransformOptions,
): number {
  const targetWidth = options.width || originalWidth;
  const targetHeight = options.height || originalHeight;

  // Estimate based on dimension ratio
  const dimensionRatio = (targetWidth * targetHeight) / (originalWidth * originalHeight);

  // Quality factor
  const qualityFactor = (options.quality || 85) / 100;

  // Format factor (webp is ~30% smaller, avif ~50% smaller)
  let formatFactor = 1;
  if (options.format === 'webp') formatFactor = 0.7;
  if (options.format === 'avif') formatFactor = 0.5;

  return Math.round(originalSize * dimensionRatio * qualityFactor * formatFactor);
}
