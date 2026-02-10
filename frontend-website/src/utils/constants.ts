export const COOKIE_NAMES = {
  ACCESS_TOKEN: 'access_token',
  REFRESH_TOKEN: 'refresh_token',
  USER: 'user',
} as const

export const COOKIE_OPTIONS = {
  EXPIRES_DAYS: 7,
  PATH: '/',
  SAME_SITE: 'lax' as const,
} as const

export const API_ENDPOINTS = {
  AUTH: {
    REGISTER: '/auth/register',
    LOGIN: '/auth/login',
    REFRESH: '/auth/refresh',
    LOGOUT: '/auth/logout',
  },
  TICKETS: {
    LIST: '/tickets',
    CREATE: '/tickets',
    DETAIL: (id: number | string) => `/tickets/${id}`,
    COMMENTS: (id: number | string) => `/tickets/${id}/comments`,
    SOLUTION: (id: number | string) => `/tickets/${id}/solution`,
    SOLUTION_REJECT: (id: number | string) => `/tickets/${id}/solution/reject`,
    ATTACHMENT: (id: number | string) => `/tickets/attachments/${id}`,
  },
  USERS: {
    DETAIL: (id: number | string) => `/users/${id}`,
  },
  META: {
    CATEGORIES: '/categories',
    TICKET_META: '/ticket-meta',
    STATUSES: '/statuses',
  },
} as const

export const POLLING_INTERVALS = {
  TICKETS_LIST: 30 * 1000,
  TICKET_DETAIL: 15 * 1000,
} as const

export const FILE_UPLOAD = {
  MAX_SIZE: 10 * 1024 * 1024, // 10 MB
  ALLOWED_IMAGE_TYPES: ['jpg', 'jpeg', 'png', 'gif', 'webp', 'svg', 'bmp'],
  ALLOWED_VIDEO_TYPES: ['mp4', 'webm', 'ogg', 'mov', 'avi'],
  ALLOWED_DOCUMENT_TYPES: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt'],
} as const

export const TICKET_DEFAULTS = {
  SOURCE_ID: 2,
} as const

export const VALIDATION = {
  PASSWORD_MIN_LENGTH: 6,
  TITLE_MIN_LENGTH: 3,
  TITLE_MAX_LENGTH: 255,
  DESCRIPTION_MIN_LENGTH: 10,
} as const

export const TOAST = {
  DURATION: {
    SHORT: 3000,
    MEDIUM: 5000,
    LONG: 7000,
  },
  POSITION: {
    TOP_RIGHT: 'top-right',
    TOP_LEFT: 'top-left',
    BOTTOM_RIGHT: 'bottom-right',
    BOTTOM_LEFT: 'bottom-left',
  },
} as const

export const DATE_FORMATS = {
  DISPLAY: 'MMM DD, YYYY HH:mm',
  DATE_ONLY: 'MMM DD, YYYY',
  TIME_ONLY: 'HH:mm',
} as const

export const TOAST_MESSAGES = {
  LOGIN_SUCCESS: 'Logged in successfully',
  ACCOUNT_CREATED_SUCCESS: 'Account created successfully',
  LOGOUT_SUCCESS: 'Logged out successfully',
  TICKET_CREATED_SUCCESS: 'Ticket created successfully',
  COMMENT_ADDED_SUCCESS: 'Comment added successfully',
  SOLUTION_ACCEPTED_SUCCESS: 'Solution accepted successfully',
  SOLUTION_REJECTED_SUCCESS: 'Solution rejected successfully',
  TICKET_UPDATED_SUCCESS: 'Ticket updated successfully',
  SESSION_EXPIRED: 'Your session has expired. Please log in again.',
  NETWORK_ERROR: 'Network error. Please check your connection.',
  GENERIC_ERROR: 'An error occurred. Please try again.',
} as const

