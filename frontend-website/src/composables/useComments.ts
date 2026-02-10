import { useQuery, useMutation, useQueryClient } from '@tanstack/vue-query'
import { commentsApi } from '@/api/comments'
import type { CreateCommentPayload } from '@/api/types'
import { useToast } from './useToast'

export const useComments = (ticketId: number) => {
  return useQuery({
    queryKey: ['comments', ticketId],
    queryFn: () => commentsApi.getByTicketId(ticketId),
    enabled: !!ticketId,
  })
}

export const useCreateComment = (ticketId: number) => {
  const queryClient = useQueryClient()
  const toast = useToast()

  return useMutation({
    mutationFn: (payload: CreateCommentPayload) =>
      commentsApi.create(ticketId, payload),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['comments', ticketId] })
      toast.success('Comment added successfully!')
    },
    onError: () => {
      // Error message already displayed by http interceptor
    },
  })
}

