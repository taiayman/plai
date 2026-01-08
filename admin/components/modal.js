/**
 * Modal Component - Reusable modal utilities
 */

class Modal {
    /**
     * Show a modal by ID
     */
    static show(modalId) {
        const modal = document.getElementById(modalId);
        if (modal) {
            modal.classList.remove('hidden');
            document.body.style.overflow = 'hidden';
        }
    }

    /**
     * Hide a modal by ID
     */
    static hide(modalId) {
        const modal = document.getElementById(modalId);
        if (modal) {
            modal.classList.add('hidden');
            document.body.style.overflow = '';
        }
    }

    /**
     * Toggle modal visibility
     */
    static toggle(modalId) {
        const modal = document.getElementById(modalId);
        if (modal) {
            if (modal.classList.contains('hidden')) {
                Modal.show(modalId);
            } else {
                Modal.hide(modalId);
            }
        }
    }

    /**
     * Show confirm dialog
     */
    static async confirm(title, message, actionLabel = 'Confirm', isDanger = true) {
        return new Promise((resolve) => {
            const modal = document.getElementById('confirm-modal');
            const titleEl = document.getElementById('confirm-title');
            const messageEl = document.getElementById('confirm-message');
            const actionBtn = document.getElementById('confirm-action');
            const cancelBtn = document.getElementById('confirm-cancel');

            titleEl.textContent = title;
            messageEl.textContent = message;
            actionBtn.textContent = actionLabel;
            actionBtn.className = `btn ${isDanger ? 'btn-danger' : 'btn-primary'}`;

            const cleanup = () => {
                Modal.hide('confirm-modal');
                actionBtn.removeEventListener('click', handleAction);
                cancelBtn.removeEventListener('click', handleCancel);
            };

            const handleAction = () => {
                cleanup();
                resolve(true);
            };

            const handleCancel = () => {
                cleanup();
                resolve(false);
            };

            actionBtn.addEventListener('click', handleAction);
            cancelBtn.addEventListener('click', handleCancel);

            Modal.show('confirm-modal');
        });
    }

    /**
     * Initialize modal close handlers
     */
    static init() {
        // Close modal when clicking overlay
        document.querySelectorAll('.modal-overlay').forEach(overlay => {
            overlay.addEventListener('click', (e) => {
                if (e.target === overlay) {
                    overlay.classList.add('hidden');
                    document.body.style.overflow = '';
                }
            });
        });

        // Close modal when clicking close button
        document.querySelectorAll('.modal-close, [data-modal]').forEach(btn => {
            btn.addEventListener('click', () => {
                const modalId = btn.dataset.modal;
                if (modalId) {
                    Modal.hide(modalId);
                }
            });
        });

        // Close modal on Escape key
        document.addEventListener('keydown', (e) => {
            if (e.key === 'Escape') {
                document.querySelectorAll('.modal-overlay:not(.hidden)').forEach(modal => {
                    modal.classList.add('hidden');
                });
                document.body.style.overflow = '';
            }
        });
    }
}

window.Modal = Modal;
