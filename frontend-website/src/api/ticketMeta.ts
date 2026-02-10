import { http } from './http'

export interface TicketType {
  id: number
  name: string
}

export interface TicketPriority {
  id: number
  name: string
}

export interface TicketMetaResponse {
  types: TicketType[]
  priorities: TicketPriority[]
}

export const ticketMetaApi = {
  get: async (): Promise<TicketMetaResponse> => {
    const response = await http.get<TicketMetaResponse>('/ticket-meta')
    return response.data
  },
}

