/**
 * Plai Admin Dashboard - API Client
 * Handles all backend communication
 */

class ApiClient {
    constructor() {
        this.baseUrl = 'https://my-chat-helper.taiayman13-ed6.workers.dev';
        this.appSecret = 'MySecretPassword123';
        this.adminAuth = localStorage.getItem('adminAuth') || '';
    }

    /**
     * Set admin authentication
     */
    setAdminAuth(password) {
        this.adminAuth = password;
        localStorage.setItem('adminAuth', password);
    }

    /**
     * Clear admin authentication
     */
    clearAuth() {
        this.adminAuth = '';
        localStorage.removeItem('adminAuth');
    }

    /**
     * Check if admin is authenticated
     */
    isAuthenticated() {
        return !!this.adminAuth;
    }

    /**
     * Make an API request
     */
    async request(endpoint, options = {}) {
        const url = `${this.baseUrl}${endpoint}`;

        const headers = {
            'Content-Type': 'application/json',
            'App-Secret': this.appSecret,
            ...options.headers,
        };

        // Add admin auth header for admin endpoints
        if (endpoint.startsWith('/admin') || this.adminAuth) {
            headers['Admin-Auth'] = this.adminAuth;
        }

        try {
            const response = await fetch(url, {
                ...options,
                headers,
            });

            // Handle non-JSON responses
            const contentType = response.headers.get('content-type');
            let data;

            if (contentType && contentType.includes('application/json')) {
                data = await response.json();
            } else {
                data = await response.text();
            }

            if (!response.ok) {
                throw new Error(data.message || data.error || `API Error: ${response.status}`);
            }

            return data;
        } catch (error) {
            console.error('API Request failed:', error);
            throw error;
        }
    }

    // ==========================================
    // Authentication
    // ==========================================

    /**
     * Validate admin credentials
     */
    async validateAdmin(password) {
        // For now, we just check against a known password
        // In production, this should validate against the backend
        const validPassword = 'PlaiAdmin2024!';

        if (password === validPassword) {
            this.setAdminAuth(password);
            return true;
        }
        return false;
    }

    // ==========================================
    // Analytics
    // ==========================================

    /**
     * Get dashboard analytics
     */
    async getAnalytics(range = '30d') {
        // For now, we aggregate from existing endpoints
        const [usersData, gamesData] = await Promise.all([
            this.getUsers(),
            this.getGames(),
        ]);

        const users = usersData.users || [];
        const games = gamesData.games || [];

        // Calculate totals
        const totalUsers = users.length;
        const totalGames = games.length;
        const totalPlays = games.reduce((sum, g) => sum + (g.playCount || 0), 0);
        const totalLikes = games.reduce((sum, g) => sum + (g.likeCount || 0), 0);

        // Calculate time series (last 30 days)
        const now = new Date();
        const thirtyDaysAgo = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);

        const usersByDay = this.groupByDay(users, 'createdAt', thirtyDaysAgo);
        const gamesByDay = this.groupByDay(games, 'createdAt', thirtyDaysAgo);

        // Top games by plays
        const topGamesByPlays = [...games]
            .sort((a, b) => (b.playCount || 0) - (a.playCount || 0))
            .slice(0, 10);

        // Top games by likes
        const topGamesByLikes = [...games]
            .sort((a, b) => (b.likeCount || 0) - (a.likeCount || 0))
            .slice(0, 10);

        // Hashtag analytics
        const hashtagCounts = {};
        games.forEach(game => {
            (game.hashtags || []).forEach(tag => {
                hashtagCounts[tag] = (hashtagCounts[tag] || 0) + 1;
            });
        });
        const topHashtags = Object.entries(hashtagCounts)
            .sort((a, b) => b[1] - a[1])
            .slice(0, 10)
            .map(([tag, count]) => ({ tag, count }));

        return {
            totals: {
                users: totalUsers,
                games: totalGames,
                plays: totalPlays,
                likes: totalLikes,
            },
            growth: {
                users: this.calculateGrowth(users, 'createdAt'),
                games: this.calculateGrowth(games, 'createdAt'),
            },
            timeSeries: {
                users: usersByDay,
                games: gamesByDay,
            },
            topGamesByPlays,
            topGamesByLikes,
            topHashtags,
            recentGames: games.slice(0, 10),
            recentUsers: users.slice(0, 10),
        };
    }

    /**
     * Group items by day
     */
    groupByDay(items, dateField, startDate) {
        const groups = {};
        const now = new Date();

        // Initialize all days
        for (let d = new Date(startDate); d <= now; d.setDate(d.getDate() + 1)) {
            const key = d.toISOString().split('T')[0];
            groups[key] = 0;
        }

        // Count items per day
        items.forEach(item => {
            if (item[dateField]) {
                const date = new Date(item[dateField]);
                if (date >= startDate) {
                    const key = date.toISOString().split('T')[0];
                    if (groups[key] !== undefined) {
                        groups[key]++;
                    }
                }
            }
        });

        // Convert to array
        return Object.entries(groups).map(([date, count]) => ({ date, count }));
    }

    /**
     * Calculate growth percentage
     */
    calculateGrowth(items, dateField) {
        const now = new Date();
        const sevenDaysAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
        const fourteenDaysAgo = new Date(now.getTime() - 14 * 24 * 60 * 60 * 1000);

        const thisWeek = items.filter(item => {
            const date = new Date(item[dateField]);
            return date >= sevenDaysAgo;
        }).length;

        const lastWeek = items.filter(item => {
            const date = new Date(item[dateField]);
            return date >= fourteenDaysAgo && date < sevenDaysAgo;
        }).length;

        if (lastWeek === 0) return thisWeek > 0 ? 100 : 0;
        return Math.round(((thisWeek - lastWeek) / lastWeek) * 100);
    }

    // ==========================================
    // Users
    // ==========================================

    /**
     * Get all users
     */
    async getUsers(options = {}) {
        // Use the existing users endpoint pattern
        // We need to fetch from Firestore directly since there's no /users list endpoint
        const response = await this.request('/admin/users');
        return response;
    }

    /**
     * Get user by ID
     */
    async getUser(userId) {
        return this.request(`/users/${userId}`);
    }

    /**
     * Update user
     */
    async updateUser(userId, data) {
        return this.request(`/users/${userId}`, {
            method: 'PATCH',
            body: JSON.stringify(data),
        });
    }

    /**
     * Ban user
     */
    async banUser(userId) {
        return this.request(`/admin/users/${userId}/ban`, {
            method: 'POST',
        });
    }

    /**
     * Unban user
     */
    async unbanUser(userId) {
        return this.request(`/admin/users/${userId}/unban`, {
            method: 'POST',
        });
    }

    /**
     * Toggle user verification
     */
    async toggleVerify(userId, isVerified) {
        return this.request(`/users/${userId}`, {
            method: 'PATCH',
            body: JSON.stringify({ isVerified }),
        });
    }

    // ==========================================
    // Games
    // ==========================================

    /**
     * Get all games
     */
    async getGames(options = {}) {
        return this.request('/games');
    }

    /**
     * Get game by ID
     */
    async getGame(gameId) {
        const { games } = await this.getGames();
        return games.find(g => g.id === gameId);
    }

    /**
     * Update game
     */
    async updateGame(gameId, data) {
        return this.request(`/admin/games/${gameId}`, {
            method: 'PATCH',
            body: JSON.stringify(data),
        });
    }

    /**
     * Delete game
     */
    async deleteGame(gameId) {
        return this.request(`/admin/games/${gameId}`, {
            method: 'DELETE',
        });
    }

    /**
     * Toggle game featured status
     */
    async toggleFeatured(gameId, isFeatured) {
        return this.request(`/admin/games/${gameId}/feature`, {
            method: 'PATCH',
            body: JSON.stringify({ isFeatured }),
        });
    }

    /**
     * Flag game for review
     */
    async flagGame(gameId, isFlagged) {
        return this.request(`/admin/games/${gameId}/flag`, {
            method: 'PATCH',
            body: JSON.stringify({ isFlagged }),
        });
    }

    // ==========================================
    // Moderation
    // ==========================================

    /**
     * Get moderation queue
     */
    async getModerationQueue() {
        return this.request('/admin/moderation/queue');
    }

    /**
     * Take moderation action
     */
    async moderateContent(gameId, action, reason = '') {
        return this.request('/admin/moderation/action', {
            method: 'POST',
            body: JSON.stringify({ gameId, action, reason }),
        });
    }

    /**
     * Get moderation log
     */
    async getModerationLog() {
        return this.request('/admin/moderation/log');
    }

    // ==========================================
    // Utilities
    // ==========================================

    /**
     * Format number with K/M suffix
     */
    static formatNumber(num) {
        if (num >= 1000000) {
            return (num / 1000000).toFixed(1) + 'M';
        }
        if (num >= 1000) {
            return (num / 1000).toFixed(1) + 'K';
        }
        return num.toString();
    }

    /**
     * Format date relative
     */
    static formatTimeAgo(dateString) {
        const date = new Date(dateString);
        const now = new Date();
        const seconds = Math.floor((now - date) / 1000);

        if (seconds < 60) return 'just now';
        if (seconds < 3600) return Math.floor(seconds / 60) + 'm ago';
        if (seconds < 86400) return Math.floor(seconds / 3600) + 'h ago';
        if (seconds < 604800) return Math.floor(seconds / 86400) + 'd ago';

        return date.toLocaleDateString();
    }

    /**
     * Format date
     */
    static formatDate(dateString) {
        const date = new Date(dateString);
        return date.toLocaleDateString('en-US', {
            year: 'numeric',
            month: 'short',
            day: 'numeric',
        });
    }
}

// Export for use in other modules
window.ApiClient = ApiClient;
window.api = new ApiClient();
