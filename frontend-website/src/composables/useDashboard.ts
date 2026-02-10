import { computed } from 'vue'
import { useQuery } from '@tanstack/vue-query'
import { ticketsApi } from '@/api/tickets'
import type { Ticket } from '@/api/types'

export const useDashboard = () => {
  // Fetch all tickets for dashboard stats (with higher limit to get all)
  const { data: ticketsData, isLoading, error } = useQuery({
    queryKey: ['dashboard-tickets'],
    queryFn: () => ticketsApi.list(1, 100), // Get more tickets for stats
    refetchInterval: 30 * 1000, // Auto-refresh every 30 seconds
  })

  const tickets = computed<Ticket[]>(() => ticketsData.value?.data || [])

  // Calculate statistics
  const stats = computed(() => {
    const allTickets = tickets.value

    const totalTickets = allTickets.length
    const openTickets = allTickets.filter(
      (t) => t.status === 'Open' || t.status === 'New' || t.status === 'Pending'
    ).length
    const resolvedTickets = allTickets.filter((t) => t.status === 'Resolved' || t.status === 'Closed').length
    const pendingTickets = allTickets.filter((t) => t.status === 'Pending' || t.status === 'Waiting').length

    // Group by status
    const statusCounts: Record<string, number> = {}
    allTickets.forEach((ticket) => {
      const status = ticket.status || 'Unknown'
      statusCounts[status] = (statusCounts[status] || 0) + 1
    })

    // Group by priority
    const priorityCounts: Record<string, number> = {}
    allTickets.forEach((ticket) => {
      const priority = ticket.priority_id !== undefined ? String(ticket.priority_id) : 'Unknown'
      priorityCounts[priority] = (priorityCounts[priority] || 0) + 1
    })

    // Recent tickets (last 5)
    const recentTickets = [...allTickets]
      .sort((a, b) => (b.created_at || 0) - (a.created_at || 0))
      .slice(0, 5)

    return {
      totalTickets,
      openTickets,
      resolvedTickets,
      pendingTickets,
      statusCounts,
      priorityCounts,
      recentTickets,
    }
  })

  // Chart data for status distribution
  const statusChartData = computed(() => {
    const statusCounts = stats.value.statusCounts
    return {
      labels: Object.keys(statusCounts),
      series: Object.values(statusCounts),
    }
  })

  // Chart data for tickets over time (last 7 days)
  const timeSeriesData = computed(() => {
    const last7Days: string[] = Array.from({ length: 7 }, (_, i) => {
      const date = new Date()
      date.setDate(date.getDate() - (6 - i))
      return date.toISOString().split('T')[0] as string
    })

    const ticketsByDate: Record<string, number> = {}
    last7Days.forEach((date) => {
      ticketsByDate[date] = 0
    })

    tickets.value.forEach((ticket) => {
      if (ticket.created_at) {
        const ticketDate = new Date(ticket.created_at * 1000).toISOString().split('T')[0]
        if (ticketDate && ticketsByDate[ticketDate] !== undefined) {
          ticketsByDate[ticketDate]++
        }
      }
    })

    return {
      labels: last7Days.map((date) => {
        const d = new Date(date)
        return d.toLocaleDateString('id-ID', { month: 'short', day: 'numeric' })
      }),
      series: last7Days.map((date) => ticketsByDate[date] ?? 0),
    }
  })

  return {
    tickets,
    stats,
    statusChartData,
    timeSeriesData,
    isLoading,
    error,
  }
}

