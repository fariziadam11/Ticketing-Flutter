import axios, { type AxiosError, type InternalAxiosRequestConfig } from 'axios'
import { getCookie, setCookie, removeCookie } from '@/utils/cookies'
import { logger } from '@/utils/logger'
import { useToastStore } from '@/stores/toast'
import { COOKIE_NAMES, COOKIE_OPTIONS } from '@/utils/constants'

const refreshHttp = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL || 'http://localhost:8080/api/v1',
  withCredentials: false,
  headers: {
    'Content-Type': 'application/json',
  },
})

let isRefreshing = false
let failedQueue: Array<{
  resolve: (value: any) => void
  reject: (error: any) => void
}> = []

const processQueue = (error: Error | null, token: string | null = null) => {
  failedQueue.forEach((prom) => {
    if (error) {
      prom.reject(error)
    } else {
      prom.resolve(token)
    }
  })
  failedQueue = []
}

export const http = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL || 'http://localhost:8080/api/v1',
  withCredentials: false,
  headers: {
    'Content-Type': 'application/json',
  },
})

http.interceptors.request.use(
  (config) => {
    const token = getCookie(COOKIE_NAMES.ACCESS_TOKEN)
    if (token) {
      config.headers.Authorization = `Bearer ${token}`
    }
    return config
  },
  (error) => {
    return Promise.reject(error)
  }
)

http.interceptors.response.use(
  (response) => {
    return response
  },
  async (error: AxiosError<{ message?: string; error?: string; code?: string }>) => {
    const originalRequest = error.config as InternalAxiosRequestConfig & {
      _retry?: boolean
    }

    // Only attempt token refresh for 401 errors if:
    // 1. Request has Authorization header (authenticated request)
    // 2. Not already retried
    // 3. Not an auth endpoint (login/register should not trigger refresh)
    const hasAuthHeader = originalRequest?.headers?.Authorization
    const isAuthEndpoint = originalRequest?.url?.includes('/auth/register') || originalRequest?.url?.includes('/auth/login')
    
    if (error.response?.status === 401 && !originalRequest._retry && hasAuthHeader && !isAuthEndpoint) {
      if (isRefreshing) {
        return new Promise((resolve, reject) => {
          failedQueue.push({
            resolve: (token: string) => {
              if (originalRequest.headers) {
                originalRequest.headers.Authorization = `Bearer ${token}`
              }
              resolve(http(originalRequest))
            },
            reject: (err: Error) => {
              reject(err)
            },
          })
        })
      }

      originalRequest._retry = true
      isRefreshing = true

      const refreshToken = getCookie(COOKIE_NAMES.REFRESH_TOKEN)

      if (!refreshToken) {
        isRefreshing = false
        processQueue(new Error('No refresh token available'), null)
        if (typeof window !== 'undefined') {
          window.location.href = '/login'
        }
        const message =
          error.response?.data?.message ||
          error.message ||
          'Session expired. Please login again.'
        return Promise.reject(new Error(message))
      }

      try {
        const response = await refreshHttp.post<{
          token: string
          refresh_token?: string
          name: string
          lastname: string
          email: string
        }>('/auth/refresh', {
          refresh_token: refreshToken,
        })
        const { token: newToken, refresh_token: newRefreshToken } = response.data

        setCookie(COOKIE_NAMES.ACCESS_TOKEN, newToken, {
          expires: COOKIE_OPTIONS.EXPIRES_DAYS,
          path: COOKIE_OPTIONS.PATH,
          secure: import.meta.env.PROD,
          sameSite: COOKIE_OPTIONS.SAME_SITE,
        })

        if (newRefreshToken) {
          setCookie(COOKIE_NAMES.REFRESH_TOKEN, newRefreshToken, {
            expires: COOKIE_OPTIONS.EXPIRES_DAYS,
            path: COOKIE_OPTIONS.PATH,
            secure: import.meta.env.PROD,
            sameSite: COOKIE_OPTIONS.SAME_SITE,
          })
        }

        if (typeof window !== 'undefined') {
          const { useAuthStore } = await import('@/stores/auth')
          const authStore = useAuthStore()
          authStore.setAuth(response.data)
        }

        processQueue(null, newToken)

        if (originalRequest.headers) {
          originalRequest.headers.Authorization = `Bearer ${newToken}`
        }
        isRefreshing = false
        return http(originalRequest)
      } catch (refreshError) {
        isRefreshing = false
        processQueue(refreshError as Error, null)

        if (typeof window !== 'undefined') {
          removeCookie(COOKIE_NAMES.ACCESS_TOKEN, { path: COOKIE_OPTIONS.PATH })
          removeCookie(COOKIE_NAMES.REFRESH_TOKEN, { path: COOKIE_OPTIONS.PATH })
          removeCookie(COOKIE_NAMES.USER, { path: COOKIE_OPTIONS.PATH })

          const { useAuthStore } = await import('@/stores/auth')
          const authStore = useAuthStore()
          authStore.clearAuth()

          window.location.href = '/login'
        }

        const message =
          (refreshError as Error).message ||
          'Session expired. Please login again.'
        return Promise.reject(new Error(message))
      }
    }

    let message = 'An error occurred'
    if (error.response?.data) {
      const errorData = error.response.data
      message = errorData.error || errorData.message || error.message || 'An error occurred'
    } else {
      message = error.message || 'An error occurred'
    }

    logger.error('API request failed', error, {
      url: error.config?.url,
      method: error.config?.method,
      status: error.response?.status,
    })

    if (typeof window !== 'undefined') {
      const toastStore = useToastStore()
      // Skip toast for auth endpoints (register/login) as they handle errors in their composables
      const isAuthEndpoint = originalRequest?.url?.includes('/auth/register') || originalRequest?.url?.includes('/auth/login')
      
      if (error.response?.status) {
        // Show toast for all client errors (4xx) and server errors (5xx), skip auth endpoints
        if (error.response.status >= 400 && !isAuthEndpoint) {
          toastStore.error(message)
        }
      } else if (!isAuthEndpoint) {
        toastStore.error('Network error. Please check your connection.')
      }
    }

    return Promise.reject(new Error(message))
  }
)

export const createFormData = (data: Record<string, any>): FormData => {
  const formData = new FormData()
  Object.entries(data).forEach(([key, value]) => {
    if (value !== null && value !== undefined) {
      if (value instanceof File) {
        formData.append(key, value)
      } else if (value instanceof FileList) {
        Array.from(value).forEach((file) => {
          formData.append(key, file)
        })
      } else if (Array.isArray(value)) {
        if (value.length > 0 && value[0] instanceof File) {
          value.forEach((file) => {
            formData.append(key, file)
          })
        } else {
          value.forEach((item) => {
            formData.append(key, String(item))
          })
        }
      } else {
        formData.append(key, String(value))
      }
    }
  })
  return formData
}

