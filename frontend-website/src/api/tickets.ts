import { http, createFormData } from './http'
import type {
  Ticket,
  TicketsResponse,
  CreateTicketPayload,
  UpdateTicketPayload,
} from './types'

export const ticketsApi = {
  list: async (page = 1, limit = 2): Promise<TicketsResponse> => {
    const response = await http.get<TicketsResponse>(`/tickets?page=${page}&limit=${limit}`)
    return response.data
  },

  getById: async (id: number): Promise<Ticket> => {
    const response = await http.get<Ticket>(`/tickets/${id}`)
    return response.data
  },

  create: async (payload: CreateTicketPayload): Promise<Ticket> => {
    const formData = createFormData({
      source_id: payload.source_id,
      category_id: payload.category_id,
      type_id: payload.type_id,
      priority_id: payload.priority_id,
      title: payload.title,
      description: payload.description,
      date_ocurred: payload.date_ocurred || Math.floor(Date.now() / 1000),
      ...(payload.attachments && { attachments: payload.attachments }),
    })

    const response = await http.post<Ticket>('/tickets', formData, {
      headers: {
        'Content-Type': 'multipart/form-data',
      },
    })
    return response.data
  },

  acceptSolution: async (
    ticketId: number,
    payload: { rating: number; comment?: string },
  ): Promise<void> => {
    await http.put(`/tickets/${ticketId}/solution`, payload)
  },

  rejectSolution: async (
    ticketId: number,
    payload: { comment: string },
  ): Promise<void> => {
    await http.put(`/tickets/${ticketId}/solution/reject`, payload)
  },

  update: async (
    ticketId: number,
    payload: UpdateTicketPayload,
  ): Promise<Ticket> => {
    const response = await http.put<Ticket>(`/tickets/${ticketId}`, payload)
    return response.data
  },
}

