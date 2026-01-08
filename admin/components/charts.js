/**
 * Charts Component - Chart.js Wrapper
 */

class Charts {
    static defaultOptions = {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
            legend: {
                display: false,
            },
            tooltip: {
                backgroundColor: '#1E1E1E',
                titleColor: '#FFFFFF',
                bodyColor: '#B3B3B3',
                borderColor: '#2A2A2A',
                borderWidth: 1,
                padding: 12,
                cornerRadius: 8,
                displayColors: false,
            },
        },
        scales: {
            x: {
                grid: {
                    color: 'rgba(255, 255, 255, 0.05)',
                    drawBorder: false,
                },
                ticks: {
                    color: '#666666',
                    font: {
                        size: 11,
                    },
                },
            },
            y: {
                grid: {
                    color: 'rgba(255, 255, 255, 0.05)',
                    drawBorder: false,
                },
                ticks: {
                    color: '#666666',
                    font: {
                        size: 11,
                    },
                },
                beginAtZero: true,
            },
        },
    };

    /**
     * Create a line chart
     */
    static createLineChart(canvasId, data, options = {}) {
        const ctx = document.getElementById(canvasId);
        if (!ctx) return null;

        return new Chart(ctx, {
            type: 'line',
            data: {
                labels: data.labels,
                datasets: [{
                    data: data.values,
                    borderColor: '#5576F8',
                    backgroundColor: 'rgba(85, 118, 248, 0.1)',
                    borderWidth: 2,
                    fill: true,
                    tension: 0.4,
                    pointRadius: 0,
                    pointHoverRadius: 6,
                    pointHoverBackgroundColor: '#5576F8',
                    pointHoverBorderColor: '#FFFFFF',
                    pointHoverBorderWidth: 2,
                }],
            },
            options: {
                ...Charts.defaultOptions,
                ...options,
            },
        });
    }

    /**
     * Create a bar chart
     */
    static createBarChart(canvasId, data, options = {}) {
        const ctx = document.getElementById(canvasId);
        if (!ctx) return null;

        return new Chart(ctx, {
            type: 'bar',
            data: {
                labels: data.labels,
                datasets: [{
                    data: data.values,
                    backgroundColor: data.colors || 'rgba(85, 118, 248, 0.8)',
                    borderRadius: 6,
                    borderSkipped: false,
                }],
            },
            options: {
                ...Charts.defaultOptions,
                ...options,
            },
        });
    }

    /**
     * Create a doughnut chart
     */
    static createDoughnutChart(canvasId, data, options = {}) {
        const ctx = document.getElementById(canvasId);
        if (!ctx) return null;

        return new Chart(ctx, {
            type: 'doughnut',
            data: {
                labels: data.labels,
                datasets: [{
                    data: data.values,
                    backgroundColor: data.colors || [
                        '#5576F8',
                        '#5DAE64',
                        '#E94F37',
                        '#FFC107',
                        '#9B59B6',
                    ],
                    borderWidth: 0,
                }],
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                cutout: '70%',
                plugins: {
                    legend: {
                        position: 'right',
                        labels: {
                            color: '#B3B3B3',
                            padding: 16,
                            font: {
                                size: 12,
                            },
                        },
                    },
                },
                ...options,
            },
        });
    }

    /**
     * Create an area chart
     */
    static createAreaChart(canvasId, data, options = {}) {
        const ctx = document.getElementById(canvasId);
        if (!ctx) return null;

        const gradient = ctx.getContext('2d').createLinearGradient(0, 0, 0, 300);
        gradient.addColorStop(0, 'rgba(85, 118, 248, 0.3)');
        gradient.addColorStop(1, 'rgba(85, 118, 248, 0)');

        return new Chart(ctx, {
            type: 'line',
            data: {
                labels: data.labels,
                datasets: [{
                    data: data.values,
                    borderColor: '#5576F8',
                    backgroundColor: gradient,
                    borderWidth: 2,
                    fill: true,
                    tension: 0.4,
                    pointRadius: 0,
                    pointHoverRadius: 6,
                    pointHoverBackgroundColor: '#5576F8',
                    pointHoverBorderColor: '#FFFFFF',
                    pointHoverBorderWidth: 2,
                }],
            },
            options: {
                ...Charts.defaultOptions,
                ...options,
            },
        });
    }

    /**
     * Format labels for time series
     */
    static formatDateLabels(dates) {
        return dates.map(d => {
            const date = new Date(d);
            return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
        });
    }

    /**
     * Destroy chart instance
     */
    static destroy(chart) {
        if (chart) {
            chart.destroy();
        }
    }
}

window.Charts = Charts;
