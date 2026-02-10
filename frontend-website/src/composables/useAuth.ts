import { useMutation } from '@tanstack/vue-query'
import { useRouter } from 'vue-router'
import { authApi } from '@/api/auth'
import type { RegisterRequest, LoginRequest } from '@/api/auth'
import { useAuthStore } from '@/stores/auth'
import { useToast } from './useToast'

export const useLogin = () => {
  const router = useRouter()
  const authStore = useAuthStore()
  const toast = useToast()

  return useMutation({
    mutationFn: (payload: LoginRequest) => authApi.login(payload),
    onSuccess: (data) => {
      authStore.setAuth(data)
      toast.success('Login successful! Welcome back.')
      router.push('/dashboard')
    },
    onError: (error: unknown) => {
      // Error is already wrapped as Error object by http interceptor with message extracted from backend
      // Backend format: { success: false, error: "message" }
      let errorMessage = 'Failed to login. Please try again.'
      
      // Try to extract error message from various sources
      if (error instanceof Error) {
        // Error object from http interceptor already has message extracted from backend
        errorMessage = error.message || errorMessage
      } else if (error && typeof error === 'object') {
        // Try to extract from axios error if available (before interceptor wraps it)
        if ('response' in error) {
          const axiosError = error as { response?: { data?: { error?: string; message?: string } } }
          errorMessage = axiosError.response?.data?.error || axiosError.response?.data?.message || errorMessage
        } else if ('message' in error && typeof (error as { message: unknown }).message === 'string') {
          errorMessage = (error as { message: string }).message
        }
      }
      
      // Ensure we have a valid error message
      if (!errorMessage || errorMessage.trim() === '') {
        errorMessage = 'Failed to login. Please try again.'
      }
      
      // Always show error toast
      toast.error(errorMessage)
    },
  })
}

export const useRegister = () => {
  const router = useRouter()
  const authStore = useAuthStore()
  const toast = useToast()

  return useMutation({
    mutationFn: (payload: RegisterRequest) => authApi.register(payload),
    onSuccess: (data) => {
      authStore.setAuth(data)
      toast.success('Account created successfully! Welcome!')
      router.push('/dashboard')
    },
    onError: (error: unknown) => {
      // Error is already wrapped as Error object by http interceptor with message extracted from backend
      // Backend format: { success: false, error: "message" }
      let errorMessage = 'Failed to create account. Please try again.'
      
      if (error instanceof Error) {
        // Error object from http interceptor already has message extracted from backend
        errorMessage = error.message || errorMessage
      } else if (error && typeof error === 'object') {
        // Try to extract from axios error if available (before interceptor wraps it)
        if ('response' in error) {
          const axiosError = error as { response?: { data?: { error?: string; message?: string } } }
          errorMessage = axiosError.response?.data?.error || axiosError.response?.data?.message || errorMessage
        } else if ('message' in error && typeof (error as { message: unknown }).message === 'string') {
          errorMessage = (error as { message: string }).message
        }
      }
      
      // Ensure we have a valid error message
      if (!errorMessage || errorMessage.trim() === '') {
        errorMessage = 'Failed to create account. Please try again.'
      }
      
      toast.error(errorMessage)
    },
  })
}

