// Package main - Health Service (Go Implementation)
// Part of BlackRoad OS - https://blackroad.io
package main

import (
	"encoding/json"
	"log"
	"net/http"
	"time"
)

type HealthResponse struct {
	Service   string `json:"service"`
	Status    string `json:"status"`
	Timestamp string `json:"timestamp"`
}

func healthHandler(w http.ResponseWriter, r *http.Request) {
	resp := HealthResponse{
		Service:   "roadhealth",
		Status:    "healthy",
		Timestamp: time.Now().UTC().Format(time.RFC3339),
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(resp)
}

func main() {
	http.HandleFunc("/health", healthHandler)
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		json.NewEncoder(w).Encode(map[string]string{
			"name": "roadhealth",
			"version": "1.0.0",
			"lang": "go",
		})
	})
	
	log.Println("🖤 Health running on :3000")
	log.Fatal(http.ListenAndServe(":3000", nil))
}
