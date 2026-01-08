/**
 * Games Page - Game management
 */

const GamesPage = {
    games: [],
    filteredGames: [],
    currentFilter: 'all',
    searchQuery: '',
    currentPage: 1,
    pageSize: 20,
    selectedGame: null,

    /**
     * Render the games page
     */
    async render(container) {
        container.innerHTML = `
            <div class="loading-state">
                <div class="spinner"></div>
                <p>Loading games...</p>
            </div>
        `;

        try {
            await this.loadGames();
            container.innerHTML = this.getTemplate();
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
                    <h3>Failed to load games</h3>
                    <p>${error.message}</p>
                </div>
            `;
        }
    },

    /**
     * Load games from API
     */
    async loadGames() {
        const data = await api.getGames();
        this.games = data.games || [];
        this.applyFilters();
    },

    /**
     * Apply filters and search
     */
    applyFilters() {
        let filtered = [...this.games];

        // Apply filter
        if (this.currentFilter === 'featured') {
            filtered = filtered.filter(g => g.isFeatured);
        } else if (this.currentFilter === 'flagged') {
            filtered = filtered.filter(g => g.isFlagged);
        }

        // Apply search
        if (this.searchQuery) {
            const query = this.searchQuery.toLowerCase();
            filtered = filtered.filter(g =>
                (g.title || '').toLowerCase().includes(query) ||
                (g.description || '').toLowerCase().includes(query) ||
                (g.creator?.username || '').toLowerCase().includes(query) ||
                (g.hashtags || []).some(h => h.toLowerCase().includes(query))
            );
        }

        this.filteredGames = filtered;
        this.currentPage = 1;
    },

    /**
     * Get paginated games
     */
    getPaginatedGames() {
        const start = (this.currentPage - 1) * this.pageSize;
        const end = start + this.pageSize;
        return this.filteredGames.slice(start, end);
    },

    /**
     * Get total pages
     */
    getTotalPages() {
        return Math.ceil(this.filteredGames.length / this.pageSize);
    },

    /**
     * Get page template
     */
    getTemplate() {
        const paginatedGames = this.getPaginatedGames();
        const totalPages = this.getTotalPages();

        return `
            <div class="table-container">
                <div class="table-header">
                    <h2 class="table-title">Games (${this.filteredGames.length})</h2>
                    <div class="table-actions">
                        <div class="filter-chips">
                            <button class="chip ${this.currentFilter === 'all' ? 'active' : ''}" data-filter="all">All</button>
                            <button class="chip ${this.currentFilter === 'featured' ? 'active' : ''}" data-filter="featured">Featured</button>
                            <button class="chip ${this.currentFilter === 'flagged' ? 'active' : ''}" data-filter="flagged">Flagged</button>
                        </div>
                        <div class="search-input">
                            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <circle cx="11" cy="11" r="8"/>
                                <path d="m21 21-4.35-4.35"/>
                            </svg>
                            <input type="search" id="game-search" placeholder="Search games..." value="${this.searchQuery}">
                        </div>
                    </div>
                </div>

                <div class="table-scroll">
                    <table>
                        <thead>
                            <tr>
                                <th>Game</th>
                                <th>Creator</th>
                                <th>Plays</th>
                                <th>Likes</th>
                                <th>Created</th>
                                <th>Status</th>
                                <th>Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            ${paginatedGames.length > 0 ? paginatedGames.map(game => `
                                <tr>
                                    <td>
                                        <div class="user-row">
                                            <img class="game-thumb" src="${game.thumbnailUrl || 'https://picsum.photos/60/80'}" alt="" onerror="this.src='https://picsum.photos/60/80'">
                                            <div class="user-info">
                                                <span class="username">${this.escapeHtml(game.title || 'Untitled')}</span>
                                                <span class="email">${(game.hashtags || []).slice(0, 3).join(' ')}</span>
                                            </div>
                                        </div>
                                    </td>
                                    <td>@${game.creator?.username || 'unknown'}</td>
                                    <td>${ApiClient.formatNumber(game.playCount || 0)}</td>
                                    <td>${ApiClient.formatNumber(game.likeCount || 0)}</td>
                                    <td>${ApiClient.formatTimeAgo(game.createdAt)}</td>
                                    <td>
                                        <div class="flex gap-sm">
                                            ${game.isFeatured ? '<span class="badge badge-gold">Featured</span>' : ''}
                                            ${game.isFlagged ? '<span class="badge badge-red">Flagged</span>' : ''}
                                            ${!game.isFeatured && !game.isFlagged ? '<span class="badge badge-gray">Normal</span>' : ''}
                                        </div>
                                    </td>
                                    <td>
                                        <div class="flex gap-sm">
                                            <button class="btn btn-ghost btn-sm" onclick="GamesPage.viewGame('${game.id}')" title="Preview Game">
                                                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" width="16" height="16">
                                                    <polygon points="5 3 19 12 5 21 5 3"/>
                                                </svg>
                                            </button>
                                            <button class="btn btn-ghost btn-sm" onclick="GamesPage.toggleFeatured('${game.id}', ${!game.isFeatured})" title="${game.isFeatured ? 'Remove from Featured' : 'Feature Game'}">
                                                <svg viewBox="0 0 24 24" fill="${game.isFeatured ? '#FFC107' : 'none'}" stroke="${game.isFeatured ? '#FFC107' : 'currentColor'}" stroke-width="2" width="16" height="16">
                                                    <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/>
                                                </svg>
                                            </button>
                                            <button class="btn btn-danger btn-sm" onclick="GamesPage.deleteGame('${game.id}')" title="Delete Game">
                                                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" width="16" height="16">
                                                    <polyline points="3 6 5 6 21 6"/>
                                                    <path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/>
                                                </svg>
                                            </button>
                                        </div>
                                    </td>
                                </tr>
                            `).join('') : `
                                <tr>
                                    <td colspan="7" style="text-align: center; padding: 48px;">
                                        <div class="empty-state">
                                            <h3>No games found</h3>
                                            <p>Try adjusting your search or filters</p>
                                        </div>
                                    </td>
                                </tr>
                            `}
                        </tbody>
                    </table>
                </div>

                ${totalPages > 1 ? `
                    <div class="table-footer">
                        <span>Showing ${(this.currentPage - 1) * this.pageSize + 1}-${Math.min(this.currentPage * this.pageSize, this.filteredGames.length)} of ${this.filteredGames.length}</span>
                        <div class="pagination">
                            <button ${this.currentPage === 1 ? 'disabled' : ''} onclick="GamesPage.goToPage(${this.currentPage - 1})">←</button>
                            ${this.getPaginationButtons(totalPages)}
                            <button ${this.currentPage === totalPages ? 'disabled' : ''} onclick="GamesPage.goToPage(${this.currentPage + 1})">→</button>
                        </div>
                    </div>
                ` : ''}
            </div>
        `;
    },

    /**
     * Get pagination buttons
     */
    getPaginationButtons(total) {
        const buttons = [];
        const current = this.currentPage;

        for (let i = 1; i <= total; i++) {
            if (i === 1 || i === total || (i >= current - 1 && i <= current + 1)) {
                buttons.push(`<button class="${i === current ? 'active' : ''}" onclick="GamesPage.goToPage(${i})">${i}</button>`);
            } else if (buttons[buttons.length - 1] !== '...') {
                buttons.push('...');
            }
        }

        return buttons.map(b => b === '...' ? '<span style="padding: 0 8px">...</span>' : b).join('');
    },

    /**
     * Initialize event listeners
     */
    initEventListeners() {
        // Filter chips
        document.querySelectorAll('[data-filter]').forEach(btn => {
            btn.addEventListener('click', () => {
                this.currentFilter = btn.dataset.filter;
                this.applyFilters();
                this.refresh();
            });
        });

        // Search
        const searchInput = document.getElementById('game-search');
        if (searchInput) {
            let timeout;
            searchInput.addEventListener('input', (e) => {
                clearTimeout(timeout);
                timeout = setTimeout(() => {
                    this.searchQuery = e.target.value;
                    this.applyFilters();
                    this.refresh();
                }, 300);
            });
        }
    },

    /**
     * Refresh the table
     */
    refresh() {
        const container = document.getElementById('content-area');
        container.innerHTML = this.getTemplate();
        this.initEventListeners();
    },

    /**
     * Go to page
     */
    goToPage(page) {
        this.currentPage = page;
        this.refresh();
    },

    /**
     * View game in modal
     */
    async viewGame(gameId) {
        const game = this.games.find(g => g.id === gameId);
        if (!game) return;

        this.selectedGame = game;

        // Update modal title
        document.getElementById('game-modal-title').textContent = game.title || 'Game Preview';

        // Load game in iframe
        const iframe = document.getElementById('game-iframe');
        if (game.gameUrl) {
            // Check if it's HTML content or a URL
            if (game.gameUrl.startsWith('<') || game.gameUrl.includes('<!DOCTYPE')) {
                iframe.srcdoc = game.gameUrl;
            } else {
                iframe.src = game.gameUrl;
            }
        } else {
            iframe.srcdoc = '<div style="display:flex;align-items:center;justify-content:center;height:100%;background:#1a1a2e;color:#fff;">No game content available</div>';
        }

        // Update game info
        document.getElementById('game-info').innerHTML = `
            <div class="game-info-item">
                <label>Creator</label>
                <span>@${game.creator?.username || 'unknown'}</span>
            </div>
            <div class="game-info-item">
                <label>Plays</label>
                <span>${ApiClient.formatNumber(game.playCount || 0)}</span>
            </div>
            <div class="game-info-item">
                <label>Likes</label>
                <span>${ApiClient.formatNumber(game.likeCount || 0)}</span>
            </div>
            <div class="game-info-item">
                <label>Created</label>
                <span>${ApiClient.formatDate(game.createdAt)}</span>
            </div>
            <div class="game-info-item" style="grid-column: span 2;">
                <label>Description</label>
                <span>${this.escapeHtml(game.description || 'No description')}</span>
            </div>
            <div class="game-info-item" style="grid-column: span 2;">
                <label>Hashtags</label>
                <span>${(game.hashtags || []).join(' ') || 'None'}</span>
            </div>
        `;

        // Update delete button
        document.getElementById('delete-game-btn').onclick = () => {
            Modal.hide('game-modal');
            this.deleteGame(gameId);
        };

        Modal.show('game-modal');
    },

    /**
     * Toggle game featured status
     */
    async toggleFeatured(gameId, isFeatured) {
        try {
            await api.toggleFeatured(gameId, isFeatured);
            Toast.show(isFeatured ? 'Game featured successfully' : 'Game removed from featured', 'success');

            // Update local data
            const game = this.games.find(g => g.id === gameId);
            if (game) game.isFeatured = isFeatured;
            this.refresh();
        } catch (error) {
            Toast.show('Failed to update game: ' + error.message, 'error');
        }
    },

    /**
     * Delete game
     */
    async deleteGame(gameId) {
        const game = this.games.find(g => g.id === gameId);
        const confirmed = await Modal.confirm(
            'Delete Game',
            `Are you sure you want to delete "${game?.title || 'this game'}"? This action cannot be undone.`,
            'Delete',
            true
        );

        if (!confirmed) return;

        try {
            await api.deleteGame(gameId);
            Toast.show('Game deleted successfully', 'success');

            // Remove from local data
            this.games = this.games.filter(g => g.id !== gameId);
            this.applyFilters();
            this.refresh();
        } catch (error) {
            Toast.show('Failed to delete game: ' + error.message, 'error');
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

window.GamesPage = GamesPage;
