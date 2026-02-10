<script setup lang="ts">
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { useArticles } from '@/composables/useArticles'
import type { ArticleCategory } from '@/api/articles'

const router = useRouter()

const categories: ArticleCategory[] = [
  { id: 20, name: 'CRM' },
  { id: 16, name: 'ESS' },
  { id: 22, name: 'Intranet' },
  { id: 23, name: 'Job Portal' },
  { id: 17, name: 'Kehadiran' },
  { id: 21, name: 'LMS' },
  { id: 24, name: 'Pengaturan Perusahaan' },
  { id: 19, name: 'Penggajian' },
  { id: 18, name: 'Personalia' },
]

const selectedCategoryId = ref<number | null>(null)
const selectedCategoryName = ref<string>('')

const { articles, isLoading, error } = useArticles(selectedCategoryId)

const selectCategory = (category: ArticleCategory) => {
  selectedCategoryId.value = category.id
  selectedCategoryName.value = category.name
}

const goToArticleDetail = (articleId: number) => {
  if (selectedCategoryId.value) {
    router.push({
      path: `/articles/${articleId}`,
      query: { category_id: selectedCategoryId.value.toString() },
    })
  } else {
    router.push(`/articles/${articleId}`)
  }
}
</script>

<template>
  <div class="articles-page">
    <div class="page-header">
      <h1>Knowledge Base Articles</h1>
    </div>

    <div class="page-content">
      <!-- Category Cards -->
      <div class="categories-section">
        <h2 class="section-title">Select Category</h2>
        <div class="categories-grid">
          <button
            v-for="category in categories"
            :key="category.id"
            class="category-card"
            :class="{ active: selectedCategoryId === category.id }"
            @click="selectCategory(category)"
          >
            <div class="category-card-content">
              <h3 class="category-name">{{ category.name }}</h3>
            </div>
          </button>
        </div>
      </div>

      <!-- Articles Section -->
      <div v-if="selectedCategoryId" class="articles-section">
        <div class="articles-header">
          <h2 class="section-title">
            Articles - {{ selectedCategoryName }}
          </h2>
        </div>

        <div v-if="isLoading" class="loading-container">
          <bx-loading :active="isLoading" />
        </div>

        <div v-else-if="error" class="error-container">
          <p class="error-message">
            {{ error instanceof Error ? error.message : 'Failed to load articles' }}
          </p>
        </div>

        <div v-else-if="articles.length === 0" class="empty-container">
          <p class="empty-message">No articles found in this category.</p>
        </div>

        <div v-else class="articles-list">
          <div
            v-for="article in articles"
            :key="article.id"
            class="article-item"
            @click="goToArticleDetail(article.id)"
          >
            <h3 class="article-title">{{ article.title }}</h3>
          </div>
        </div>
      </div>

      <div v-else class="empty-selection">
        <p class="empty-message">Please select a category to view articles.</p>
      </div>
    </div>
  </div>
</template>

<style scoped>
.articles-page {
  padding: 2rem;
  max-width: 1400px;
  margin: 0 auto;
}

.page-header {
  margin-bottom: 2rem;
}

.page-header h1 {
  font-size: 2rem;
  font-weight: 600;
  color: var(--cds-text-primary);
  margin: 0;
}

.page-content {
  display: flex;
  flex-direction: column;
  gap: 2rem;
}

.section-title {
  font-size: 1.5rem;
  font-weight: 600;
  color: var(--cds-text-primary);
  margin-bottom: 1rem;
}

/* Categories Section */
.categories-section {
  margin-bottom: 2rem;
}

.categories-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
  gap: 1rem;
}

.category-card {
  background-color: var(--cds-layer-01);
  border: 2px solid var(--cds-border-subtle);
  border-radius: 8px;
  padding: 1.5rem;
  cursor: pointer;
  transition: all 0.2s ease;
  text-align: center;
  min-height: 100px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.category-card:hover {
  border-color: var(--cds-link-primary);
  background-color: var(--cds-layer-hover-01);
  transform: translateY(-2px);
  box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);
}

.category-card.active {
  border-color: var(--cds-link-primary);
  background-color: var(--cds-layer-selected);
}

.category-name {
  font-size: 1.125rem;
  font-weight: 500;
  color: var(--cds-text-primary);
  margin: 0;
}

/* Articles Section */
.articles-section {
  margin-top: 2rem;
}

.articles-header {
  margin-bottom: 1.5rem;
}

.loading-container,
.error-container,
.empty-container,
.empty-selection {
  display: flex;
  justify-content: center;
  align-items: center;
  padding: 3rem;
  text-align: center;
}

.error-message,
.empty-message {
  color: var(--cds-text-secondary);
  font-size: 1rem;
}

.error-message {
  color: var(--cds-support-error);
}

.articles-list {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}

.article-item {
  background-color: var(--cds-layer-01);
  border: 1px solid var(--cds-border-subtle);
  border-radius: 8px;
  padding: 1.25rem 1.5rem;
  cursor: pointer;
  transition: all 0.2s ease;
}

.article-item:hover {
  border-color: var(--cds-link-primary);
  background-color: var(--cds-layer-hover-01);
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
  transform: translateX(4px);
}

.article-item .article-title {
  font-size: 1.125rem;
  font-weight: 500;
  color: var(--cds-text-primary);
  margin: 0;
}

@media (max-width: 768px) {
  .articles-page {
    padding: 1rem;
  }

  .page-header h1 {
    font-size: 1.5rem;
  }

  .section-title {
    font-size: 1.25rem;
  }

  .categories-grid {
    grid-template-columns: repeat(auto-fill, minmax(150px, 1fr));
    gap: 0.75rem;
  }

  .category-card {
    padding: 1rem;
    min-height: 80px;
  }

  .category-name {
    font-size: 1rem;
  }

  .article-item {
    padding: 1rem;
  }

  .article-item .article-title {
    font-size: 1rem;
  }
}

@media (max-width: 480px) {
  .categories-grid {
    grid-template-columns: 1fr;
  }
}
</style>

