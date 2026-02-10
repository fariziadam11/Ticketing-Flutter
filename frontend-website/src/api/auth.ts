import { http } from './http'

export interface RegisterRequest {
  name: string
  lastname: string
  email: string
  password: string
}

export interface LoginRequest {
  email: string
  password: string
}

export interface AuthResponse {
  token: string
  refresh_token?: string
  name: string
  lastname: string
  email: string
}

export interface RefreshTokenRequest {
  refresh_token: string
}

export const authApi = {
  register: async (payload: RegisterRequest): Promise<AuthResponse> => {
    const response = await http.post<AuthResponse>('/auth/register', payload)
    return response.data
  },

  login: async (payload: LoginRequest): Promise<AuthResponse> => {
    const response = await http.post<AuthResponse>('/auth/login', payload)
    return response.data
  },

  refreshToken: async (refreshToken: string): Promise<AuthResponse> => {
    const response = await http.post<AuthResponse>('/auth/refresh', {
      refresh_token: refreshToken,
    } as RefreshTokenRequest)
    return response.data
  },

  revokeToken: async (token: string): Promise<void> => {
    await http.post('/auth/revoke', null, {
      headers: {
        Authorization: `Bearer ${token}`,
      },
    })
  },
}

