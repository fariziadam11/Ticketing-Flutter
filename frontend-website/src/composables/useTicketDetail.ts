import { useQuery } from '@tanstack/vue-query'
import { ticketsApi } from '@/api/tickets'

export const useTicketDetail = (id: number) => {
  return useQuery({
    queryKey: ['tickets', id],
    queryFn: () => ticketsApi.getById(id),
    enabled: !!id,
  })
}

