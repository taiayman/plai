/**
 * Plai Admin Dashboard - Main Application
 */

class AdminApp {
    constructor() {
        this.currentPage = null;
        this.pages = {
            overview: OverviewPage,
            users: UsersPage,
            games: GamesPage,
            analytics: AnalyticsPage,
            moderation: ModerationPage,
        };
        this.init();
    }

    /**
     * Initialize the application
     */
    init() {
        // Check authentication
        if (!this.checkAuth()) {
            this.showLogin();
            this.initLoginForm();
            return;
        }

        // Show main app
        this.showApp();

        // Initialize components
        Modal.init();
        this.initRouter();
        this.initEventListeners();

        // Navigate to initial page
        const hash = window.location.hash.slice(1) || 'overview';
        this.navigate(hash);

        // Update moderation badge
        this.updateModerationBadge();
    }

    /**
     * Check if admin is authenticated
     */
    checkAuth() {
        return api.isAuthenticated();
    }

    /**
     * Show login modal
     */
    showLogin() {
        document.getElementById('login-modal').classList.remove('hidden');
        document.getElementById('app').classList.add('hidden');
    }

    /**
     * Show main app
     */
    showApp() {
        document.getElementById('login-modal').classList.add('hidden');
        document.getElementById('app').classList.remove('hidden');
    }

    /**
     * Initialize login form
     */
    initLoginForm() {
        const form = document.getElementById('login-form');
        const errorEl = document.getElementById('login-error');

        form.addEventListener('submit', async (e) => {
            e.preventDefault();

            const password = document.getElementById('admin-password').value;
            errorEl.classList.add('hidden');

            try {
                const valid = await api.validateAdmin(password);

                if (valid) {
                    this.showApp();
                    Modal.init();
                    this.initRouter();
                    this.initEventListeners();
                    this.navigate('overview');
                    this.updateModerationBadge();
                } else {
                    errorEl.textContent = 'Invalid admin password';
                    errorEl.classList.remove('hidden');
                }
            } catch (error) {
                errorEl.textContent = 'Authentication failed: ' + error.message;
                errorEl.classList.remove('hidden');
            }
        });
    }

    /**
     * Initialize router
     */
    initRouter() {
        window.addEventListener('hashchange', () => {
            const page = window.location.hash.slice(1) || 'overview';
            this.navigate(page);
        });
    }

    /**
     * Initialize event listeners
     */
    initEventListeners() {
        // Mobile menu toggle
        const mobileMenuBtn = document.getElementById('mobile-menu-btn');
        const sidebar = document.getElementById('sidebar');
        const backdrop = document.getElementById('sidebar-backdrop');

        const closeSidebar = () => {
            sidebar.classList.remove('open');
            backdrop.classList.remove('active');
            document.body.style.overflow = '';
        };

        const openSidebar = () => {
            sidebar.classList.add('open');
            backdrop.classList.add('active');
            document.body.style.overflow = 'hidden';
        };

        if (mobileMenuBtn) {
            mobileMenuBtn.addEventListener('click', () => {
                if (sidebar.classList.contains('open')) {
                    closeSidebar();
                } else {
                    openSidebar();
                }
            });
        }

        // Close sidebar when clicking backdrop
        if (backdrop) {
            backdrop.addEventListener('click', closeSidebar);
        }

        // Close sidebar when clicking outside on mobile
        document.addEventListener('click', (e) => {
            if (window.innerWidth <= 768) {
                if (!sidebar.contains(e.target) && !mobileMenuBtn.contains(e.target)) {
                    closeSidebar();
                }
            }
        });

        // Handle window resize - close mobile menu if window grows
        window.addEventListener('resize', () => {
            if (window.innerWidth > 768) {
                closeSidebar();
            }
        });

        // Refresh button
        const refreshBtn = document.getElementById('refresh-btn');
        if (refreshBtn) {
            refreshBtn.addEventListener('click', () => {
                this.navigate(this.currentPage);
                Toast.show('Data refreshed', 'success');
            });
        }

        // Logout button
        const logoutBtn = document.getElementById('logout-btn');
        if (logoutBtn) {
            logoutBtn.addEventListener('click', () => {
                this.logout();
            });
        }

        // Nav items - close mobile sidebar on navigation
        document.querySelectorAll('.nav-item').forEach(item => {
            item.addEventListener('click', () => {
                if (window.innerWidth <= 768) {
                    closeSidebar();
                }
            });
        });
    }

    /**
     * Navigate to a page
     */
    async navigate(pageName) {
        const page = this.pages[pageName];

        if (!page) {
            console.error('Page not found:', pageName);
            return;
        }

        // Cleanup previous page
        if (this.currentPage && this.pages[this.currentPage]?.destroy) {
            this.pages[this.currentPage].destroy();
        }

        this.currentPage = pageName;

        // Update URL
        if (window.location.hash.slice(1) !== pageName) {
            window.location.hash = pageName;
        }

        // Update nav active state
        document.querySelectorAll('.nav-item').forEach(item => {
            item.classList.toggle('active', item.dataset.page === pageName);
        });

        // Update page title
        const titles = {
            overview: 'Overview',
            users: 'Users',
            games: 'Games',
            analytics: 'Analytics',
            moderation: 'Moderation',
        };
        document.getElementById('page-title').textContent = titles[pageName] || 'Dashboard';

        // Render page
        const container = document.getElementById('content-area');
        await page.render(container);
    }

    /**
     * View a game (helper method for other pages)
     */
    viewGame(gameId) {
        GamesPage.viewGame(gameId);
    }

    /**
     * Update moderation badge
     */
    async updateModerationBadge() {
        try {
            const gamesData = await api.getGames();
            const games = gamesData.games || [];
            const flaggedCount = games.filter(g => g.isFlagged).length;

            const badge = document.getElementById('moderation-badge');
            if (badge) {
                badge.textContent = flaggedCount;
                badge.style.display = flaggedCount > 0 ? 'inline-block' : 'none';
            }
        } catch (error) {
            console.error('Failed to update moderation badge:', error);
        }
    }

    /**
     * Logout
     */
    logout() {
        api.clearAuth();
        this.showLogin();
        document.getElementById('admin-password').value = '';
    }
}

/**
 * Toast Notification System
 */
class Toast {
    static show(message, type = 'success', duration = 3000) {
        const container = document.getElementById('toast-container');

        const toast = document.createElement('div');
        toast.className = `toast ${type}`;
        toast.innerHTML = `
            <svg class="toast-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                ${type === 'success'
                    ? '<path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/>'
                    : '<circle cx="12" cy="12" r="10"/><line x1="15" y1="9" x2="9" y2="15"/><line x1="9" y1="9" x2="15" y2="15"/>'
                }
            </svg>
            <span class="toast-message">${message}</span>
            <button class="toast-close" onclick="this.parentElement.remove()">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" width="16" height="16">
                    <line x1="18" y1="6" x2="6" y2="18"/>
                    <line x1="6" y1="6" x2="18" y2="18"/>
                </svg>
            </button>
        `;

        container.appendChild(toast);

        // Auto remove after duration
        setTimeout(() => {
            if (toast.parentElement) {
                toast.style.animation = 'slideIn 0.3s ease reverse';
                setTimeout(() => toast.remove(), 300);
            }
        }, duration);
    }
}

window.Toast = Toast;

// Initialize app when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
    window.app = new AdminApp();
});
