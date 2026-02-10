import { http } from './http'

export interface ArticleAttachment {
  id: number
  url: string
  name: string
}

export interface Article {
  id: number
  title: string
  author_id: number
  responsible_id: number
  content: string
  creation_date: number
  last_update_date: number
  solved_requests: string | number
  views: number
  category_id: number
  is_private: boolean
  attachments: ArticleAttachment[]
  rating: number
}

export interface ArticlesResponse {
  data: Article[]
}

export interface ArticleCategory {
  id: number
  name: string
}

export const articlesApi = {
  getByCategory: async (categoryId: number): Promise<ArticlesResponse> => {
    const response = await http.get<ArticlesResponse>(`/articles?category_id=${categoryId}`)
    return response.data
  },
}

