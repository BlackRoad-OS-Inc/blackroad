package blackroad

import (
	"context"
	"encoding/json"
	"fmt"
	"net/url"
	"strconv"
)

// TaskAPI provides access to task operations.
type TaskAPI struct {
	client *Client
}

// Dispatch creates a new task.
func (t *TaskAPI) Dispatch(ctx context.Context, opts *DispatchTaskOptions) (*Task, error) {
	if opts.Priority == "" {
		opts.Priority = "medium"
	}

	resp, err := t.client.Post(ctx, "/tasks", opts)
	if err != nil {
		return nil, err
	}

	var task Task
	if err := json.Unmarshal(resp, &task); err != nil {
		return nil, NewConnectionError("failed to parse task response", err)
	}
	return &task, nil
}

// Get returns a specific task by ID.
func (t *TaskAPI) Get(ctx context.Context, taskID string) (*Task, error) {
	resp, err := t.client.Get(ctx, fmt.Sprintf("/tasks/%s", taskID), nil)
	if err != nil {
		return nil, err
	}

	var task Task
	if err := json.Unmarshal(resp, &task); err != nil {
		return nil, NewConnectionError("failed to parse task response", err)
	}
	return &task, nil
}

// List returns tasks with optional filters.
func (t *TaskAPI) List(ctx context.Context, opts *TaskListOptions) ([]Task, error) {
	params := url.Values{}
	if opts != nil {
		if opts.Status != "" {
			params.Set("status", opts.Status)
		}
		if opts.Priority != "" {
			params.Set("priority", opts.Priority)
		}
		if opts.Division != "" {
			params.Set("division", opts.Division)
		}
		if opts.Limit > 0 {
			params.Set("limit", strconv.Itoa(opts.Limit))
		}
		if opts.Offset > 0 {
			params.Set("offset", strconv.Itoa(opts.Offset))
		}
	}

	resp, err := t.client.Get(ctx, "/tasks", params)
	if err != nil {
		return nil, err
	}

	var result struct {
		Tasks []Task `json:"tasks"`
	}
	if err := json.Unmarshal(resp, &result); err != nil {
		return nil, NewConnectionError("failed to parse tasks response", err)
	}
	return result.Tasks, nil
}

// Complete marks a task as completed.
func (t *TaskAPI) Complete(ctx context.Context, taskID string, result string) (*Task, error) {
	body := map[string]interface{}{
		"status": "completed",
	}
	if result != "" {
		body["result"] = result
	}

	resp, err := t.client.Put(ctx, fmt.Sprintf("/tasks/%s", taskID), body)
	if err != nil {
		return nil, err
	}

	var task Task
	if err := json.Unmarshal(resp, &task); err != nil {
		return nil, NewConnectionError("failed to parse task response", err)
	}
	return &task, nil
}

// Fail marks a task as failed.
func (t *TaskAPI) Fail(ctx context.Context, taskID string, reason string) (*Task, error) {
	body := map[string]interface{}{
		"status": "failed",
	}
	if reason != "" {
		body["result"] = reason
	}

	resp, err := t.client.Put(ctx, fmt.Sprintf("/tasks/%s", taskID), body)
	if err != nil {
		return nil, err
	}

	var task Task
	if err := json.Unmarshal(resp, &task); err != nil {
		return nil, NewConnectionError("failed to parse task response", err)
	}
	return &task, nil
}

// Assign assigns a task to an agent.
func (t *TaskAPI) Assign(ctx context.Context, taskID string, agentID string) (*Task, error) {
	body := map[string]interface{}{
		"assigned_agent": agentID,
		"status":         "assigned",
	}

	resp, err := t.client.Put(ctx, fmt.Sprintf("/tasks/%s", taskID), body)
	if err != nil {
		return nil, err
	}

	var task Task
	if err := json.Unmarshal(resp, &task); err != nil {
		return nil, NewConnectionError("failed to parse task response", err)
	}
	return &task, nil
}

// Cancel cancels a task.
func (t *TaskAPI) Cancel(ctx context.Context, taskID string) error {
	_, err := t.client.Delete(ctx, fmt.Sprintf("/tasks/%s", taskID))
	return err
}

// Stats returns task statistics.
func (t *TaskAPI) Stats(ctx context.Context) (*Stats, error) {
	resp, err := t.client.Get(ctx, "/tasks/stats", nil)
	if err != nil {
		return nil, err
	}

	var stats Stats
	if err := json.Unmarshal(resp, &stats); err != nil {
		return nil, NewConnectionError("failed to parse stats response", err)
	}
	return &stats, nil
}

// Pending returns pending tasks.
func (t *TaskAPI) Pending(ctx context.Context) ([]Task, error) {
	return t.List(ctx, &TaskListOptions{Status: "pending"})
}

// InProgress returns in-progress tasks.
func (t *TaskAPI) InProgress(ctx context.Context) ([]Task, error) {
	return t.List(ctx, &TaskListOptions{Status: "in_progress"})
}

// ByDivision returns tasks filtered by division.
func (t *TaskAPI) ByDivision(ctx context.Context, division string) ([]Task, error) {
	return t.List(ctx, &TaskListOptions{Division: division})
}

// Urgent returns urgent priority tasks.
func (t *TaskAPI) Urgent(ctx context.Context) ([]Task, error) {
	return t.List(ctx, &TaskListOptions{Priority: "urgent"})
}
