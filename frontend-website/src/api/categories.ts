import { http } from './http'
import type { Category, CategoriesResponse } from './types'

export const categoriesApi = {
  list: async (): Promise<Category[]> => {
    const response = await http.get<CategoriesResponse>('/categories')
    return response.data.data
  },
}

