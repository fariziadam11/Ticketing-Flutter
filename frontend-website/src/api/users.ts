import { http } from './http'

export interface InvGateUser {
  id: number
  name?: string
  lastname?: string
  email?: string
  type?: number
  [key: string]: any
}

export const usersApi = {
  getById: async (id: number): Promise<InvGateUser> => {
    const response = await http.get<InvGateUser>(`/users/${id}`)
    return response.data
  },
}


