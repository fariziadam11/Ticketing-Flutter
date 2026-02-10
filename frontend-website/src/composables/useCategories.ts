import { useQuery } from '@tanstack/vue-query'
import { categoriesApi } from '@/api/categories'

export const useCategories = () => {
  return useQuery({
    queryKey: ['categories'],
    queryFn: () => categoriesApi.list(),
  })
}

