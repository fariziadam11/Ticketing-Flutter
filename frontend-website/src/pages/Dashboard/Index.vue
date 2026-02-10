<script setup lang="ts">
import { computed } from 'vue'
import { useRouter } from 'vue-router'
import { useDashboard } from '@/composables/useDashboard'
import { useAuthStore } from '@/stores/auth'
import VueApexCharts from 'vue3-apexcharts'
import type { ApexOptions } from 'apexcharts'

const router = useRouter()
const authStore = useAuthStore()
const { stats, statusChartData, timeSeriesData, isLoading } = useDashboard()

const formatDate = (timestamp: number): string => {
  const date = new Date(timestamp * 1000)
  return date.toLocaleDateString('id-ID', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  })
}

const getStatusColor = (status: string): string => {
  const statusColors: Record<string, string> = {
    New: '#0f62fe',
    Open: '#0f62fe',
    Pending: '#f1c21b',
    Waiting: '#f1c21b',
    Resolved: '#24a148',
    Closed: '#24a148',
    Rejected: '#da1e28',
    Canceled: '#6f6f6f',
  }
  return statusColors[status] || '#6f6f6f'
}

const statusChartSeries = computed(() => statusChartData.value.series)
const timeSeriesChartSeries = computed(() => [
  {
    name: 'Tickets Created',
    data: timeSeriesData.value.series,
  },
])

// Chart options for status distribution (Donut chart) - reactive
const statusChartOptionsComputed = computed<ApexOptions>(() => ({
  chart: {
    type: 'donut',
    toolbar: {
      show: false,
    },
  },
  labels: statusChartData.value.labels,
  colors: statusChartData.value.labels.map((label) => getStatusColor(label)),
  legend: {
    position: 'bottom',
  },
  dataLabels: {
    enabled: true,
    formatter: (val: number) => `${val.toFixed(1)}%`,
  },
  plotOptions: {
    pie: {
      donut: {
        size: '70%',
      },
    },
  },
}))

// Chart options for time series (Line chart) - reactive
const timeSeriesChartOptionsComputed = computed<ApexOptions>(() => ({
  chart: {
    type: 'line',
    toolbar: {
      show: false,
    },
    zoom: {
      enabled: false,
    },
  },
  stroke: {
    curve: 'smooth',
    width: 3,
  },
  colors: ['#0f62fe'],
  xaxis: {
    categories: timeSeriesData.value.labels,
  },
  yaxis: {
    title: {
      text: 'Number of Tickets',
    },
  },
  grid: {
    borderColor: '#e0e0e0',
  },
}))
</script>

<template>
  <div class="dashboard-page">
    <div class="page-header">
      <div>
        <h1>Dashboard</h1>
        <p class="welcome-text">Welcome back, {{ authStore.fullName }}!</p>
      </div>
    </div>

    <div v-if="isLoading" class="loading-container">
      <bx-loading :active="isLoading" />
    </div>

    <div v-else class="dashboard-content">
      <!-- Statistics Cards -->
      <div class="stats-grid">
        <div class="stat-card">
          <div class="stat-icon total">
            <i class="pi pi-ticket"></i>
          </div>
          <div class="stat-content">
            <h3 class="stat-value">{{ stats.totalTickets }}</h3>
            <p class="stat-label">Total Tickets</p>
          </div>
        </div>

        <div class="stat-card">
          <div class="stat-icon open">
            <i class="pi pi-clock"></i>
          </div>
          <div class="stat-content">
            <h3 class="stat-value">{{ stats.openTickets }}</h3>
            <p class="stat-label">Open Tickets</p>
          </div>
        </div>

        <div class="stat-card">
          <div class="stat-icon resolved">
            <i class="pi pi-check-circle"></i>
          </div>
          <div class="stat-content">
            <h3 class="stat-value">{{ stats.resolvedTickets }}</h3>
            <p class="stat-label">Resolved Tickets</p>
          </div>
        </div>

        <div class="stat-card">
          <div class="stat-icon pending">
            <i class="pi pi-hourglass"></i>
          </div>
          <div class="stat-content">
            <h3 class="stat-value">{{ stats.pendingTickets }}</h3>
            <p class="stat-label">Pending Tickets</p>
          </div>
        </div>
      </div>

      <!-- Charts Section -->
      <div class="charts-grid">
        <div class="chart-card">
          <h2 class="chart-title">Tickets by Status</h2>
          <VueApexCharts
            type="donut"
            height="350"
            :options="statusChartOptionsComputed"
            :series="statusChartSeries"
          />
        </div>

        <div class="chart-card">
          <h2 class="chart-title">Tickets Created (Last 7 Days)</h2>
          <VueApexCharts
            type="line"
            height="350"
            :options="timeSeriesChartOptionsComputed"
            :series="timeSeriesChartSeries"
          />
        </div>
      </div>

      <!-- Recent Tickets & Quick Actions -->
      <div class="bottom-grid">
        <div class="recent-tickets-card">
          <div class="card-header">
            <h2 class="card-title">Recent Tickets</h2>
            <bx-btn size="sm" @click="router.push('/tickets')">View All</bx-btn>
          </div>
          <div v-if="stats.recentTickets.length === 0" class="empty-state">
            <p>No tickets yet</p>
          </div>
          <div v-else class="tickets-list">
            <div
              v-for="ticket in stats.recentTickets"
              :key="ticket.id"
              class="ticket-item"
              @click="router.push(`/tickets/${ticket.id}`)"
            >
              <div class="ticket-info">
                <h4 class="ticket-title">{{ ticket.title }}</h4>
                <p class="ticket-meta">
                  <span class="ticket-id">{{ ticket.wrk_ticket_id || `#${ticket.id}` }}</span>
                  <span class="ticket-date">{{ formatDate(ticket.created_at) }}</span>
                </p>
              </div>
              <div class="ticket-status">
                <span
                  class="status-badge"
                  :style="{ backgroundColor: getStatusColor(ticket.status) + '20', color: getStatusColor(ticket.status) }"
                >
                  {{ ticket.status }}
                </span>
              </div>
            </div>
          </div>
        </div>

        <div class="quick-actions-card">
          <h2 class="card-title">Quick Actions</h2>
          <div class="actions-list">
            <button class="action-button" @click="router.push('/tickets/create')">
              <i class="pi pi-plus-circle"></i>
              <span>Create New Ticket</span>
            </button>
            <button class="action-button" @click="router.push('/tickets')">
              <i class="pi pi-list"></i>
              <span>View All Tickets</span>
            </button>
            <button class="action-button" @click="router.push('/articles')">
              <i class="pi pi-book"></i>
              <span>Browse Articles</span>
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.dashboard-page {
  padding: 2rem;
  max-width: 1600px;
  margin: 0 auto;
}

.page-header {
  margin-bottom: 2rem;
}

.page-header h1 {
  font-size: 2rem;
  font-weight: 600;
  color: var(--cds-text-primary);
  margin: 0 0 0.5rem 0;
}

.welcome-text {
  color: var(--cds-text-secondary);
  font-size: 1rem;
  margin: 0;
}

.loading-container {
  display: flex;
  justify-content: center;
  align-items: center;
  padding: 4rem;
}

.dashboard-content {
  display: flex;
  flex-direction: column;
  gap: 2rem;
}

/* Statistics Cards */
.stats-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 1.5rem;
}

.stat-card {
  background-color: var(--cds-layer-01);
  border: 1px solid var(--cds-border-subtle);
  border-radius: 8px;
  padding: 1.5rem;
  display: flex;
  align-items: center;
  gap: 1.5rem;
  transition: box-shadow 0.2s ease;
}

.stat-card:hover {
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
}

.stat-icon {
  width: 60px;
  height: 60px;
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 1.5rem;
  flex-shrink: 0;
}

.stat-icon.total {
  background-color: #0f62fe20;
  color: #0f62fe;
}

.stat-icon.open {
  background-color: #0f62fe20;
  color: #0f62fe;
}

.stat-icon.resolved {
  background-color: #24a14820;
  color: #24a148;
}

.stat-icon.pending {
  background-color: #f1c21b20;
  color: #f1c21b;
}

.stat-content {
  flex: 1;
}

.stat-value {
  font-size: 2rem;
  font-weight: 600;
  color: var(--cds-text-primary);
  margin: 0 0 0.25rem 0;
}

.stat-label {
  font-size: 0.875rem;
  color: var(--cds-text-secondary);
  margin: 0;
}

/* Charts Section */
.charts-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(400px, 1fr));
  gap: 1.5rem;
}

.chart-card {
  background-color: var(--cds-layer-01);
  border: 1px solid var(--cds-border-subtle);
  border-radius: 8px;
  padding: 1.5rem;
}

.chart-title {
  font-size: 1.25rem;
  font-weight: 600;
  color: var(--cds-text-primary);
  margin: 0 0 1.5rem 0;
}

/* Bottom Grid */
.bottom-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(400px, 1fr));
  gap: 1.5rem;
}

@media (max-width: 900px) {
  .bottom-grid {
    grid-template-columns: 1fr;
  }
}

.recent-tickets-card,
.quick-actions-card {
  background-color: var(--cds-layer-01);
  border: 1px solid var(--cds-border-subtle);
  border-radius: 8px;
  padding: 1.5rem;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1.5rem;
}

.card-title {
  font-size: 1.25rem;
  font-weight: 600;
  color: var(--cds-text-primary);
  margin: 0 0 1.5rem 0;
}

/* Recent Tickets */
.tickets-list {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.ticket-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1rem;
  background-color: var(--cds-layer-02);
  border: 1px solid var(--cds-border-subtle);
  border-radius: 8px;
  cursor: pointer;
  transition: all 0.2s ease;
}

.ticket-item:hover {
  border-color: var(--cds-link-primary);
  background-color: var(--cds-layer-hover-01);
  transform: translateX(4px);
}

.ticket-info {
  flex: 1;
}

.ticket-title {
  font-size: 1rem;
  font-weight: 500;
  color: var(--cds-text-primary);
  margin: 0 0 0.5rem 0;
}

.ticket-meta {
  display: flex;
  gap: 1rem;
  font-size: 0.875rem;
  color: var(--cds-text-secondary);
  margin: 0;
}

.ticket-id {
  font-weight: 500;
}

.status-badge {
  padding: 0.25rem 0.75rem;
  border-radius: 12px;
  font-size: 0.75rem;
  font-weight: 500;
}

.empty-state {
  text-align: center;
  padding: 2rem;
  color: var(--cds-text-secondary);
}

/* Quick Actions */
.quick-actions-card .card-title {
  margin-bottom: 1.5rem;
}

.actions-list {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}

.action-button {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 1rem;
  background-color: var(--cds-layer-02);
  border: 1px solid var(--cds-border-subtle);
  border-radius: 8px;
  color: var(--cds-text-primary);
  font-size: 0.875rem;
  cursor: pointer;
  transition: all 0.2s ease;
  text-align: left;
}

.action-button:hover {
  background-color: var(--cds-layer-hover-01);
  border-color: var(--cds-link-primary);
  transform: translateX(4px);
}

.action-button i {
  font-size: 1.25rem;
  color: var(--cds-link-primary);
}

@media (max-width: 1024px) {
  .charts-grid {
    grid-template-columns: 1fr;
  }
}

@media (max-width: 768px) {
  .dashboard-page {
    padding: 1rem;
  }

  .page-header h1 {
    font-size: 1.5rem;
  }

  .welcome-text {
    font-size: 0.875rem;
  }

  .stats-grid {
    grid-template-columns: repeat(2, 1fr);
    gap: 1rem;
  }

  .stat-card {
    padding: 1rem;
  }

  .stat-icon {
    width: 50px;
    height: 50px;
    font-size: 1.25rem;
  }

  .stat-value {
    font-size: 1.5rem;
  }

  .charts-grid,
  .bottom-grid {
    grid-template-columns: 1fr;
  }

  .chart-card {
    padding: 1rem;
  }

  .recent-tickets-card,
  .quick-actions-card {
    padding: 1rem;
  }

  .card-header {
    flex-direction: column;
    align-items: flex-start;
    gap: 1rem;
  }

  .card-header ::deep bx-btn {
    width: 100%;
  }

  .actions-list {
    gap: 0.5rem;
  }

  .action-button {
    padding: 0.875rem;
    font-size: 0.875rem;
    width: 100%;
    justify-content: flex-start;
  }

  .action-button i {
    font-size: 1.125rem;
  }
}

@media (max-width: 480px) {
  .stats-grid {
    grid-template-columns: 1fr;
  }

  .stat-card {
    flex-direction: row;
    gap: 1rem;
  }

  .bottom-grid {
    grid-template-columns: 1fr;
  }

  .recent-tickets-card,
  .quick-actions-card {
    padding: 0.875rem;
  }

  .card-title {
    font-size: 1.125rem;
  }

  .action-button {
    padding: 0.75rem;
    font-size: 0.8125rem;
  }

  .action-button i {
    font-size: 1rem;
  }

  .ticket-item {
    flex-direction: column;
    align-items: flex-start;
    gap: 0.75rem;
  }

  .ticket-status {
    width: 100%;
  }

  .status-badge {
    display: inline-block;
  }
}
</style>

