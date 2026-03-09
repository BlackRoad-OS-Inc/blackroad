/**
 * File Upload Handler for RoadForms
 *
 * Handles file uploads with:
 * - Size limits
 * - Type validation
 * - Virus scanning placeholder
 * - R2 storage
 */

interface UploadConfig {
  maxSizeBytes: number;
  allowedTypes: string[];
  allowedExtensions: string[];
  scanForViruses: boolean;
}

interface UploadResult {
  id: string;
  filename: string;
  originalName: string;
  size: number;
  contentType: string;
  url: string;
  uploadedAt: number;
}

interface UploadError {
  code: string;
  message: string;
  field?: string;
}

const DEFAULT_CONFIG: UploadConfig = {
  maxSizeBytes: 10 * 1024 * 1024, // 10MB
  allowedTypes: [
    'image/jpeg',
    'image/png',
    'image/gif',
    'image/webp',
    'application/pdf',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'application/vnd.ms-excel',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'text/plain',
    'text/csv',
  ],
  allowedExtensions: [
    '.jpg', '.jpeg', '.png', '.gif', '.webp',
    '.pdf', '.doc', '.docx', '.xls', '.xlsx',
    '.txt', '.csv',
  ],
  scanForViruses: false,
};

/**
 * Validate file upload
 */
export function validateUpload(
  file: File,
  config: Partial<UploadConfig> = {},
): UploadError | null {
  const cfg = { ...DEFAULT_CONFIG, ...config };

  // Check size
  if (file.size > cfg.maxSizeBytes) {
    return {
      code: 'FILE_TOO_LARGE',
      message: `File exceeds maximum size of ${cfg.maxSizeBytes / (1024 * 1024)}MB`,
    };
  }

  // Check type
  if (!cfg.allowedTypes.includes(file.type)) {
    return {
      code: 'INVALID_TYPE',
      message: `File type ${file.type} is not allowed`,
    };
  }

  // Check extension
  const ext = '.' + file.name.split('.').pop()?.toLowerCase();
  if (!cfg.allowedExtensions.includes(ext)) {
    return {
      code: 'INVALID_EXTENSION',
      message: `File extension ${ext} is not allowed`,
    };
  }

  return null;
}

/**
 * Generate unique filename
 */
export function generateFilename(originalName: string): string {
  const timestamp = Date.now();
  const random = Math.random().toString(36).substring(2, 8);
  const ext = originalName.split('.').pop() || 'bin';
  return `${timestamp}-${random}.${ext}`;
}

/**
 * Get file metadata
 */
export function getFileMetadata(file: File): {
  name: string;
  size: number;
  type: string;
  lastModified: number;
} {
  return {
    name: file.name,
    size: file.size,
    type: file.type,
    lastModified: file.lastModified,
  };
}

/**
 * Upload handler for Cloudflare Workers
 */
export async function handleUpload(
  request: Request,
  bucket: R2Bucket,
  formId: string,
  fieldId: string,
  config: Partial<UploadConfig> = {},
): Promise<Response> {
  const cfg = { ...DEFAULT_CONFIG, ...config };

  try {
    const formData = await request.formData();
    const file = formData.get('file') as File | null;

    if (!file) {
      return Response.json(
        { error: { code: 'NO_FILE', message: 'No file provided' } },
        { status: 400 }
      );
    }

    // Validate
    const error = validateUpload(file, cfg);
    if (error) {
      return Response.json({ error }, { status: 400 });
    }

    // Generate storage path
    const filename = generateFilename(file.name);
    const storagePath = `uploads/${formId}/${fieldId}/${filename}`;

    // Upload to R2
    const arrayBuffer = await file.arrayBuffer();

    await bucket.put(storagePath, arrayBuffer, {
      httpMetadata: {
        contentType: file.type,
      },
      customMetadata: {
        originalName: file.name,
        formId,
        fieldId,
        uploadedAt: String(Date.now()),
      },
    });

    const result: UploadResult = {
      id: filename.split('.')[0],
      filename,
      originalName: file.name,
      size: file.size,
      contentType: file.type,
      url: `/uploads/${formId}/${fieldId}/${filename}`,
      uploadedAt: Date.now(),
    };

    return Response.json(result);

  } catch (e) {
    console.error('Upload error:', e);
    return Response.json(
      { error: { code: 'UPLOAD_FAILED', message: 'Upload failed' } },
      { status: 500 }
    );
  }
}

/**
 * Serve uploaded file
 */
export async function serveUpload(
  bucket: R2Bucket,
  path: string,
): Promise<Response> {
  const object = await bucket.get(path);

  if (!object) {
    return new Response('Not found', { status: 404 });
  }

  const headers = new Headers();
  headers.set('Content-Type', object.httpMetadata?.contentType || 'application/octet-stream');
  headers.set('Content-Length', String(object.size));
  headers.set('Cache-Control', 'public, max-age=31536000');

  // Set content-disposition for downloads
  const originalName = object.customMetadata?.originalName;
  if (originalName) {
    headers.set('Content-Disposition', `inline; filename="${originalName}"`);
  }

  return new Response(object.body, { headers });
}

/**
 * Delete uploaded file
 */
export async function deleteUpload(
  bucket: R2Bucket,
  path: string,
): Promise<boolean> {
  try {
    await bucket.delete(path);
    return true;
  } catch {
    return false;
  }
}

/**
 * List uploads for a form
 */
export async function listUploads(
  bucket: R2Bucket,
  formId: string,
): Promise<UploadResult[]> {
  const prefix = `uploads/${formId}/`;
  const list = await bucket.list({ prefix });

  return list.objects.map(obj => ({
    id: obj.key.split('/').pop()?.split('.')[0] || '',
    filename: obj.key.split('/').pop() || '',
    originalName: obj.customMetadata?.originalName || '',
    size: obj.size,
    contentType: obj.httpMetadata?.contentType || '',
    url: `/${obj.key}`,
    uploadedAt: parseInt(obj.customMetadata?.uploadedAt || '0'),
  }));
}

/**
 * Get total storage used by a form
 */
export async function getStorageUsage(
  bucket: R2Bucket,
  formId: string,
): Promise<{ count: number; totalBytes: number }> {
  const prefix = `uploads/${formId}/`;
  const list = await bucket.list({ prefix });

  let totalBytes = 0;
  for (const obj of list.objects) {
    totalBytes += obj.size;
  }

  return {
    count: list.objects.length,
    totalBytes,
  };
}

/**
 * Image processing utilities
 */
export function isImage(contentType: string): boolean {
  return contentType.startsWith('image/');
}

export function getImageDimensions(arrayBuffer: ArrayBuffer): Promise<{
  width: number;
  height: number;
} | null> {
  // In Workers, we'd use cf.image or external service
  // This is a placeholder
  return Promise.resolve(null);
}

/**
 * Generate thumbnail URL (using Cloudflare Images)
 */
export function getThumbnailUrl(
  originalUrl: string,
  width: number = 200,
  height: number = 200,
): string {
  // In production, use Cloudflare Image Resizing
  // return `https://imagedelivery.net/.../w=${width},h=${height}/${path}`;
  return `${originalUrl}?w=${width}&h=${height}`;
}
