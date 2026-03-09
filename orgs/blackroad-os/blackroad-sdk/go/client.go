package blackroad

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"os"
	"strconv"
	"strings"
	"time"
)

const (
	defaultBaseURL    = "https://api.blackroad.io/v1"
	defaultTimeout    = 30 * time.Second
	defaultMaxRetries = 3
)

// ClientConfig contains configuration options for the client.
type ClientConfig struct {
	// APIKey is the BlackRoad API key. If empty, reads from BLACKROAD_API_KEY env var.
	APIKey string

	// BaseURL is the API base URL. Defaults to https://api.blackroad.io/v1
	BaseURL string

	// Timeout is the request timeout. Defaults to 30 seconds.
	Timeout time.Duration

	// MaxRetries is the maximum number of retry attempts. Defaults to 3.
	MaxRetries int

	// HTTPClient allows providing a custom HTTP client.
	HTTPClient *http.Client
}

// Client is the BlackRoad API client.
type Client struct {
	apiKey     string
	baseURL    string
	timeout    time.Duration
	maxRetries int
	httpClient *http.Client

	// API modules
	Agents *AgentAPI
	Tasks  *TaskAPI
	Memory *MemoryAPI
}

// NewClient creates a new BlackRoad client.
//
// Example:
//
//	client, err := blackroad.NewClient(&blackroad.ClientConfig{
//		APIKey: "your-api-key",
//	})
//	if err != nil {
//		log.Fatal(err)
//	}
//
//	agents, err := client.Agents.List(context.Background(), nil)
func NewClient(config *ClientConfig) (*Client, error) {
	if config == nil {
		config = &ClientConfig{}
	}

	apiKey := config.APIKey
	if apiKey == "" {
		apiKey = os.Getenv("BLACKROAD_API_KEY")
	}
	if apiKey == "" {
		return nil, NewAuthenticationError("API key required. Set BLACKROAD_API_KEY environment variable or pass APIKey in config.")
	}

	baseURL := config.BaseURL
	if baseURL == "" {
		baseURL = os.Getenv("BLACKROAD_API_URL")
	}
	if baseURL == "" {
		baseURL = defaultBaseURL
	}
	baseURL = strings.TrimSuffix(baseURL, "/")

	timeout := config.Timeout
	if timeout == 0 {
		timeout = defaultTimeout
	}

	maxRetries := config.MaxRetries
	if maxRetries == 0 {
		maxRetries = defaultMaxRetries
	}

	httpClient := config.HTTPClient
	if httpClient == nil {
		httpClient = &http.Client{
			Timeout: timeout,
		}
	}

	c := &Client{
		apiKey:     apiKey,
		baseURL:    baseURL,
		timeout:    timeout,
		maxRetries: maxRetries,
		httpClient: httpClient,
	}

	// Initialize API modules
	c.Agents = &AgentAPI{client: c}
	c.Tasks = &TaskAPI{client: c}
	c.Memory = &MemoryAPI{client: c}

	return c, nil
}

// request makes an HTTP request to the API.
func (c *Client) request(ctx context.Context, method, endpoint string, body interface{}, params url.Values) ([]byte, error) {
	fullURL := fmt.Sprintf("%s/%s", c.baseURL, strings.TrimPrefix(endpoint, "/"))
	if len(params) > 0 {
		fullURL = fmt.Sprintf("%s?%s", fullURL, params.Encode())
	}

	var bodyReader io.Reader
	if body != nil {
		jsonBody, err := json.Marshal(body)
		if err != nil {
			return nil, NewConnectionError("failed to marshal request body", err)
		}
		bodyReader = bytes.NewReader(jsonBody)
	}

	var lastErr error
	for attempt := 0; attempt < c.maxRetries; attempt++ {
		req, err := http.NewRequestWithContext(ctx, method, fullURL, bodyReader)
		if err != nil {
			return nil, NewConnectionError("failed to create request", err)
		}

		req.Header.Set("Authorization", fmt.Sprintf("Bearer %s", c.apiKey))
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("User-Agent", "blackroad-go/1.0.0")

		resp, err := c.httpClient.Do(req)
		if err != nil {
			lastErr = NewConnectionError("request failed", err)
			time.Sleep(time.Duration(1<<attempt) * time.Second)
			continue
		}
		defer resp.Body.Close()

		respBody, err := io.ReadAll(resp.Body)
		if err != nil {
			lastErr = NewConnectionError("failed to read response", err)
			continue
		}

		if resp.StatusCode >= 200 && resp.StatusCode < 300 {
			return respBody, nil
		}

		switch resp.StatusCode {
		case 401:
			return nil, NewAuthenticationError("invalid API key")
		case 404:
			return nil, NewNotFoundError(endpoint)
		case 422:
			return nil, NewValidationError(string(respBody))
		case 429:
			retryAfter := 1
			if ra := resp.Header.Get("Retry-After"); ra != "" {
				if parsed, err := strconv.Atoi(ra); err == nil {
					retryAfter = parsed
				}
			}
			if attempt < c.maxRetries-1 {
				time.Sleep(time.Duration(retryAfter) * time.Second)
				continue
			}
			return nil, NewRateLimitError(retryAfter)
		default:
			lastErr = &Error{
				Message:    fmt.Sprintf("API error: %s", string(respBody)),
				Code:       "API_ERROR",
				StatusCode: resp.StatusCode,
			}
		}
	}

	if lastErr != nil {
		return nil, lastErr
	}
	return nil, &Error{Message: "max retries exceeded"}
}

// Get makes a GET request.
func (c *Client) Get(ctx context.Context, endpoint string, params url.Values) ([]byte, error) {
	return c.request(ctx, http.MethodGet, endpoint, nil, params)
}

// Post makes a POST request.
func (c *Client) Post(ctx context.Context, endpoint string, body interface{}) ([]byte, error) {
	return c.request(ctx, http.MethodPost, endpoint, body, nil)
}

// Put makes a PUT request.
func (c *Client) Put(ctx context.Context, endpoint string, body interface{}) ([]byte, error) {
	return c.request(ctx, http.MethodPut, endpoint, body, nil)
}

// Delete makes a DELETE request.
func (c *Client) Delete(ctx context.Context, endpoint string) ([]byte, error) {
	return c.request(ctx, http.MethodDelete, endpoint, nil, nil)
}

// Health checks the API health status.
func (c *Client) Health(ctx context.Context) (*HealthStatus, error) {
	resp, err := c.Get(ctx, "/health", nil)
	if err != nil {
		return nil, err
	}

	var health HealthStatus
	if err := json.Unmarshal(resp, &health); err != nil {
		return nil, NewConnectionError("failed to parse health response", err)
	}
	return &health, nil
}

// Version returns the API version.
func (c *Client) Version(ctx context.Context) (string, error) {
	resp, err := c.Get(ctx, "/version", nil)
	if err != nil {
		return "", err
	}

	var result struct {
		Version string `json:"version"`
	}
	if err := json.Unmarshal(resp, &result); err != nil {
		return "", NewConnectionError("failed to parse version response", err)
	}
	return result.Version, nil
}
