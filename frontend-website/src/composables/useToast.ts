import { useToastStore } from '@/stores/toast'
import { TOAST } from '@/utils/constants'

export const useToast = () => {
  const toastStore = useToastStore()

  return {
    success: (message: string, duration = TOAST.DURATION.MEDIUM) => {
      return toastStore.success(message, duration)
    },
    error: (message: string, duration = TOAST.DURATION.LONG) => {
      return toastStore.error(message, duration)
    },
    warning: (message: string, duration = TOAST.DURATION.MEDIUM) => {
      return toastStore.warning(message, duration)
    },
    info: (message: string, duration = TOAST.DURATION.SHORT) => {
      return toastStore.info(message, duration)
    },
  }
}

