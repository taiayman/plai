/**
 * Overview Page - Dashboard home with KPI cards and charts
 */

const OverviewPage = {
    charts: {},
    data: null,

    /**
     * Render the overview page
     */
    async render(container) {
        container.innerHTML = `
            <div class="loading-state">
                <div class="spinner"></div>
                <p>Loading dashboard...</p>
            </div>
        `;

        try {
            this.data = await api.getAnalytics();
            container.innerHTML = this.getTemplate();
            this.initCharts();
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
                    <h3>Failed to load dashboard</h3>
                    <p>${error.message}</p>
                    <button class="btn btn-primary mt-lg" onclick="app.navigate('overview')">
                        Try Again
                    </button>
                </div>
            `;
        }
    },

    /**
     * Get the page template
     */
    getTemplate() {
        const { totals, growth, topGamesByPlays, recentGames, topHashtags } = this.data;

        return `
            <!-- Stats Grid -->
            <div class="stats-grid">
                ${this.getStatCard('Users', totals.users, growth.users, 'users')}
                ${this.getStatCard('Games', totals.games, growth.games, 'games')}
                ${this.getStatCard('Total Plays', totals.plays, null, 'plays')}
                ${this.getStatCard('Total Likes', totals.likes, null, 'likes')}
            </div>

            <!-- Charts Row -->
            <div class="grid-2">
                <div class="chart-container">
                    <div class="chart-header">
                        <h3 class="chart-title">User Growth</h3>
                        <span class="text-muted">Last 30 days</span>
                    </div>
                    <div class="chart-wrapper">
                        <canvas id="users-chart"></canvas>
                    </div>
                </div>
                <div class="chart-container">
                    <div class="chart-header">
                        <h3 class="chart-title">Games Created</h3>
                        <span class="text-muted">Last 30 days</span>
                    </div>
                    <div class="chart-wrapper">
                        <canvas id="games-chart"></canvas>
                    </div>
                </div>
            </div>

            <!-- Content Row -->
            <div class="grid-2">
                <!-- Top Games -->
                <div class="card">
                    <div class="card-header">
                        <h3 class="card-title">Top Games by Plays</h3>
                        <a href="#games" class="btn btn-ghost btn-sm">View All</a>
                    </div>
                    <div class="activity-feed">
                        ${topGamesByPlays.length > 0 ? topGamesByPlays.slice(0, 5).map((game, i) => `
                            <div class="activity-item" style="cursor: pointer" onclick="app.viewGame('${game.id}')">
                                <div class="activity-icon blue">
                                    <span style="font-weight: 700">${i + 1}</span>
                                </div>
                                <div class="activity-content">
                                    <p><strong>${this.escapeHtml(game.title)}</strong></p>
                                    <span>by @${game.creator?.username || 'unknown'} • ${ApiClient.formatNumber(game.playCount || 0)} plays</span>
                                </div>
                            </div>
                        `).join('') : '<div class="empty-state"><p>No games yet</p></div>'}
                    </div>
                </div>

                <!-- Recent Activity -->
                <div class="card">
                    <div class="card-header">
                        <h3 class="card-title">Recent Games</h3>
                        <a href="#games" class="btn btn-ghost btn-sm">View All</a>
                    </div>
                    <div class="activity-feed">
                        ${recentGames.length > 0 ? recentGames.slice(0, 5).map(game => `
                            <div class="activity-item" style="cursor: pointer" onclick="app.viewGame('${game.id}')">
                                <div class="activity-icon green">
                                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                        <rect x="2" y="6" width="20" height="12" rx="2"/>
                                        <path d="M6 12h4"/>
                                        <path d="M8 10v4"/>
                                    </svg>
                                </div>
                                <div class="activity-content">
                                    <p><strong>${this.escapeHtml(game.title)}</strong> created</p>
                                    <span>by @${game.creator?.username || 'unknown'} • ${ApiClient.formatTimeAgo(game.createdAt)}</span>
                                </div>
                            </div>
                        `).join('') : '<div class="empty-state"><p>No recent activity</p></div>'}
                    </div>
                </div>
            </div>

            <!-- Hashtags Section -->
            <div class="card mt-lg">
                <div class="card-header">
                    <h3 class="card-title">Popular Hashtags</h3>
                </div>
                <div class="filter-chips" style="padding: 0 var(--spacing-lg) var(--spacing-lg);">
                    ${topHashtags.length > 0 ? topHashtags.map(h => `
                        <span class="chip">${h.tag} (${h.count})</span>
                    `).join('') : '<p class="text-muted">No hashtags yet</p>'}
                </div>
            </div>
        `;
    },

    /**
     * Get stat card HTML
     */
    getStatCard(label, value, change, type) {
        const icons = {
            users: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>',
            games: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="2" y="6" width="20" height="12" rx="2"/><path d="M6 12h4"/><path d="M8 10v4"/><circle cx="17" cy="10" r="1"/><circle cx="15" cy="14" r="1"/></svg>',
            plays: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polygon points="5 3 19 12 5 21 5 3"/></svg>',
            likes: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/></svg>',
        };

        const colors = {
            users: '#5576F8',
            games: '#9B59B6',
            plays: '#5DAE64',
            likes: '#E94F37',
        };

        const changeHtml = change !== null ? `
            <div class="stat-change ${change >= 0 ? 'positive' : 'negative'}">
                ${change >= 0 ? '↑' : '↓'} ${Math.abs(change)}% this week
            </div>
        ` : '';

        return `
            <div class="stat-card" style="--stat-color: ${colors[type]}">
                <div class="stat-icon" style="background: ${colors[type]}15">
                    <svg viewBox="0 0 24 24" fill="none" stroke="${colors[type]}" stroke-width="2">
                        ${icons[type].replace(/<svg[^>]*>|<\/svg>/g, '')}
                    </svg>
                </div>
                <div class="stat-value">${ApiClient.formatNumber(value)}</div>
                <div class="stat-label">${label}</div>
                ${changeHtml}
            </div>
        `;
    },

    /**
     * Initialize charts
     */
    initCharts() {
        const { timeSeries } = this.data;

        // Users chart
        if (timeSeries.users.length > 0) {
            const userData = {
                labels: Charts.formatDateLabels(timeSeries.users.map(d => d.date)),
                values: timeSeries.users.map(d => d.count),
            };
            this.charts.users = Charts.createAreaChart('users-chart', userData);
        }

        // Games chart
        if (timeSeries.games.length > 0) {
            const gamesData = {
                labels: Charts.formatDateLabels(timeSeries.games.map(d => d.date)),
                values: timeSeries.games.map(d => d.count),
            };
            this.charts.games = Charts.createLineChart('games-chart', gamesData);
        }
    },

    /**
     * Cleanup
     */
    destroy() {
        Object.values(this.charts).forEach(chart => Charts.destroy(chart));
        this.charts = {};
    },

    /**
     * Escape HTML to prevent XSS
     */
    escapeHtml(text) {
        const div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML;
    },
};

window.OverviewPage = OverviewPage;
