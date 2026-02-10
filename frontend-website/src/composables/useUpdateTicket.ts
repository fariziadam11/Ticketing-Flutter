import { useMutation, useQueryClient } from '@tanstack/vue-query'
import { ticketsApi } from '@/api/tickets'
import type { UpdateTicketPayload } from '@/api/types'
import { useToast } from './useToast'
import { TOAST_MESSAGES } from '@/utils/constants'

export const useUpdateTicket = (ticketId: number) => {
  const queryClient = useQueryClient()
  const toast = useToast()

  return useMutation({
    mutationFn: (payload: UpdateTicketPayload) =>
      ticketsApi.update(ticketId, payload),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['tickets'] })
      queryClient.invalidateQueries({ queryKey: ['ticket', ticketId] })
      toast.success(TOAST_MESSAGES.TICKET_UPDATED_SUCCESS)
    },
    onError: () => {
      // Error message already displayed by http interceptor
    },
  })
}

