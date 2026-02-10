import { http, createFormData } from './http'
import type { Comment, CommentsResponse, CreateCommentPayload } from './types'

export const commentsApi = {
  getByTicketId: async (ticketId: number): Promise<Comment[]> => {
    const response = await http.get<CommentsResponse>(
      `/tickets/${ticketId}/comments`
    )
    return response.data.data
  },

  create: async (
    ticketId: number,
    payload: CreateCommentPayload
  ): Promise<Comment> => {
    const formData = createFormData({
      comment: payload.message, // Backend expects "comment" field
      ...(payload.attachments && { attachments: payload.attachments }),
    })

    const response = await http.post<Comment>(
      `/tickets/${ticketId}/comments`,
      formData,
      {
        headers: {
          'Content-Type': 'multipart/form-data',
        },
      }
    )
    return response.data
  },
}

