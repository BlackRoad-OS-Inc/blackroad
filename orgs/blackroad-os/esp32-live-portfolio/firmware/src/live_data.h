/**
 * ESP32 Live Hub - Real-Time Data System
 * Fetches and parses live data from BlackRoad aggregator API
 *
 * All screens bind to these structs - updated every 30 seconds
 */

#ifndef LIVE_DATA_H
#define LIVE_DATA_H

#include <Arduino.h>
#include <WiFi.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>

// ═══════════════════════════════════════════════════════════════════
// CONFIGURATION
// ═══════════════════════════════════════════════════════════════════

#define LIVE_HUB_URL "https://api.blackroad.io/v1/live-hub"
#define FETCH_INTERVAL_MS 30000  // 30 seconds
#define FETCH_TIMEOUT_MS 10000   // 10 second timeout
#define MAX_ALERTS 5
#define MAX_TOP_REPOS 5
#define MAX_SERVERS 5

// ═══════════════════════════════════════════════════════════════════
// DATA STRUCTURES - All live data flows through here
// ═══════════════════════════════════════════════════════════════════

// GitHub metrics
struct GitHubData {
    int total_repos;
    int total_stars;
    int total_forks;
    int open_prs;
    int open_issues;
    int commits_today;
    char last_commit[16];

    struct TopRepo {
        char name[32];
        int stars;
        int forks;
        char language[16];
    } top_repos[MAX_TOP_REPOS];
    int top_repo_count;
};

// Crypto prices
struct CryptoData {
    int btc_price;
    float btc_change;
    int eth_price;
    float eth_change;
    int sol_price;
    float sol_change;
    int portfolio_value;
    float btc_holding;
    float eth_holding;
    float sol_holding;
};

// Infrastructure health
struct InfraData {
    struct Server {
        char name[16];
        char ip[16];
        bool online;
        int cpu;
        int mem;
        int disk;
    } servers[MAX_SERVERS];
    int server_count;
    int servers_online;
    int vpn_nodes;
    int vpn_connected;
    int sovereignty_score;
    int containers_running;
};

// Business metrics
struct BusinessData {
    // CRM
    int total_leads;
    int hot_leads;
    int deals_pipeline;
    int pipeline_value;  // in thousands
    int won_this_month;

    // Stripe
    int mrr;
    int arr;
    int customers;
    int transactions_today;

    // Linear
    int open_issues;
    int in_progress;
    int completed_today;
    int p1_issues;
};

// AI/ML systems
struct AIData {
    bool vllm_online;
    int vllm_requests;
    int vllm_latency;

    bool localai_online;
    int models_loaded;
    int gpu_util;

    int vectors_stored;  // in millions
    int agents_active;   // in thousands
    int inference_today;
};

// Cloudflare
struct CloudflareData {
    int zones;
    int pages_projects;
    int workers;
    int kv_namespaces;
    int requests_24h;  // in thousands
};

// Alerts
struct Alert {
    char level[12];    // "info", "warning", "critical"
    char source[16];   // "linear", "infrastructure", etc.
    char message[64];
};

// Summary
struct SummaryData {
    int products_live;
    int products_total;
    int health_score;
    int sovereignty_score;
    float uptime_percent;
};

// ═══════════════════════════════════════════════════════════════════
// GLOBAL LIVE DATA - All screens read from here
// ═══════════════════════════════════════════════════════════════════

extern GitHubData liveGitHub;
extern CryptoData liveCrypto;
extern InfraData liveInfra;
extern BusinessData liveBusiness;
extern AIData liveAI;
extern CloudflareData liveCloudflare;
extern Alert liveAlerts[MAX_ALERTS];
extern int liveAlertCount;
extern SummaryData liveSummary;

extern unsigned long lastFetchTime;
extern bool lastFetchSuccess;
extern int dataAgeSeconds;

// ═══════════════════════════════════════════════════════════════════
// LIVE DATA FUNCTIONS
// ═══════════════════════════════════════════════════════════════════

/**
 * Initialize live data system
 */
void initLiveData() {
    memset(&liveGitHub, 0, sizeof(liveGitHub));
    memset(&liveCrypto, 0, sizeof(liveCrypto));
    memset(&liveInfra, 0, sizeof(liveInfra));
    memset(&liveBusiness, 0, sizeof(liveBusiness));
    memset(&liveAI, 0, sizeof(liveAI));
    memset(&liveCloudflare, 0, sizeof(liveCloudflare));
    memset(&liveSummary, 0, sizeof(liveSummary));
    liveAlertCount = 0;
    lastFetchTime = 0;
    lastFetchSuccess = false;
}

/**
 * Fetch live data from aggregator API
 * Call this every FETCH_INTERVAL_MS
 */
bool fetchLiveData() {
    if (WiFi.status() != WL_CONNECTED) {
        Serial.println("[LIVE] WiFi not connected");
        return false;
    }

    HTTPClient http;
    http.setTimeout(FETCH_TIMEOUT_MS);
    http.begin(LIVE_HUB_URL);
    http.addHeader("Accept", "application/json");

    Serial.println("[LIVE] Fetching live data...");
    unsigned long startTime = millis();

    int httpCode = http.GET();

    if (httpCode != 200) {
        Serial.printf("[LIVE] HTTP error: %d\n", httpCode);
        http.end();
        lastFetchSuccess = false;
        return false;
    }

    String payload = http.getString();
    http.end();

    unsigned long fetchTime = millis() - startTime;
    Serial.printf("[LIVE] Received %d bytes in %lums\n", payload.length(), fetchTime);

    // Parse JSON
    DynamicJsonDocument doc(16384);  // 16KB buffer
    DeserializationError error = deserializeJson(doc, payload);

    if (error) {
        Serial.printf("[LIVE] JSON parse error: %s\n", error.c_str());
        lastFetchSuccess = false;
        return false;
    }

    // Parse GitHub
    JsonObject github = doc["github"];
    liveGitHub.total_repos = github["total_repos"] | 0;
    liveGitHub.total_stars = github["total_stars"] | 0;
    liveGitHub.total_forks = github["total_forks"] | 0;
    liveGitHub.open_prs = github["open_prs"] | 0;
    liveGitHub.open_issues = github["open_issues"] | 0;
    liveGitHub.commits_today = github["commits_today"] | 0;
    strlcpy(liveGitHub.last_commit, github["last_commit"] | "N/A", sizeof(liveGitHub.last_commit));

    // Parse top repos
    JsonArray topRepos = github["top_repos"];
    liveGitHub.top_repo_count = min((int)topRepos.size(), MAX_TOP_REPOS);
    for (int i = 0; i < liveGitHub.top_repo_count; i++) {
        strlcpy(liveGitHub.top_repos[i].name, topRepos[i]["name"] | "", 32);
        liveGitHub.top_repos[i].stars = topRepos[i]["stars"] | 0;
        liveGitHub.top_repos[i].forks = topRepos[i]["forks"] | 0;
        strlcpy(liveGitHub.top_repos[i].language, topRepos[i]["language"] | "", 16);
    }

    // Parse Crypto
    JsonObject crypto = doc["crypto"];
    liveCrypto.btc_price = crypto["btc"]["price"] | 0;
    liveCrypto.btc_change = crypto["btc"]["change_24h"] | 0.0f;
    liveCrypto.eth_price = crypto["eth"]["price"] | 0;
    liveCrypto.eth_change = crypto["eth"]["change_24h"] | 0.0f;
    liveCrypto.sol_price = crypto["sol"]["price"] | 0;
    liveCrypto.sol_change = crypto["sol"]["change_24h"] | 0.0f;
    liveCrypto.portfolio_value = crypto["portfolio_value_raw"] | 0;
    liveCrypto.btc_holding = crypto["holdings"]["btc"] | 0.0f;
    liveCrypto.eth_holding = crypto["holdings"]["eth"] | 0.0f;
    liveCrypto.sol_holding = crypto["holdings"]["sol"] | 0.0f;

    // Parse Infrastructure
    JsonObject infra = doc["infrastructure"];
    liveInfra.servers_online = infra["servers_online"] | 0;
    liveInfra.vpn_nodes = infra["vpn_nodes"] | 0;
    liveInfra.vpn_connected = infra["vpn_connected"] | 0;
    liveInfra.sovereignty_score = infra["sovereignty_score"] | 0;
    liveInfra.containers_running = infra["containers_running"] | 0;

    JsonObject servers = infra["servers"];
    liveInfra.server_count = 0;
    for (JsonPair kv : servers) {
        if (liveInfra.server_count >= MAX_SERVERS) break;
        int idx = liveInfra.server_count++;
        strlcpy(liveInfra.servers[idx].name, kv.value()["name"] | "", 16);
        strlcpy(liveInfra.servers[idx].ip, kv.value()["ip"] | "", 16);
        liveInfra.servers[idx].online = strcmp(kv.value()["status"] | "offline", "online") == 0;
        liveInfra.servers[idx].cpu = kv.value()["cpu"] | 0;
        liveInfra.servers[idx].mem = kv.value()["mem"] | 0;
        liveInfra.servers[idx].disk = kv.value()["disk"] | 0;
    }

    // Parse Business
    JsonObject business = doc["business"];
    JsonObject crm = business["crm"];
    liveBusiness.total_leads = crm["total_leads"] | 0;
    liveBusiness.hot_leads = crm["hot_leads"] | 0;
    liveBusiness.deals_pipeline = crm["deals_pipeline"] | 0;
    liveBusiness.pipeline_value = crm["pipeline_value_raw"] | 0;
    liveBusiness.won_this_month = crm["won_this_month"] | 0;

    JsonObject stripe = business["stripe"];
    liveBusiness.mrr = stripe["mrr_raw"] | 0;
    liveBusiness.arr = stripe["arr_raw"] | 0;
    liveBusiness.customers = stripe["customers"] | 0;
    liveBusiness.transactions_today = stripe["transactions_today"] | 0;

    JsonObject linear = business["linear"];
    liveBusiness.open_issues = linear["open_issues"] | 0;
    liveBusiness.in_progress = linear["in_progress"] | 0;
    liveBusiness.completed_today = linear["completed_today"] | 0;
    liveBusiness.p1_issues = linear["p1_issues"] | 0;

    // Parse AI
    JsonObject ai = doc["ai"];
    liveAI.vllm_online = strcmp(ai["vllm"]["status"] | "offline", "online") == 0;
    liveAI.vllm_requests = ai["vllm"]["requests_today"] | 0;
    liveAI.vllm_latency = ai["vllm"]["avg_latency_ms"] | 0;
    liveAI.localai_online = strcmp(ai["localai"]["status"] | "offline", "online") == 0;
    liveAI.models_loaded = ai["localai"]["models_loaded"] | 0;
    liveAI.gpu_util = ai["localai"]["gpu_util"] | 0;
    liveAI.vectors_stored = ai["embeddings"]["vectors_stored"] | 0;
    liveAI.agents_active = ai["agents_active"] | 0;
    liveAI.inference_today = ai["inference_today"] | 0;

    // Parse Cloudflare
    JsonObject cf = doc["cloudflare"];
    liveCloudflare.zones = cf["zones"] | 0;
    liveCloudflare.pages_projects = cf["pages_projects"] | 0;
    liveCloudflare.workers = cf["workers"] | 0;
    liveCloudflare.kv_namespaces = cf["kv_namespaces"] | 0;
    liveCloudflare.requests_24h = cf["requests_24h"] | 0;

    // Parse Alerts
    JsonArray alerts = doc["alerts"];
    liveAlertCount = min((int)alerts.size(), MAX_ALERTS);
    for (int i = 0; i < liveAlertCount; i++) {
        strlcpy(liveAlerts[i].level, alerts[i]["level"] | "info", 12);
        strlcpy(liveAlerts[i].source, alerts[i]["source"] | "", 16);
        strlcpy(liveAlerts[i].message, alerts[i]["message"] | "", 64);
    }

    // Parse Summary
    JsonObject summary = doc["summary"];
    liveSummary.products_live = summary["products_live"] | 0;
    liveSummary.products_total = summary["products_total"] | 199;
    liveSummary.health_score = summary["health_score"] | 0;
    liveSummary.sovereignty_score = summary["sovereignty_score"] | 0;
    liveSummary.uptime_percent = summary["uptime_percent"] | 0.0f;

    lastFetchTime = millis();
    lastFetchSuccess = true;

    Serial.println("[LIVE] Data updated successfully!");
    Serial.printf("[LIVE] GitHub: %d repos, %d stars\n", liveGitHub.total_repos, liveGitHub.total_stars);
    Serial.printf("[LIVE] Crypto: BTC $%d, ETH $%d, SOL $%d\n", liveCrypto.btc_price, liveCrypto.eth_price, liveCrypto.sol_price);
    Serial.printf("[LIVE] Infra: %d/%d servers online\n", liveInfra.servers_online, liveInfra.server_count);

    return true;
}

/**
 * Get data freshness in seconds
 */
int getDataAge() {
    if (lastFetchTime == 0) return 999;
    return (millis() - lastFetchTime) / 1000;
}

/**
 * Check if data is fresh (< 60 seconds old)
 */
bool isDataFresh() {
    return getDataAge() < 60;
}

/**
 * Check if data is stale (60-300 seconds old)
 */
bool isDataStale() {
    int age = getDataAge();
    return age >= 60 && age < 300;
}

/**
 * Check if data is offline (> 300 seconds old)
 */
bool isDataOffline() {
    return getDataAge() >= 300;
}

/**
 * Get status text for UI
 */
const char* getDataStatusText() {
    if (isDataFresh()) return "LIVE";
    if (isDataStale()) return "STALE";
    return "OFFLINE";
}

/**
 * Get status color for UI (RGB565)
 */
uint16_t getDataStatusColor() {
    if (isDataFresh()) return 0x07E0;   // Green
    if (isDataStale()) return 0xFFE0;   // Yellow
    return 0xF800;                       // Red
}

/**
 * Auto-fetch loop - call from main loop()
 */
void updateLiveData() {
    static unsigned long lastUpdate = 0;

    if (millis() - lastUpdate >= FETCH_INTERVAL_MS) {
        fetchLiveData();
        lastUpdate = millis();
    }
}

#endif // LIVE_DATA_H
