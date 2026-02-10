import { ref, computed, type Ref } from 'vue'
import { useQuery } from '@tanstack/vue-query'
import { articlesApi } from '@/api/articles'
import type { Article } from '@/api/articles'

export const useArticles = (categoryId: Ref<number | null> = ref(null)) => {
  const queryKey = computed(() => ['articles', categoryId.value] as const)

  const query = useQuery({
    queryKey: queryKey,
    queryFn: () => {
      if (!categoryId.value) {
        throw new Error('Category ID is required')
      }
      return articlesApi.getByCategory(categoryId.value)
    },
    enabled: computed(() => categoryId.value !== null && categoryId.value > 0),
  })

  const articles = computed<Article[]>(() => query.data.value?.data || [])

  return {
    ...query,
    articles,
  }
}

