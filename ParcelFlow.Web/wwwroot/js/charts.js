// Thin JS-interop layer so Blazor components can render Chart.js charts
// without pulling in a separate npm/webpack build step.

window.parcelFlowCharts = {
    _instances: {},

    renderBar: function (canvasId, labels, values, label) {
        this._destroy(canvasId);
        const ctx = document.getElementById(canvasId).getContext('2d');
        this._instances[canvasId] = new Chart(ctx, {
            type: 'bar',
            data: {
                labels: labels,
                datasets: [{ label: label, data: values, backgroundColor: '#1e3a5f' }]
            },
            options: { responsive: true, plugins: { legend: { display: false } } }
        });
    },

    renderPie: function (canvasId, labels, values) {
        this._destroy(canvasId);
        const ctx = document.getElementById(canvasId).getContext('2d');
        this._instances[canvasId] = new Chart(ctx, {
            type: 'pie',
            data: {
                labels: labels,
                datasets: [{ data: values, backgroundColor: ['#1a7f37', '#b25e00', '#b42318'] }]
            },
            options: { responsive: true }
        });
    },

    _destroy: function (canvasId) {
        if (this._instances[canvasId]) {
            this._instances[canvasId].destroy();
        }
    }
};
