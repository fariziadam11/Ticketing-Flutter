import { ref, computed, type Ref } from 'vue'
import { useQuery } from '@tanstack/vue-query'
import { ticketsApi } from '@/api/tickets'
import type { PaginationMeta } from '@/api/types'

export const useTickets = (page: Ref<number> = ref(1), limit: Ref<number> = ref(2)) => {
  const queryKey = computed(() => ['tickets', page.value, limit.value] as const)
  
  const query = useQuery({
    queryKey: queryKey,
    queryFn: () => ticketsApi.list(page.value, limit.value),
    refetchInterval: 30 * 1000, // Auto-refresh every 30 seconds
  })

  const tickets = computed(() => query.data.value?.data || [])
  const pagination = computed<PaginationMeta | undefined>(() => query.data.value?.pagination)

  return {
    ...query,
    tickets,
    pagination,
    // Helper methods
    nextPage: () => {
      if (pagination.value?.has_next) {
        page.value++
      }
    },
    prevPage: () => {
      if (pagination.value?.has_prev) {
        page.value--
      }
    },
    goToPage: (newPage: number) => {
      // Allow page change even if pagination metadata not yet loaded
      if (newPage >= 1) {
        page.value = newPage
      }
    },
    setLimit: (newLimit: number) => {
      limit.value = newLimit
      page.value = 1 // Reset to first page when changing limit
    },
  }
}

