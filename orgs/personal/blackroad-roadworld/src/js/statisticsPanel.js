// Statistics Panel for RoadWorld
// Displays comprehensive player statistics and progress

export class StatisticsPanel {
    constructor(gameEngine, achievementsManager, missionsManager) {
        this.gameEngine = gameEngine;
        this.achievementsManager = achievementsManager;
        this.missionsManager = missionsManager;
        this.panelElement = null;
        this.isVisible = false;
    }

    init() {
        this.createPanel();
        this.setupEventListeners();

        console.log('📊 Statistics Panel initialized');
    }

    createPanel() {
        this.panelElement = document.createElement('div');
        this.panelElement.className = 'statistics-panel ui-overlay';
        this.panelElement.id = 'statistics-panel';
        this.panelElement.style.display = 'none';

        this.panelElement.innerHTML = `
            <div class="panel-header">
                <span>Player Statistics</span>
                <button class="panel-close" id="stats-close">✕</button>
            </div>
            <div class="panel-content stats-content">
                <div class="stats-tabs">
                    <button class="stats-tab active" data-tab="overview">Overview</button>
                    <button class="stats-tab" data-tab="achievements">Achievements</button>
                    <button class="stats-tab" data-tab="missions">Missions</button>
                    <button class="stats-tab" data-tab="inventory">Inventory</button>
                </div>

                <div class="stats-tab-content" id="tab-overview">
                    <div class="stats-profile" id="stats-profile"></div>
                    <div class="stats-grid" id="stats-grid"></div>
                    <div class="stats-chart" id="stats-chart"></div>
                </div>

                <div class="stats-tab-content" id="tab-achievements" style="display: none;">
                    <div class="achievements-progress" id="achievements-progress"></div>
                    <div class="achievements-grid" id="achievements-grid"></div>
                </div>

                <div class="stats-tab-content" id="tab-missions" style="display: none;">
                    <div class="missions-header" id="missions-header"></div>
                    <div class="missions-list" id="missions-list"></div>
                </div>

                <div class="stats-tab-content" id="tab-inventory" style="display: none;">
                    <div class="inventory-summary" id="inventory-summary"></div>
                    <div class="inventory-details" id="inventory-details"></div>
                </div>
            </div>
        `;

        document.body.appendChild(this.panelElement);
    }

    setupEventListeners() {
        // Close button
        document.getElementById('stats-close').addEventListener('click', () => {
            this.hide();
        });

        // Tab switching
        this.panelElement.querySelectorAll('.stats-tab').forEach(tab => {
            tab.addEventListener('click', (e) => {
                const tabName = e.target.dataset.tab;
                this.switchTab(tabName);
            });
        });
    }

    switchTab(tabName) {
        // Update active tab button
        this.panelElement.querySelectorAll('.stats-tab').forEach(tab => {
            tab.classList.toggle('active', tab.dataset.tab === tabName);
        });

        // Show/hide tab content
        this.panelElement.querySelectorAll('.stats-tab-content').forEach(content => {
            content.style.display = content.id === `tab-${tabName}` ? 'block' : 'none';
        });

        // Refresh content
        this.refreshTab(tabName);
    }

    refreshTab(tabName) {
        switch (tabName) {
            case 'overview':
                this.renderOverview();
                break;
            case 'achievements':
                this.renderAchievements();
                break;
            case 'missions':
                this.renderMissions();
                break;
            case 'inventory':
                this.renderInventory();
                break;
        }
    }

    renderOverview() {
        const player = this.gameEngine.player;
        const stats = this.gameEngine.getPlayerStats();

        // Profile section
        document.getElementById('stats-profile').innerHTML = `
            <div class="profile-avatar" style="background: ${player.avatar.color}">
                <span class="profile-icon">🧑‍🚀</span>
            </div>
            <div class="profile-info">
                <div class="profile-name">${player.username}</div>
                <div class="profile-level">Level ${player.level}</div>
                <div class="profile-xp-bar">
                    <div class="profile-xp-fill" style="width: ${stats.xpProgress}%"></div>
                </div>
                <div class="profile-xp-text">${player.xp} / ${player.xpToNextLevel} XP</div>
            </div>
        `;

        // Stats grid
        const playTimeHours = Math.floor(player.stats.playTime / 3600000);
        const playTimeMinutes = Math.floor((player.stats.playTime % 3600000) / 60000);
        const distanceKm = (player.stats.distanceTraveled / 1000).toFixed(2);

        document.getElementById('stats-grid').innerHTML = `
            <div class="stat-card">
                <div class="stat-card-icon">🚶</div>
                <div class="stat-card-value">${distanceKm} km</div>
                <div class="stat-card-label">Distance Traveled</div>
            </div>
            <div class="stat-card">
                <div class="stat-card-icon">✨</div>
                <div class="stat-card-value">${player.stats.itemsCollected}</div>
                <div class="stat-card-label">Items Collected</div>
            </div>
            <div class="stat-card">
                <div class="stat-card-icon">🏆</div>
                <div class="stat-card-value">${this.achievementsManager?.unlockedAchievements.size || 0}</div>
                <div class="stat-card-label">Achievements</div>
            </div>
            <div class="stat-card">
                <div class="stat-card-icon">⏱️</div>
                <div class="stat-card-value">${playTimeHours}h ${playTimeMinutes}m</div>
                <div class="stat-card-label">Play Time</div>
            </div>
            <div class="stat-card">
                <div class="stat-card-icon">📍</div>
                <div class="stat-card-value">${player.stats.locationsDiscovered}</div>
                <div class="stat-card-label">Locations Found</div>
            </div>
            <div class="stat-card">
                <div class="stat-card-icon">🎯</div>
                <div class="stat-card-value">${player.stats.missionsCompleted}</div>
                <div class="stat-card-label">Missions Done</div>
            </div>
        `;
    }

    renderAchievements() {
        if (!this.achievementsManager) return;

        const progress = this.achievementsManager.getAchievementProgress();
        const achievements = this.achievementsManager.getAllAchievements();

        // Progress bar
        document.getElementById('achievements-progress').innerHTML = `
            <div class="achievements-progress-bar">
                <div class="achievements-progress-fill" style="width: ${progress.percentage}%"></div>
            </div>
            <div class="achievements-progress-text">
                ${progress.unlocked} / ${progress.total} Achievements (${progress.percentage}%)
            </div>
        `;

        // Achievement categories
        const categories = ['explorer', 'collector', 'level', 'time', 'special'];
        let gridHTML = '';

        categories.forEach(category => {
            const categoryAchievements = achievements.filter(a => a.category === category);
            if (categoryAchievements.length === 0) return;

            gridHTML += `
                <div class="achievement-category">
                    <h4>${category.charAt(0).toUpperCase() + category.slice(1)}</h4>
                    <div class="achievement-list">
                        ${categoryAchievements.map(a => `
                            <div class="achievement-item ${a.unlocked ? 'unlocked' : 'locked'} ${a.rarity}">
                                <div class="achievement-icon">${a.icon}</div>
                                <div class="achievement-info">
                                    <div class="achievement-name">${a.name}</div>
                                    <div class="achievement-desc">${a.description}</div>
                                </div>
                                <div class="achievement-reward">+${a.xpReward} XP</div>
                            </div>
                        `).join('')}
                    </div>
                </div>
            `;
        });

        document.getElementById('achievements-grid').innerHTML = gridHTML;
    }

    renderMissions() {
        if (!this.missionsManager) return;

        const missions = this.missionsManager.getMissions();
        const timeUntilReset = this.missionsManager.getTimeUntilReset();
        const claimableCount = this.missionsManager.getClaimableCount();

        // Header with reset timer
        document.getElementById('missions-header').innerHTML = `
            <div class="missions-timer">
                <span class="timer-icon">⏰</span>
                <span>Resets in ${timeUntilReset.formatted}</span>
            </div>
            ${claimableCount > 0 ? `<div class="missions-claimable">${claimableCount} reward${claimableCount > 1 ? 's' : ''} available!</div>` : ''}
        `;

        // Mission list
        if (missions.length === 0) {
            document.getElementById('missions-list').innerHTML = `
                <div class="missions-empty">No active missions. Check back tomorrow!</div>
            `;
            return;
        }

        document.getElementById('missions-list').innerHTML = missions.map(mission => {
            const progressPercent = Math.min(100, (mission.progress / mission.target) * 100);

            return `
                <div class="mission-item ${mission.completed ? 'completed' : ''} ${mission.claimed ? 'claimed' : ''}">
                    <div class="mission-icon">${mission.icon}</div>
                    <div class="mission-info">
                        <div class="mission-name">${mission.name}</div>
                        <div class="mission-desc">${mission.description}</div>
                        <div class="mission-progress-bar">
                            <div class="mission-progress-fill" style="width: ${progressPercent}%"></div>
                        </div>
                        <div class="mission-progress-text">${mission.progress.toFixed(0)} / ${mission.target}</div>
                    </div>
                    <div class="mission-reward">
                        ${mission.claimed ? '✓ Claimed' :
                          mission.completed ? `<button class="claim-btn" data-mission="${mission.id}">Claim ${mission.xpReward} XP</button>` :
                          `+${mission.xpReward} XP`}
                    </div>
                </div>
            `;
        }).join('');

        // Add claim button handlers
        this.panelElement.querySelectorAll('.claim-btn').forEach(btn => {
            btn.addEventListener('click', (e) => {
                const missionId = e.target.dataset.mission;
                this.missionsManager.claimMissionReward(missionId);
                this.renderMissions();
            });
        });
    }

    renderInventory() {
        const inventory = this.gameEngine.getInventorySummary();
        const items = this.gameEngine.player.inventory.items || [];

        // Summary
        document.getElementById('inventory-summary').innerHTML = `
            <div class="inventory-grid">
                <div class="inventory-item-card">
                    <span class="inv-icon">⭐</span>
                    <span class="inv-count">${inventory.stars}</span>
                    <span class="inv-label">Stars</span>
                </div>
                <div class="inventory-item-card">
                    <span class="inv-icon">💎</span>
                    <span class="inv-count">${inventory.gems}</span>
                    <span class="inv-label">Gems</span>
                </div>
                <div class="inventory-item-card">
                    <span class="inv-icon">🏆</span>
                    <span class="inv-count">${inventory.trophies}</span>
                    <span class="inv-label">Trophies</span>
                </div>
                <div class="inventory-item-card">
                    <span class="inv-icon">🗝️</span>
                    <span class="inv-count">${inventory.keys}</span>
                    <span class="inv-label">Keys</span>
                </div>
            </div>
            <div class="inventory-total">
                Total Items: ${inventory.total}
            </div>
        `;

        // Recent items
        const recentItems = items.slice(-10).reverse();
        document.getElementById('inventory-details').innerHTML = `
            <h4>Recent Finds</h4>
            <div class="recent-items">
                ${recentItems.length === 0 ? '<div class="no-items">No items collected yet</div>' :
                  recentItems.map(item => `
                    <div class="recent-item ${item.rarity}">
                        <span class="recent-item-icon">${item.icon}</span>
                        <span class="recent-item-type">${item.type}</span>
                        <span class="recent-item-rarity">${item.rarity}</span>
                    </div>
                  `).join('')}
            </div>
        `;
    }

    show() {
        this.isVisible = true;
        this.panelElement.style.display = 'block';
        this.switchTab('overview');
    }

    hide() {
        this.isVisible = false;
        this.panelElement.style.display = 'none';
    }

    toggle() {
        if (this.isVisible) {
            this.hide();
        } else {
            this.show();
        }
    }
}
