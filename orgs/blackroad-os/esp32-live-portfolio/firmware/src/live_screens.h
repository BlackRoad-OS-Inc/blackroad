/**
 * ESP32 Live Hub - Screen Renderers
 * All screens read from live data structs and render in real-time
 */

#ifndef LIVE_SCREENS_H
#define LIVE_SCREENS_H

#include "live_data.h"

// Forward declarations (from main.cpp)
extern TFT_eSPI tft;
extern BlackRoadFont brFont;

// ═══════════════════════════════════════════════════════════════════
// COMMON UI ELEMENTS
// ═══════════════════════════════════════════════════════════════════

/**
 * Draw live status indicator in top-right corner
 */
void drawLiveIndicator(int x, int y) {
    uint16_t statusColor = getDataStatusColor();
    const char* statusText = getDataStatusText();
    int age = getDataAge();

    // Draw status dot
    tft.fillCircle(x, y + 6, 4, statusColor);

    // Draw status text
    tft.setTextColor(statusColor);
    tft.setTextSize(1);
    tft.setCursor(x + 10, y);
    tft.print(statusText);

    // Draw age
    tft.setCursor(x + 10, y + 10);
    if (age < 60) {
        tft.printf("%ds", age);
    } else if (age < 3600) {
        tft.printf("%dm", age / 60);
    } else {
        tft.print("--");
    }
}

/**
 * Draw section header with live dot
 */
void drawSectionHeader(const char* title, uint16_t color, bool isLive) {
    tft.fillRect(0, 0, 320, 24, COLOR_BLACK);
    tft.setTextColor(color);
    tft.setTextSize(2);
    tft.setCursor(8, 4);
    tft.print(title);

    if (isLive) {
        drawLiveIndicator(260, 4);
    }
}

/**
 * Draw metric card
 */
void drawMetricCard(int x, int y, int w, int h, const char* label, const char* value, uint16_t color) {
    // Card background
    tft.fillRoundRect(x, y, w, h, 4, 0x1082);  // Dark gray
    tft.drawRoundRect(x, y, w, h, 4, color);

    // Value (large)
    tft.setTextColor(COLOR_WHITE);
    tft.setTextSize(2);
    tft.setCursor(x + 8, y + 8);
    tft.print(value);

    // Label (small)
    tft.setTextColor(color);
    tft.setTextSize(1);
    tft.setCursor(x + 8, y + h - 14);
    tft.print(label);
}

/**
 * Draw metric card with integer value
 */
void drawMetricCardInt(int x, int y, int w, int h, const char* label, int value, uint16_t color) {
    char buf[16];
    if (value >= 1000000) {
        sprintf(buf, "%.1fM", value / 1000000.0);
    } else if (value >= 1000) {
        sprintf(buf, "%.1fK", value / 1000.0);
    } else {
        sprintf(buf, "%d", value);
    }
    drawMetricCard(x, y, w, h, label, buf, color);
}

/**
 * Draw progress bar
 */
void drawProgressBar(int x, int y, int w, int h, int percent, uint16_t color) {
    tft.drawRect(x, y, w, h, color);
    int fillW = (w - 2) * percent / 100;
    tft.fillRect(x + 1, y + 1, fillW, h - 2, color);
}

// ═══════════════════════════════════════════════════════════════════
// PORTFOLIO HOME SCREEN
// ═══════════════════════════════════════════════════════════════════

void drawPortfolioHome() {
    tft.fillScreen(COLOR_BLACK);
    drawSectionHeader("BLACKROAD PORTFOLIO", COLOR_HOT_PINK, true);

    // Main stats - 2x2 grid
    drawMetricCardInt(8, 32, 150, 50, "PRODUCTS", liveSummary.products_live, COLOR_HOT_PINK);
    drawMetricCardInt(162, 32, 150, 50, "ORGS", 15, COLOR_ELECTRIC_BLUE);
    drawMetricCardInt(8, 88, 150, 50, "GITHUB STARS", liveGitHub.total_stars, COLOR_AMBER);
    drawMetricCardInt(162, 88, 150, 50, "AGENTS", liveAI.agents_active / 1000, COLOR_VIOLET);

    // Sovereignty score bar
    tft.setTextColor(COLOR_WHITE);
    tft.setTextSize(1);
    tft.setCursor(8, 148);
    tft.print("Infrastructure Sovereignty:");
    tft.printf(" %d%%", liveInfra.sovereignty_score);
    drawProgressBar(8, 162, 304, 12, liveInfra.sovereignty_score, COLOR_AMBER);

    // Health score bar
    tft.setCursor(8, 182);
    tft.print("System Health:");
    tft.printf(" %d%%", liveSummary.health_score);
    drawProgressBar(8, 196, 304, 12, liveSummary.health_score, COLOR_ELECTRIC_BLUE);

    // Bottom: Alert count or status
    if (liveAlertCount > 0) {
        tft.setTextColor(COLOR_HOT_PINK);
        tft.setCursor(8, 218);
        tft.printf("%d active alerts", liveAlertCount);
    } else {
        tft.setTextColor(COLOR_ELECTRIC_BLUE);
        tft.setCursor(8, 218);
        tft.print("All systems operational");
    }
}

// ═══════════════════════════════════════════════════════════════════
// GITHUB SCREEN - LIVE
// ═══════════════════════════════════════════════════════════════════

void drawGitHubScreen() {
    tft.fillScreen(COLOR_BLACK);
    drawSectionHeader("GITHUB", COLOR_VIOLET, true);

    // Stats row 1
    drawMetricCardInt(8, 32, 100, 45, "REPOS", liveGitHub.total_repos, COLOR_VIOLET);
    drawMetricCardInt(112, 32, 100, 45, "STARS", liveGitHub.total_stars, COLOR_AMBER);
    drawMetricCardInt(216, 32, 96, 45, "FORKS", liveGitHub.total_forks, COLOR_ELECTRIC_BLUE);

    // Stats row 2
    drawMetricCardInt(8, 82, 100, 45, "PRS", liveGitHub.open_prs, COLOR_HOT_PINK);
    drawMetricCardInt(112, 82, 100, 45, "ISSUES", liveGitHub.open_issues, COLOR_AMBER);
    drawMetricCardInt(216, 82, 96, 45, "COMMITS", liveGitHub.commits_today, COLOR_ELECTRIC_BLUE);

    // Top repos
    tft.setTextColor(COLOR_WHITE);
    tft.setTextSize(1);
    tft.setCursor(8, 135);
    tft.print("TOP REPOSITORIES:");

    for (int i = 0; i < min(liveGitHub.top_repo_count, 4); i++) {
        int y = 150 + (i * 18);
        tft.setTextColor(COLOR_AMBER);
        tft.setCursor(8, y);
        tft.print(liveGitHub.top_repos[i].name);
        tft.setTextColor(COLOR_WHITE);
        tft.setCursor(200, y);
        tft.printf("%d stars", liveGitHub.top_repos[i].stars);
    }
}

// ═══════════════════════════════════════════════════════════════════
// CRYPTO SCREEN - LIVE
// ═══════════════════════════════════════════════════════════════════

void drawCryptoScreen() {
    tft.fillScreen(COLOR_BLACK);
    drawSectionHeader("CRYPTO", COLOR_AMBER, true);

    // BTC
    tft.setTextColor(COLOR_AMBER);
    tft.setTextSize(2);
    tft.setCursor(8, 35);
    tft.print("BTC");
    tft.setTextColor(COLOR_WHITE);
    tft.setCursor(60, 35);
    tft.printf("$%d", liveCrypto.btc_price);
    tft.setTextColor(liveCrypto.btc_change >= 0 ? 0x07E0 : 0xF800);
    tft.setTextSize(1);
    tft.setCursor(200, 40);
    tft.printf("%+.1f%%", liveCrypto.btc_change);

    // ETH
    tft.setTextColor(COLOR_ELECTRIC_BLUE);
    tft.setTextSize(2);
    tft.setCursor(8, 70);
    tft.print("ETH");
    tft.setTextColor(COLOR_WHITE);
    tft.setCursor(60, 70);
    tft.printf("$%d", liveCrypto.eth_price);
    tft.setTextColor(liveCrypto.eth_change >= 0 ? 0x07E0 : 0xF800);
    tft.setTextSize(1);
    tft.setCursor(200, 75);
    tft.printf("%+.1f%%", liveCrypto.eth_change);

    // SOL
    tft.setTextColor(COLOR_VIOLET);
    tft.setTextSize(2);
    tft.setCursor(8, 105);
    tft.print("SOL");
    tft.setTextColor(COLOR_WHITE);
    tft.setCursor(60, 105);
    tft.printf("$%d", liveCrypto.sol_price);
    tft.setTextColor(liveCrypto.sol_change >= 0 ? 0x07E0 : 0xF800);
    tft.setTextSize(1);
    tft.setCursor(200, 110);
    tft.printf("%+.1f%%", liveCrypto.sol_change);

    // Portfolio value
    tft.drawLine(0, 140, 320, 140, COLOR_DARK_GRAY);
    tft.setTextColor(COLOR_HOT_PINK);
    tft.setTextSize(1);
    tft.setCursor(8, 150);
    tft.print("PORTFOLIO VALUE");
    tft.setTextColor(COLOR_WHITE);
    tft.setTextSize(3);
    tft.setCursor(8, 170);
    tft.printf("$%d", liveCrypto.portfolio_value);

    // Holdings
    tft.setTextSize(1);
    tft.setTextColor(COLOR_AMBER);
    tft.setCursor(8, 210);
    tft.printf("%.2f BTC", liveCrypto.btc_holding);
    tft.setTextColor(COLOR_ELECTRIC_BLUE);
    tft.setCursor(100, 210);
    tft.printf("%.1f ETH", liveCrypto.eth_holding);
    tft.setTextColor(COLOR_VIOLET);
    tft.setCursor(200, 210);
    tft.printf("%.0f SOL", liveCrypto.sol_holding);
}

// ═══════════════════════════════════════════════════════════════════
// INFRASTRUCTURE SCREEN - LIVE
// ═══════════════════════════════════════════════════════════════════

void drawInfraScreen() {
    tft.fillScreen(COLOR_BLACK);
    drawSectionHeader("INFRASTRUCTURE", COLOR_ELECTRIC_BLUE, true);

    // Server status
    tft.setTextColor(COLOR_WHITE);
    tft.setTextSize(1);

    for (int i = 0; i < min(liveInfra.server_count, 5); i++) {
        int y = 32 + (i * 36);

        // Status dot
        uint16_t statusColor = liveInfra.servers[i].online ? 0x07E0 : 0xF800;
        tft.fillCircle(12, y + 10, 5, statusColor);

        // Server name
        tft.setTextColor(COLOR_WHITE);
        tft.setCursor(24, y);
        tft.print(liveInfra.servers[i].name);

        // IP
        tft.setTextColor(COLOR_DARK_GRAY);
        tft.setCursor(24, y + 12);
        tft.print(liveInfra.servers[i].ip);

        if (liveInfra.servers[i].online) {
            // CPU bar
            tft.setTextColor(COLOR_AMBER);
            tft.setCursor(140, y);
            tft.printf("CPU %d%%", liveInfra.servers[i].cpu);
            drawProgressBar(140, y + 12, 60, 8, liveInfra.servers[i].cpu, COLOR_AMBER);

            // MEM bar
            tft.setTextColor(COLOR_ELECTRIC_BLUE);
            tft.setCursor(220, y);
            tft.printf("MEM %d%%", liveInfra.servers[i].mem);
            drawProgressBar(220, y + 12, 60, 8, liveInfra.servers[i].mem, COLOR_ELECTRIC_BLUE);
        }
    }

    // VPN status
    tft.drawLine(0, 195, 320, 195, COLOR_DARK_GRAY);
    tft.setTextColor(COLOR_VIOLET);
    tft.setCursor(8, 205);
    tft.printf("VPN: %d/%d nodes", liveInfra.vpn_connected, liveInfra.vpn_nodes);

    tft.setTextColor(COLOR_HOT_PINK);
    tft.setCursor(160, 205);
    tft.printf("Containers: %d", liveInfra.containers_running);

    tft.setTextColor(COLOR_AMBER);
    tft.setCursor(8, 222);
    tft.printf("Sovereignty: %d%%", liveInfra.sovereignty_score);
}

// ═══════════════════════════════════════════════════════════════════
// AI SCREEN - LIVE
// ═══════════════════════════════════════════════════════════════════

void drawAIScreen() {
    tft.fillScreen(COLOR_BLACK);
    drawSectionHeader("AI SYSTEMS", COLOR_VIOLET, true);

    // vLLM status
    tft.setTextColor(liveAI.vllm_online ? 0x07E0 : 0xF800);
    tft.setTextSize(1);
    tft.setCursor(8, 35);
    tft.print(liveAI.vllm_online ? "VLLM ONLINE" : "VLLM OFFLINE");
    if (liveAI.vllm_online) {
        tft.setTextColor(COLOR_WHITE);
        tft.setCursor(8, 50);
        tft.printf("Requests: %d | Latency: %dms", liveAI.vllm_requests, liveAI.vllm_latency);
    }

    // LocalAI status
    tft.setTextColor(liveAI.localai_online ? 0x07E0 : 0xF800);
    tft.setCursor(8, 75);
    tft.print(liveAI.localai_online ? "LOCALAI ONLINE" : "LOCALAI OFFLINE");
    if (liveAI.localai_online) {
        tft.setTextColor(COLOR_WHITE);
        tft.setCursor(8, 90);
        tft.printf("Models: %d | GPU: %d%%", liveAI.models_loaded, liveAI.gpu_util);
        drawProgressBar(200, 88, 100, 10, liveAI.gpu_util, COLOR_HOT_PINK);
    }

    // Vectors
    tft.setTextColor(COLOR_AMBER);
    tft.setCursor(8, 115);
    tft.print("VECTOR DB");
    tft.setTextColor(COLOR_WHITE);
    tft.setCursor(100, 115);
    if (liveAI.vectors_stored >= 1000000) {
        tft.printf("%.1fM vectors", liveAI.vectors_stored / 1000000.0);
    } else {
        tft.printf("%dK vectors", liveAI.vectors_stored / 1000);
    }

    // Big stats
    tft.drawLine(0, 135, 320, 135, COLOR_DARK_GRAY);
    drawMetricCardInt(8, 145, 150, 45, "AGENTS ACTIVE", liveAI.agents_active, COLOR_HOT_PINK);
    drawMetricCardInt(162, 145, 150, 45, "INFERENCES/DAY", liveAI.inference_today, COLOR_VIOLET);

    // Status
    tft.setTextColor(COLOR_ELECTRIC_BLUE);
    tft.setCursor(8, 210);
    tft.print("30,000 AI Employees Deployed");
}

// ═══════════════════════════════════════════════════════════════════
// BUSINESS SCREEN - LIVE
// ═══════════════════════════════════════════════════════════════════

void drawBusinessScreen() {
    tft.fillScreen(COLOR_BLACK);
    drawSectionHeader("BUSINESS", COLOR_HOT_PINK, true);

    // CRM Section
    tft.setTextColor(COLOR_AMBER);
    tft.setTextSize(1);
    tft.setCursor(8, 32);
    tft.print("CRM");

    drawMetricCardInt(8, 45, 75, 40, "LEADS", liveBusiness.total_leads, COLOR_AMBER);
    drawMetricCardInt(87, 45, 75, 40, "HOT", liveBusiness.hot_leads, COLOR_HOT_PINK);
    drawMetricCardInt(166, 45, 75, 40, "DEALS", liveBusiness.deals_pipeline, COLOR_ELECTRIC_BLUE);
    drawMetricCardInt(245, 45, 67, 40, "WON", liveBusiness.won_this_month, COLOR_VIOLET);

    // Stripe Section
    tft.setTextColor(COLOR_ELECTRIC_BLUE);
    tft.setCursor(8, 92);
    tft.print("REVENUE");

    char mrrBuf[16], arrBuf[16];
    sprintf(mrrBuf, "$%dK", liveBusiness.mrr / 1000);
    sprintf(arrBuf, "$%dK", liveBusiness.arr / 1000);

    drawMetricCard(8, 105, 100, 40, "MRR", mrrBuf, COLOR_HOT_PINK);
    drawMetricCard(112, 105, 100, 40, "ARR", arrBuf, COLOR_AMBER);
    drawMetricCardInt(216, 105, 96, 40, "CUSTOMERS", liveBusiness.customers, COLOR_ELECTRIC_BLUE);

    // Linear Section
    tft.setTextColor(COLOR_VIOLET);
    tft.setCursor(8, 152);
    tft.print("LINEAR TASKS");

    drawMetricCardInt(8, 165, 75, 40, "OPEN", liveBusiness.open_issues, COLOR_VIOLET);
    drawMetricCardInt(87, 165, 75, 40, "WIP", liveBusiness.in_progress, COLOR_ELECTRIC_BLUE);
    drawMetricCardInt(166, 165, 75, 40, "DONE", liveBusiness.completed_today, COLOR_AMBER);

    // P1 alert
    if (liveBusiness.p1_issues > 0) {
        tft.setTextColor(COLOR_HOT_PINK);
        tft.fillRoundRect(245, 165, 67, 40, 4, 0x4800);  // Dark red bg
        drawMetricCardInt(245, 165, 67, 40, "P1!", liveBusiness.p1_issues, COLOR_HOT_PINK);
    } else {
        drawMetricCardInt(245, 165, 67, 40, "P1", 0, COLOR_DARK_GRAY);
    }
}

// ═══════════════════════════════════════════════════════════════════
// ALERTS SCREEN - LIVE
// ═══════════════════════════════════════════════════════════════════

void drawAlertsScreen() {
    tft.fillScreen(COLOR_BLACK);
    drawSectionHeader("ALERTS", COLOR_HOT_PINK, true);

    if (liveAlertCount == 0) {
        tft.setTextColor(COLOR_ELECTRIC_BLUE);
        tft.setTextSize(2);
        tft.setCursor(60, 100);
        tft.print("ALL CLEAR");
        tft.setTextSize(1);
        tft.setCursor(80, 130);
        tft.print("No active alerts");
        return;
    }

    for (int i = 0; i < min(liveAlertCount, 5); i++) {
        int y = 32 + (i * 40);

        // Alert level color
        uint16_t levelColor = COLOR_ELECTRIC_BLUE;
        if (strcmp(liveAlerts[i].level, "warning") == 0) levelColor = COLOR_AMBER;
        if (strcmp(liveAlerts[i].level, "critical") == 0) levelColor = COLOR_HOT_PINK;

        // Background
        tft.fillRoundRect(4, y, 312, 36, 4, 0x1082);
        tft.drawRoundRect(4, y, 312, 36, 4, levelColor);

        // Level indicator
        tft.fillCircle(16, y + 18, 6, levelColor);

        // Source
        tft.setTextColor(levelColor);
        tft.setTextSize(1);
        tft.setCursor(28, y + 4);
        tft.print(liveAlerts[i].source);

        // Message
        tft.setTextColor(COLOR_WHITE);
        tft.setCursor(28, y + 18);
        tft.print(liveAlerts[i].message);
    }
}

#endif // LIVE_SCREENS_H
