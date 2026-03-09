/**
 * BlackRoad SDK Errors
 */

export class BlackRoadError extends Error {
  code: string;
  statusCode?: number;
  details?: Record<string, unknown>;

  constructor(message: string, code: string = 'UNKNOWN_ERROR', statusCode?: number) {
    super(message);
    this.name = 'BlackRoadError';
    this.code = code;
    this.statusCode = statusCode;
    Object.setPrototypeOf(this, BlackRoadError.prototype);
  }
}

export class AuthenticationError extends BlackRoadError {
  constructor(message: string = 'Authentication failed') {
    super(message, 'AUTH_ERROR', 401);
    this.name = 'AuthenticationError';
    Object.setPrototypeOf(this, AuthenticationError.prototype);
  }
}

export class RateLimitError extends BlackRoadError {
  retryAfter?: number;

  constructor(message: string = 'Rate limit exceeded', retryAfter?: number) {
    super(message, 'RATE_LIMIT', 429);
    this.name = 'RateLimitError';
    this.retryAfter = retryAfter;
    Object.setPrototypeOf(this, RateLimitError.prototype);
  }
}

export class NotFoundError extends BlackRoadError {
  constructor(message: string = 'Resource not found') {
    super(message, 'NOT_FOUND', 404);
    this.name = 'NotFoundError';
    Object.setPrototypeOf(this, NotFoundError.prototype);
  }
}

export class ValidationError extends BlackRoadError {
  errors?: Array<{ field: string; message: string }>;

  constructor(message: string = 'Validation failed', errors?: Array<{ field: string; message: string }>) {
    super(message, 'VALIDATION_ERROR', 422);
    this.name = 'ValidationError';
    this.errors = errors;
    Object.setPrototypeOf(this, ValidationError.prototype);
  }
}

export class ConnectionError extends BlackRoadError {
  constructor(message: string = 'Connection failed') {
    super(message, 'CONNECTION_ERROR');
    this.name = 'ConnectionError';
    Object.setPrototypeOf(this, ConnectionError.prototype);
  }
}

export class TimeoutError extends BlackRoadError {
  constructor(message: string = 'Request timed out') {
    super(message, 'TIMEOUT');
    this.name = 'TimeoutError';
    Object.setPrototypeOf(this, TimeoutError.prototype);
  }
}
