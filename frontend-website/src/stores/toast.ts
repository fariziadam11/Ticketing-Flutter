import { defineStore } from 'pinia'
import { ref } from 'vue'

export type ToastType = 'success' | 'error' | 'warning' | 'info'

export interface Toast {
  id: string
  type: ToastType
  message: string
  duration?: number
  timestamp: number
}

export const useToastStore = defineStore('toast', () => {
  const toasts = ref<Toast[]>([])

  const addToast = (
    type: ToastType,
    message: string,
    duration?: number
  ): string => {
    const id = `toast-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`
    const toast: Toast = {
      id,
      type,
      message,
      duration,
      timestamp: Date.now(),
    }

    toasts.value.push(toast)

    if (duration && duration > 0) {
      setTimeout(() => {
        removeToast(id)
      }, duration)
    }

    return id
  }

  const removeToast = (id: string): void => {
    const index = toasts.value.findIndex((toast) => toast.id === id)
    if (index > -1) {
      toasts.value.splice(index, 1)
    }
  }

  const clearAll = (): void => {
    toasts.value = []
  }

  const success = (message: string, duration?: number): string => {
    return addToast('success', message, duration)
  }

  const error = (message: string, duration?: number): string => {
    return addToast('error', message, duration)
  }

  const warning = (message: string, duration?: number): string => {
    return addToast('warning', message, duration)
  }

  const info = (message: string, duration?: number): string => {
    return addToast('info', message, duration)
  }

  return {
    toasts,
    addToast,
    removeToast,
    clearAll,
    success,
    error,
    warning,
    info,
  }
})

