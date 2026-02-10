import { useMutation, useQueryClient } from '@tanstack/vue-query'
import { useRouter } from 'vue-router'
import { ticketsApi } from '@/api/tickets'
import type { CreateTicketPayload } from '@/api/types'
import { useToast } from './useToast'

export const useCreateTicket = () => {
  const queryClient = useQueryClient()
  const router = useRouter()
  const toast = useToast()

  return useMutation({
    mutationFn: (payload: CreateTicketPayload) => ticketsApi.create(payload),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['tickets'] })
      toast.success('Ticket created successfully!')
      router.push('/tickets')
    },
    onError: () => {
      // Error message already displayed by http interceptor
    },
  })
}

