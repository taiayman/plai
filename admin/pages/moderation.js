/**
 * Moderation Page - Content moderation queue
 */

const ModerationPage = {
    queue: [],
    log: [],

    /**
     * Render the moderation page
     */
    async render(container) {
        container.innerHTML = `
            <div class="loading-state">
                <div class="spinner"></div>
                <p>Loading moderation queue...</p>
            </div>
        `;

        try {
            await this.loadData();
            container.innerHTML = this.getTemplate();
            this.initEventListeners();
        } catch (error) {
            // If endpoints don't exist yet, show empty state
            container.innerHTML = this.getEmptyTemplate();
        }
    },

    /**
     * Load moderation data
     */
    async loadData() {
        // For now, we'll get flagged games from the games list
        const gamesData = await api.getGames();
        const games = gamesData.games || [];

        // Filter flagged games as our "queue"
        this.queue = games.filter(g => g.isFlagged);

        // Mock moderation log for now
        this.log = [];
    },

    /**
     * Get page template
     */
    getTemplate() {
        return `
            <!-- Queue Stats -->
            <div class="stats-grid" style="grid-template-columns: repeat(3, 1fr);">
                <div class="stat-card" style="--stat-color: #E94F37;">
                    <div class="stat-value">${this.queue.length}</div>
                    <div class="stat-label">Pending Review</div>
                </div>
                <div class="stat-card" style="--stat-color: #5DAE64;">
                    <div class="stat-value">0</div>
                    <div class="stat-label">Approved Today</div>
                </div>
                <div class="stat-card" style="--stat-color: #FFC107;">
                    <div class="stat-value">0</div>
                    <div class="stat-label">Removed Today</div>
                </div>
            </div>

            <!-- Moderation Queue -->
            <div class="card">
                <div class="card-header">
                    <h3 class="card-title">Flagged Content Queue</h3>
                    <span class="badge badge-red">${this.queue.length} pending</span>
                </div>

                ${this.queue.length > 0 ? `
                    <div class="activity-feed">
                        ${this.queue.map(game => `
                            <div class="activity-item" style="padding: 20px;">
                                <img class="game-thumb" src="${game.thumbnailUrl || 'https://picsum.photos/60/80'}" alt="" onerror="this.src='https://picsum.photos/60/80'">
                                <div class="activity-content" style="flex: 1;">
                                    <p><strong>${this.escapeHtml(game.title || 'Untitled')}</strong></p>
                                    <span>by @${game.creator?.username || 'unknown'} • ${ApiClient.formatTimeAgo(game.createdAt)}</span>
                                    <div style="margin-top: 8px;">
                                        ${(game.hashtags || []).map(tag => `<span class="badge badge-gray" style="margin-right: 4px;">${tag}</span>`).join('')}
                                    </div>
                                </div>
                                <div class="flex gap-sm">
                                    <button class="btn btn-ghost btn-sm" onclick="ModerationPage.previewGame('${game.id}')" title="Preview">
                                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" width="16" height="16">
                                            <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/>
                                            <circle cx="12" cy="12" r="3"/>
                                        </svg>
                                    </button>
                                    <button class="btn btn-success btn-sm" onclick="ModerationPage.approveGame('${game.id}')">Approve</button>
                                    <button class="btn btn-danger btn-sm" onclick="ModerationPage.removeGame('${game.id}')">Remove</button>
                                </div>
                            </div>
                        `).join('')}
                    </div>
                ` : `
                    <div class="empty-state" style="padding: 48px;">
                        <div class="empty-state-icon">
                            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/>
                            </svg>
                        </div>
                        <h3>All Clear!</h3>
                        <p>No content flagged for review</p>
                    </div>
                `}
            </div>

            <!-- Moderation Log -->
            <div class="card mt-lg">
                <div class="card-header">
                    <h3 class="card-title">Recent Moderation Actions</h3>
                </div>

                ${this.log.length > 0 ? `
                    <div class="activity-feed">
                        ${this.log.map(entry => `
                            <div class="activity-item">
                                <div class="activity-icon ${entry.action === 'approved' ? 'green' : 'red'}">
                                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" width="16" height="16">
                                        ${entry.action === 'approved'
                                            ? '<polyline points="20 6 9 17 4 12"/>'
                                            : '<line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/>'
                                        }
                                    </svg>
                                </div>
                                <div class="activity-content">
                                    <p><strong>${entry.gameTitle}</strong> was ${entry.action}</p>
                                    <span>${entry.reason} • ${ApiClient.formatTimeAgo(entry.timestamp)}</span>
                                </div>
                            </div>
                        `).join('')}
                    </div>
                ` : `
                    <div class="empty-state" style="padding: 32px;">
                        <p class="text-muted">No moderation actions yet</p>
                    </div>
                `}
            </div>

            <!-- Moderation Guidelines -->
            <div class="card mt-lg">
                <div class="card-header">
                    <h3 class="card-title">Moderation Guidelines</h3>
                </div>
                <div style="padding: 0 var(--spacing-lg) var(--spacing-lg);">
                    <ul style="color: var(--text-secondary); line-height: 2;">
                        <li><strong>Remove</strong> content that contains: violence, hate speech, adult content, spam, or copyright violations</li>
                        <li><strong>Approve</strong> content that is safe and follows community guidelines</li>
                        <li><strong>Warn</strong> creators for minor violations before banning</li>
                        <li>When in doubt, escalate to the admin team</li>
                    </ul>
                </div>
            </div>
        `;
    },

    /**
     * Get empty template when moderation isn't set up
     */
    getEmptyTemplate() {
        return `
            <div class="card">
                <div class="card-header">
                    <h3 class="card-title">Content Moderation</h3>
                </div>
                <div class="empty-state" style="padding: 64px;">
                    <div class="empty-state-icon">
                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/>
                        </svg>
                    </div>
                    <h3>Moderation System</h3>
                    <p>The moderation queue shows games that have been flagged for review.<br>
                    Flag games from the Games page to add them to this queue.</p>
                </div>
            </div>

            <!-- How to Flag Content -->
            <div class="card mt-lg">
                <div class="card-header">
                    <h3 class="card-title">How to Flag Content</h3>
                </div>
                <div style="padding: 0 var(--spacing-lg) var(--spacing-lg);">
                    <ol style="color: var(--text-secondary); line-height: 2.5; padding-left: 20px;">
                        <li>Go to the <a href="#games">Games</a> page</li>
                        <li>Find the game you want to flag</li>
                        <li>Click the flag icon in the actions column</li>
                        <li>The game will appear in this moderation queue</li>
                    </ol>
                </div>
            </div>
        `;
    },

    /**
     * Initialize event listeners
     */
    initEventListeners() {
        // Add any specific event listeners here
    },

    /**
     * Preview game
     */
    previewGame(gameId) {
        GamesPage.viewGame(gameId);
    },

    /**
     * Approve game (remove flag)
     */
    async approveGame(gameId) {
        try {
            await api.flagGame(gameId, false);
            Toast.show('Game approved and removed from queue', 'success');

            // Add to log
            const game = this.queue.find(g => g.id === gameId);
            if (game) {
                this.log.unshift({
                    gameTitle: game.title,
                    action: 'approved',
                    reason: 'Content verified as safe',
                    timestamp: new Date().toISOString(),
                });
            }

            // Remove from queue
            this.queue = this.queue.filter(g => g.id !== gameId);
            this.refresh();

            // Update moderation badge
            this.updateBadge();
        } catch (error) {
            Toast.show('Failed to approve game: ' + error.message, 'error');
        }
    },

    /**
     * Remove game
     */
    async removeGame(gameId) {
        const game = this.queue.find(g => g.id === gameId);
        const confirmed = await Modal.confirm(
            'Remove Game',
            `Are you sure you want to remove "${game?.title || 'this game'}"? This will permanently delete the game.`,
            'Remove',
            true
        );

        if (!confirmed) return;

        try {
            await api.deleteGame(gameId);
            Toast.show('Game removed successfully', 'success');

            // Add to log
            if (game) {
                this.log.unshift({
                    gameTitle: game.title,
                    action: 'removed',
                    reason: 'Violated community guidelines',
                    timestamp: new Date().toISOString(),
                });
            }

            // Remove from queue
            this.queue = this.queue.filter(g => g.id !== gameId);
            this.refresh();

            // Update moderation badge
            this.updateBadge();
        } catch (error) {
            Toast.show('Failed to remove game: ' + error.message, 'error');
        }
    },

    /**
     * Refresh the page
     */
    refresh() {
        const container = document.getElementById('content-area');
        container.innerHTML = this.getTemplate();
        this.initEventListeners();
    },

    /**
     * Update the moderation badge in sidebar
     */
    updateBadge() {
        const badge = document.getElementById('moderation-badge');
        if (badge) {
            badge.textContent = this.queue.length;
            badge.style.display = this.queue.length > 0 ? 'inline-block' : 'none';
        }
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

window.ModerationPage = ModerationPage;
