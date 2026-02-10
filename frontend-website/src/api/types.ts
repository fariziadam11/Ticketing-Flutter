export interface Ticket {
  id: number
  pretty_id?: string
  inv_gate_id?: string | number
  wrk_ticket_id?: string
  title: string
  description?: string
  status: string
  status_id?: number
  priority_id?: number
  category_id?: number
  type_id?: number
  user_id?: number
  creator_id?: number
  assigned_id?: number
  assigned_group_id?: number
  created_at: number
  last_update?: number
  closed_at?: number | null
  closed_reason?: string | null
  solved_at?: number | null
  date_ocurred?: number
  location_id?: number
  source_id?: number
  attachments?: number[] | Attachment[]
  custom_fields?: any[]
  [key: string]: any
}

export interface Comment {
  id?: number
  comment?: string
  message?: string
  author?: string
  author_id?: number
  created_at?: number
  incident_id?: number
  attached_files?: number[] | Attachment[]
  attachments?: number[] | Attachment[]
  customer_visible?: boolean
  is_solution?: boolean
  msg_num?: number
  reference?: string | null
  [key: string]: any
}

export interface Attachment {
  id: number
  name: string
  url?: string
  hash?: string
  extension?: string
}

export interface Category {
  id: number
  name: string
  [key: string]: any
}

export interface PaginationMeta {
  page: number
  limit: number
  total: number
  total_pages: number
  has_next: boolean
  has_prev: boolean
}

export interface TicketsResponse {
  data: Ticket[]
  pagination?: PaginationMeta
}

export interface CommentsResponse {
  data: Comment[]
}

export interface CategoriesResponse {
  data: Category[]
}

export interface CreateTicketPayload {
  source_id: number
  category_id: number
  type_id: number
  priority_id: number
  title: string
  description: string
  date_ocurred?: number
  attachments?: File[]
}

export interface CreateCommentPayload {
  message: string
  customer_visible?: boolean
  attachments?: File[]
}

export interface UpdateTicketPayload {
  source_id?: number
  creator_id?: number
  customer_id?: number
  category_id?: number
  type_id?: number
  priority_id?: number
  title?: string
  description?: string
  date_ocurred?: number
}

