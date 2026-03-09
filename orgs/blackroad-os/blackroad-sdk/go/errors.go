package blackroad

import "fmt"

// Error represents a BlackRoad API error.
type Error struct {
	Message    string
	Code       string
	StatusCode int
}

func (e *Error) Error() string {
	if e.Code != "" {
		return fmt.Sprintf("blackroad: %s (code: %s, status: %d)", e.Message, e.Code, e.StatusCode)
	}
	return fmt.Sprintf("blackroad: %s", e.Message)
}

// AuthenticationError indicates an invalid or missing API key.
type AuthenticationError struct {
	*Error
}

// NewAuthenticationError creates a new AuthenticationError.
func NewAuthenticationError(message string) *AuthenticationError {
	return &AuthenticationError{
		Error: &Error{
			Message:    message,
			Code:       "AUTHENTICATION_ERROR",
			StatusCode: 401,
		},
	}
}

// NotFoundError indicates a resource was not found.
type NotFoundError struct {
	*Error
	Resource string
}

// NewNotFoundError creates a new NotFoundError.
func NewNotFoundError(resource string) *NotFoundError {
	return &NotFoundError{
		Error: &Error{
			Message:    fmt.Sprintf("resource not found: %s", resource),
			Code:       "NOT_FOUND",
			StatusCode: 404,
		},
		Resource: resource,
	}
}

// RateLimitError indicates the rate limit was exceeded.
type RateLimitError struct {
	*Error
	RetryAfter int
}

// NewRateLimitError creates a new RateLimitError.
func NewRateLimitError(retryAfter int) *RateLimitError {
	return &RateLimitError{
		Error: &Error{
			Message:    "rate limit exceeded",
			Code:       "RATE_LIMIT_EXCEEDED",
			StatusCode: 429,
		},
		RetryAfter: retryAfter,
	}
}

// ValidationError indicates invalid request data.
type ValidationError struct {
	*Error
	Details string
}

// NewValidationError creates a new ValidationError.
func NewValidationError(details string) *ValidationError {
	return &ValidationError{
		Error: &Error{
			Message:    fmt.Sprintf("validation error: %s", details),
			Code:       "VALIDATION_ERROR",
			StatusCode: 422,
		},
		Details: details,
	}
}

// ConnectionError indicates a network or connection failure.
type ConnectionError struct {
	*Error
	Cause error
}

// NewConnectionError creates a new ConnectionError.
func NewConnectionError(message string, cause error) *ConnectionError {
	return &ConnectionError{
		Error: &Error{
			Message: message,
			Code:    "CONNECTION_ERROR",
		},
		Cause: cause,
	}
}

func (e *ConnectionError) Unwrap() error {
	return e.Cause
}
