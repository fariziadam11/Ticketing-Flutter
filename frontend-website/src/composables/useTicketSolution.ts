import { useMutation, useQueryClient } from '@tanstack/vue-query'
import { ticketsApi } from '@/api/tickets'
import { useToast } from './useToast'
import type { AxiosError } from 'axios'

export const useTicketSolution = (ticketId: number) => {
  const queryClient = useQueryClient()
  const toast = useToast()

  const acceptMutation = useMutation({
    mutationFn: (payload: { rating: number; comment?: string }) =>
      ticketsApi.acceptSolution(ticketId, payload),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['ticket', ticketId] })
      queryClient.invalidateQueries({ queryKey: ['comments', ticketId] })
      toast.success('Solution accepted successfully!')
    },
    onError: () => {
      // Error message already displayed by http interceptor
    },
  })

  const rejectMutation = useMutation({
    mutationFn: (payload: { comment: string }) =>
      ticketsApi.rejectSolution(ticketId, payload),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['ticket', ticketId] })
      queryClient.invalidateQueries({ queryKey: ['comments', ticketId] })
      toast.success('Solution rejected. Ticket reopened.')
    },
    onError: () => {
      // Error message already displayed by http interceptor
    },
  })

  return {
    acceptMutation,
    rejectMutation,
  }
}


