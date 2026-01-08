/**
 * Users Page - User management
 */

const UsersPage = {
    users: [],
    filteredUsers: [],
    currentFilter: 'all',
    searchQuery: '',
    currentPage: 1,
    pageSize: 20,

    /**
     * Render the users page
     */
    async render(container) {
        container.innerHTML = `
            <div class="loading-state">
                <div class="spinner"></div>
                <p>Loading users...</p>
            </div>
        `;

        try {
            await this.loadUsers();
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
                    <h3>Failed to load users</h3>
                    <p>${error.message}</p>
                </div>
            `;
        }
    },

    /**
     * Load users from API
     */
    async loadUsers() {
        const data = await api.getAnalytics();
        // Get users from the analytics data (recentUsers includes all for now)
        const gamesData = await api.getGames();
        const games = gamesData.games || [];

        // Extract unique users from games
        const userMap = new Map();
        games.forEach(game => {
            if (game.creator && game.creator.id) {
                const userId = game.creator.id;
                if (!userMap.has(userId)) {
                    userMap.set(userId, {
                        ...game.creator,
                        gamesCount: 0,
                        totalPlays: 0,
                        totalLikes: 0,
                    });
                }
                const user = userMap.get(userId);
                user.gamesCount++;
                user.totalPlays += game.playCount || 0;
                user.totalLikes += game.likeCount || 0;
            }
        });

        this.users = Array.from(userMap.values());
        this.applyFilters();
    },

    /**
     * Apply filters and search
     */
    applyFilters() {
        let filtered = [...this.users];

        // Apply filter
        if (this.currentFilter === 'verified') {
            filtered = filtered.filter(u => u.isVerified);
        } else if (this.currentFilter === 'banned') {
            filtered = filtered.filter(u => u.isBanned);
        }

        // Apply search
        if (this.searchQuery) {
            const query = this.searchQuery.toLowerCase();
            filtered = filtered.filter(u =>
                (u.username || '').toLowerCase().includes(query) ||
                (u.displayName || '').toLowerCase().includes(query)
            );
        }

        this.filteredUsers = filtered;
        this.currentPage = 1;
    },

    /**
     * Get paginated users
     */
    getPaginatedUsers() {
        const start = (this.currentPage - 1) * this.pageSize;
        const end = start + this.pageSize;
        return this.filteredUsers.slice(start, end);
    },

    /**
     * Get total pages
     */
    getTotalPages() {
        return Math.ceil(this.filteredUsers.length / this.pageSize);
    },

    /**
     * Get page template
     */
    getTemplate() {
        const paginatedUsers = this.getPaginatedUsers();
        const totalPages = this.getTotalPages();

        return `
            <div class="table-container">
                <div class="table-header">
                    <h2 class="table-title">Users (${this.filteredUsers.length})</h2>
                    <div class="table-actions">
                        <div class="filter-chips">
                            <button class="chip ${this.currentFilter === 'all' ? 'active' : ''}" data-filter="all">All</button>
                            <button class="chip ${this.currentFilter === 'verified' ? 'active' : ''}" data-filter="verified">Verified</button>
                            <button class="chip ${this.currentFilter === 'banned' ? 'active' : ''}" data-filter="banned">Banned</button>
                        </div>
                        <div class="search-input">
                            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <circle cx="11" cy="11" r="8"/>
                                <path d="m21 21-4.35-4.35"/>
                            </svg>
                            <input type="search" id="user-search" placeholder="Search users..." value="${this.searchQuery}">
                        </div>
                    </div>
                </div>

                <div class="table-scroll">
                    <table>
                        <thead>
                            <tr>
                                <th>User</th>
                                <th>Games</th>
                                <th>Total Plays</th>
                                <th>Total Likes</th>
                                <th>Status</th>
                                <th>Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            ${paginatedUsers.length > 0 ? paginatedUsers.map(user => `
                                <tr>
                                    <td>
                                        <div class="user-row">
                                            <img class="avatar" src="${user.profilePicture || 'https://api.dicebear.com/7.x/avataaars/png?seed=' + user.id}" alt="">
                                            <div class="user-info">
                                                <span class="username">
                                                    ${this.escapeHtml(user.displayName || 'Unknown')}
                                                    ${user.isVerified ? '<svg class="verified-badge" viewBox="0 0 24 24" fill="currentColor"><path d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>' : ''}
                                                </span>
                                                <span class="email">@${user.username || 'unknown'}</span>
                                            </div>
                                        </div>
                                    </td>
                                    <td>${user.gamesCount}</td>
                                    <td>${ApiClient.formatNumber(user.totalPlays)}</td>
                                    <td>${ApiClient.formatNumber(user.totalLikes)}</td>
                                    <td>
                                        ${user.isBanned
                                            ? '<span class="badge badge-red">Banned</span>'
                                            : user.isVerified
                                                ? '<span class="badge badge-blue">Verified</span>'
                                                : '<span class="badge badge-gray">Active</span>'
                                        }
                                    </td>
                                    <td>
                                        <div class="flex gap-sm">
                                            <button class="btn btn-ghost btn-sm" onclick="UsersPage.viewUser('${user.id}')" title="View Details">
                                                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" width="16" height="16">
                                                    <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/>
                                                    <circle cx="12" cy="12" r="3"/>
                                                </svg>
                                            </button>
                                            <button class="btn btn-ghost btn-sm" onclick="UsersPage.toggleVerify('${user.id}', ${!user.isVerified})" title="${user.isVerified ? 'Remove Verification' : 'Verify User'}">
                                                <svg viewBox="0 0 24 24" fill="none" stroke="${user.isVerified ? '#5576F8' : 'currentColor'}" stroke-width="2" width="16" height="16">
                                                    <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/>
                                                    <polyline points="22 4 12 14.01 9 11.01"/>
                                                </svg>
                                            </button>
                                            ${user.isBanned
                                                ? `<button class="btn btn-success btn-sm" onclick="UsersPage.unbanUser('${user.id}')">Unban</button>`
                                                : `<button class="btn btn-danger btn-sm" onclick="UsersPage.banUser('${user.id}')">Ban</button>`
                                            }
                                        </div>
                                    </td>
                                </tr>
                            `).join('') : `
                                <tr>
                                    <td colspan="6" style="text-align: center; padding: 48px;">
                                        <div class="empty-state">
                                            <h3>No users found</h3>
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
                        <span>Showing ${(this.currentPage - 1) * this.pageSize + 1}-${Math.min(this.currentPage * this.pageSize, this.filteredUsers.length)} of ${this.filteredUsers.length}</span>
                        <div class="pagination">
                            <button ${this.currentPage === 1 ? 'disabled' : ''} onclick="UsersPage.goToPage(${this.currentPage - 1})">←</button>
                            ${this.getPaginationButtons(totalPages)}
                            <button ${this.currentPage === totalPages ? 'disabled' : ''} onclick="UsersPage.goToPage(${this.currentPage + 1})">→</button>
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
                buttons.push(`<button class="${i === current ? 'active' : ''}" onclick="UsersPage.goToPage(${i})">${i}</button>`);
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
        const searchInput = document.getElementById('user-search');
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
     * View user details
     */
    async viewUser(userId) {
        const user = this.users.find(u => u.id === userId);
        if (!user) return;

        const content = document.getElementById('user-modal-content');
        content.innerHTML = `
            <div style="text-align: center; margin-bottom: 24px;">
                <img class="avatar avatar-xl" src="${user.profilePicture || 'https://api.dicebear.com/7.x/avataaars/png?seed=' + user.id}" alt="">
                <h3 style="margin-top: 16px;">
                    ${this.escapeHtml(user.displayName || 'Unknown')}
                    ${user.isVerified ? '<svg class="verified-badge" viewBox="0 0 24 24" fill="currentColor" width="20" height="20"><path d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>' : ''}
                </h3>
                <p class="text-muted">@${user.username || 'unknown'}</p>
            </div>

            <div class="game-info">
                <div class="game-info-item">
                    <label>Games Created</label>
                    <span>${user.gamesCount}</span>
                </div>
                <div class="game-info-item">
                    <label>Total Plays</label>
                    <span>${ApiClient.formatNumber(user.totalPlays)}</span>
                </div>
                <div class="game-info-item">
                    <label>Total Likes</label>
                    <span>${ApiClient.formatNumber(user.totalLikes)}</span>
                </div>
                <div class="game-info-item">
                    <label>Status</label>
                    <span>${user.isBanned ? 'Banned' : user.isVerified ? 'Verified' : 'Active'}</span>
                </div>
            </div>

            ${user.bio ? `
                <div style="margin-top: 24px;">
                    <label>Bio</label>
                    <p style="margin-top: 8px;">${this.escapeHtml(user.bio)}</p>
                </div>
            ` : ''}
        `;

        const footer = document.getElementById('user-modal-footer');
        footer.innerHTML = `
            <button class="btn btn-secondary" data-modal="user-modal">Close</button>
            <button class="btn ${user.isVerified ? 'btn-secondary' : 'btn-primary'}" onclick="UsersPage.toggleVerify('${userId}', ${!user.isVerified}); Modal.hide('user-modal');">
                ${user.isVerified ? 'Remove Verification' : 'Verify User'}
            </button>
            ${user.isBanned
                ? `<button class="btn btn-success" onclick="UsersPage.unbanUser('${userId}'); Modal.hide('user-modal');">Unban User</button>`
                : `<button class="btn btn-danger" onclick="UsersPage.banUser('${userId}'); Modal.hide('user-modal');">Ban User</button>`
            }
        `;

        Modal.show('user-modal');
    },

    /**
     * Toggle user verification
     */
    async toggleVerify(userId, isVerified) {
        try {
            await api.toggleVerify(userId, isVerified);
            Toast.show(isVerified ? 'User verified successfully' : 'Verification removed', 'success');

            // Update local data
            const user = this.users.find(u => u.id === userId);
            if (user) user.isVerified = isVerified;
            this.refresh();
        } catch (error) {
            Toast.show('Failed to update verification: ' + error.message, 'error');
        }
    },

    /**
     * Ban user
     */
    async banUser(userId) {
        const confirmed = await Modal.confirm(
            'Ban User',
            'Are you sure you want to ban this user? They will not be able to access the app.',
            'Ban User',
            true
        );

        if (!confirmed) return;

        try {
            await api.banUser(userId);
            Toast.show('User banned successfully', 'success');

            // Update local data
            const user = this.users.find(u => u.id === userId);
            if (user) user.isBanned = true;
            this.refresh();
        } catch (error) {
            Toast.show('Failed to ban user: ' + error.message, 'error');
        }
    },

    /**
     * Unban user
     */
    async unbanUser(userId) {
        try {
            await api.unbanUser(userId);
            Toast.show('User unbanned successfully', 'success');

            // Update local data
            const user = this.users.find(u => u.id === userId);
            if (user) user.isBanned = false;
            this.refresh();
        } catch (error) {
            Toast.show('Failed to unban user: ' + error.message, 'error');
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

window.UsersPage = UsersPage;
