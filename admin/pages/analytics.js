/**
 * Analytics Page - Detailed analytics and charts
 */

const AnalyticsPage = {
    data: null,
    charts: {},
    dateRange: '30d',

    /**
     * Render the analytics page
     */
    async render(container) {
        container.innerHTML = `
            <div class="loading-state">
                <div class="spinner"></div>
                <p>Loading analytics...</p>
            </div>
        `;

        try {
            this.data = await api.getAnalytics(this.dateRange);
            container.innerHTML = this.getTemplate();
            this.initCharts();
            this.initEventListeners();
        } catch (error) {
            container.innerHTML = `
                <div class="empty-state">
                    <div class="empty-state-icon">
                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <circle cx="12" cy="12" r="10"/>
                            <line x1="12" y1="8" x2="12" y2="12"/>
                            <line x1="12" y1="16" x2="12.01" y2="16"/>
                        </svg>
                    </div>
                    <h3>Failed to load analytics</h3>
                    <p>${error.message}</p>
                </div>
            `;
        }
    },

    /**
     * Get page template
     */
    getTemplate() {
        const { totals, topGamesByPlays, topGamesByLikes, topHashtags } = this.data;

        // Calculate engagement metrics
        const avgPlaysPerGame = totals.games > 0 ? (totals.plays / totals.games).toFixed(1) : 0;
        const avgLikesPerGame = totals.games > 0 ? (totals.likes / totals.games).toFixed(1) : 0;
        const likeRate = totals.plays > 0 ? ((totals.likes / totals.plays) * 100).toFixed(1) : 0;
        const avgGamesPerUser = totals.users > 0 ? (totals.games / totals.users).toFixed(1) : 0;

        return `
            <!-- Date Range Selector -->
            <div class="flex-between mb-lg">
                <h2>Analytics Dashboard</h2>
                <div class="filter-chips">
                    <button class="chip ${this.dateRange === '7d' ? 'active' : ''}" data-range="7d">7 Days</button>
                    <button class="chip ${this.dateRange === '30d' ? 'active' : ''}" data-range="30d">30 Days</button>
                    <button class="chip ${this.dateRange === '90d' ? 'active' : ''}" data-range="90d">90 Days</button>
                </div>
            </div>

            <!-- Engagement Metrics -->
            <div class="stats-grid">
                <div class="stat-card">
                    <div class="stat-value">${avgPlaysPerGame}</div>
                    <div class="stat-label">Avg Plays / Game</div>
                </div>
                <div class="stat-card">
                    <div class="stat-value">${avgLikesPerGame}</div>
                    <div class="stat-label">Avg Likes / Game</div>
                </div>
                <div class="stat-card">
                    <div class="stat-value">${likeRate}%</div>
                    <div class="stat-label">Like Rate</div>
                </div>
                <div class="stat-card">
                    <div class="stat-value">${avgGamesPerUser}</div>
                    <div class="stat-label">Avg Games / User</div>
                </div>
            </div>

            <!-- Charts -->
            <div class="grid-2">
                <div class="chart-container">
                    <div class="chart-header">
                        <h3 class="chart-title">User Growth</h3>
                    </div>
                    <div class="chart-wrapper">
                        <canvas id="analytics-users-chart"></canvas>
                    </div>
                </div>
                <div class="chart-container">
                    <div class="chart-header">
                        <h3 class="chart-title">Games Created</h3>
                    </div>
                    <div class="chart-wrapper">
                        <canvas id="analytics-games-chart"></canvas>
                    </div>
                </div>
            </div>

            <!-- Leaderboards -->
            <div class="grid-2 mt-lg">
                <!-- Top Games by Plays -->
                <div class="card">
                    <div class="card-header">
                        <h3 class="card-title">Top Games by Plays</h3>
                    </div>
                    <div class="activity-feed">
                        ${topGamesByPlays.length > 0 ? topGamesByPlays.map((game, i) => `
                            <div class="activity-item">
                                <div class="activity-icon ${i < 3 ? 'gold' : 'blue'}">
                                    <span style="font-weight: 700; font-size: 12px;">${i + 1}</span>
                                </div>
                                <div class="activity-content" style="flex: 1;">
                                    <p><strong>${this.escapeHtml(game.title)}</strong></p>
                                    <span>by @${game.creator?.username || 'unknown'}</span>
                                </div>
                                <div style="text-align: right;">
                                    <strong>${ApiClient.formatNumber(game.playCount || 0)}</strong>
                                    <span class="text-muted" style="display: block; font-size: 11px;">plays</span>
                                </div>
                            </div>
                        `).join('') : '<div class="empty-state"><p>No games yet</p></div>'}
                    </div>
                </div>

                <!-- Top Games by Likes -->
                <div class="card">
                    <div class="card-header">
                        <h3 class="card-title">Top Games by Likes</h3>
                    </div>
                    <div class="activity-feed">
                        ${topGamesByLikes.length > 0 ? topGamesByLikes.map((game, i) => `
                            <div class="activity-item">
                                <div class="activity-icon ${i < 3 ? 'gold' : 'blue'}">
                                    <span style="font-weight: 700; font-size: 12px;">${i + 1}</span>
                                </div>
                                <div class="activity-content" style="flex: 1;">
                                    <p><strong>${this.escapeHtml(game.title)}</strong></p>
                                    <span>by @${game.creator?.username || 'unknown'}</span>
                                </div>
                                <div style="text-align: right;">
                                    <strong>${ApiClient.formatNumber(game.likeCount || 0)}</strong>
                                    <span class="text-muted" style="display: block; font-size: 11px;">likes</span>
                                </div>
                            </div>
                        `).join('') : '<div class="empty-state"><p>No games yet</p></div>'}
                    </div>
                </div>
            </div>

            <!-- Hashtag Analytics -->
            <div class="card mt-lg">
                <div class="card-header">
                    <h3 class="card-title">Hashtag Analytics</h3>
                </div>
                <div style="padding: 0 var(--spacing-lg) var(--spacing-lg);">
                    ${topHashtags.length > 0 ? `
                        <div class="chart-wrapper" style="height: 200px;">
                            <canvas id="hashtag-chart"></canvas>
                        </div>
                    ` : '<div class="empty-state"><p>No hashtags yet</p></div>'}
                </div>
            </div>
        `;
    },

    /**
     * Initialize charts
     */
    initCharts() {
        const { timeSeries, topHashtags } = this.data;

        // Destroy existing charts
        Object.values(this.charts).forEach(chart => Charts.destroy(chart));
        this.charts = {};

        // Users chart
        if (timeSeries.users.length > 0) {
            const userData = {
                labels: Charts.formatDateLabels(timeSeries.users.map(d => d.date)),
                values: timeSeries.users.map(d => d.count),
            };
            this.charts.users = Charts.createAreaChart('analytics-users-chart', userData);
        }

        // Games chart
        if (timeSeries.games.length > 0) {
            const gamesData = {
                labels: Charts.formatDateLabels(timeSeries.games.map(d => d.date)),
                values: timeSeries.games.map(d => d.count),
            };
            this.charts.games = Charts.createLineChart('analytics-games-chart', gamesData);
        }

        // Hashtag chart
        if (topHashtags.length > 0) {
            const hashtagData = {
                labels: topHashtags.map(h => h.tag),
                values: topHashtags.map(h => h.count),
                colors: [
                    '#5576F8',
                    '#5DAE64',
                    '#E94F37',
                    '#FFC107',
                    '#9B59B6',
                    '#FF9500',
                    '#00CED1',
                    '#FF69B4',
                    '#32CD32',
                    '#BA55D3',
                ],
            };
            this.charts.hashtags = Charts.createBarChart('hashtag-chart', hashtagData);
        }
    },

    /**
     * Initialize event listeners
     */
    initEventListeners() {
        document.querySelectorAll('[data-range]').forEach(btn => {
            btn.addEventListener('click', async () => {
                this.dateRange = btn.dataset.range;
                const container = document.getElementById('content-area');
                await this.render(container);
            });
        });
    },

    /**
     * Cleanup
     */
    destroy() {
        Object.values(this.charts).forEach(chart => Charts.destroy(chart));
        this.charts = {};
    },

    /**
     * Escape HTML
     */
    escapeHtml(text) {
        const div = document.createElement('div');
        div.textContent = text || '';
        return div.innerHTML;
    },
};

window.AnalyticsPage = AnalyticsPage;
