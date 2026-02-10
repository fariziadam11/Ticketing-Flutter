import { http } from './http'
import type { Attachment } from './types'
import { logger } from '@/utils/logger'

export const attachmentsApi = {
  getById: async (attachmentId: number): Promise<Blob> => {
    const response = await http.get(`/tickets/attachments/${attachmentId}`, {
      responseType: 'blob',
    })
    return response.data
  },

  getDetail: async (attachmentId: number): Promise<Attachment> => {
    const response = await http.get<{ data?: Attachment; success?: boolean } | Attachment>(
      `/tickets/attachments/${attachmentId}`,
      {
        headers: {
          Accept: 'application/json',
        },
      }
    )
    
    logger.debug('Attachment detail response', response.data)
    
    const responseData = response.data
    if (responseData && typeof responseData === 'object') {
      if ('data' in responseData && 'success' in responseData) {
        const wrapped = responseData as { data: Attachment; success: boolean }
        logger.debug('Wrapped response, data', wrapped.data)
        return wrapped.data
      }
      if ('id' in responseData && ('url' in responseData || 'name' in responseData)) {
        logger.debug('Direct attachment object', responseData)
        return responseData as Attachment
      }
    }
    
    logger.warn('Unexpected response format', responseData)
    return responseData as Attachment
  },

  getUrl: (attachmentId: number): string => {
    const baseURL = import.meta.env.VITE_API_BASE_URL || 'http://localhost:8080/api/v1'
    return `${baseURL}/tickets/attachments/${attachmentId}`
  },
}

