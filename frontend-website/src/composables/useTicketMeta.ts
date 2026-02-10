import { useQuery } from '@tanstack/vue-query'
import { ticketMetaApi } from '@/api/ticketMeta'

export const useTicketMeta = () => {
  return useQuery({
    queryKey: ['ticket-meta'],
    queryFn: () => ticketMetaApi.get(),
    staleTime: 1000 * 60 * 60, // 1 hour - metadata rarely changes
  })
}

