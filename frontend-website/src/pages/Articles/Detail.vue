<script setup lang="ts">
import { computed, onMounted, nextTick, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useArticles } from '@/composables/useArticles'

interface Props {
  id: string
}

const props = defineProps<Props>()
const route = useRoute()
const router = useRouter()

const articleId = computed(() => parseInt(props.id || String(route.params.id), 10))

// Get category ID from route query
const categoryId = computed(() => {
  const catId = route.query.category_id
  return catId ? parseInt(String(catId), 10) : null
})

const { articles, isLoading, error } = useArticles(categoryId)

// Find the article from the list
const foundArticle = computed(() => {
  if (!articles.value || articles.value.length === 0) return null
  return articles.value.find((a) => a.id === articleId.value) || null
})

const formatDate = (timestamp: number): string => {
  const date = new Date(timestamp * 1000)
  return date.toLocaleDateString('id-ID', {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  })
}

const formatRating = (rating: number): string => {
  return rating > 0 ? `${rating.toFixed(1)} ⭐` : 'No rating'
}

const goBack = () => {
  router.push('/articles')
}

// Process content to ensure images load correctly after content is rendered
const processImages = () => {
  nextTick(() => {
    const contentEl = document.querySelector('.article-content')
    if (contentEl) {
      const images = contentEl.querySelectorAll('img')
      images.forEach((img) => {
        // Force image to be visible
        img.style.display = 'block'
        img.style.visibility = 'visible'
        img.style.opacity = '1'
        
        // Set referrer policy to allow loading from external domains
        img.referrerPolicy = 'no-referrer'
        
        // Handle image loading with retry mechanism
        const originalSrc = img.src
        let retryCount = 0
        const maxRetries = 3
        
        // Fix URL immediately if it has port 443 (should be removed for HTTPS)
        if (originalSrc.includes(':443/')) {
          const fixedSrc = originalSrc.replace(':443/', '/')
          img.src = fixedSrc
        }
        
        img.onerror = () => {
          console.warn('Image failed to load:', img.src, 'Retry:', retryCount)
          
          // Try different URL variations
          if (retryCount < maxRetries) {
            retryCount++
            let newSrc = originalSrc
            
            if (retryCount === 1) {
              // First retry: Remove port 443
              if (newSrc.includes(':443/')) {
                newSrc = newSrc.replace(':443/', '/')
              }
            } else if (retryCount === 2) {
              // Second retry: Try HTTPS
              if (newSrc.startsWith('http://')) {
                newSrc = newSrc.replace('http://', 'https://')
                newSrc = newSrc.replace(':443/', '/')
              }
            } else if (retryCount === 3) {
              // Third retry: Try HTTP without port
              if (newSrc.includes('https://')) {
                newSrc = newSrc.replace('https://', 'http://')
              }
              newSrc = newSrc.replace(':443/', '/')
            }
            
            console.log('Retrying with URL:', newSrc)
            img.src = newSrc
          } else {
            // Show placeholder or error message
            img.alt = 'Image failed to load'
            img.style.border = '1px dashed #ccc'
            img.style.padding = '1rem'
            img.style.backgroundColor = '#f5f5f5'
            img.style.minHeight = '100px'
            img.style.display = 'flex'
            img.style.alignItems = 'center'
            img.style.justifyContent = 'center'
          }
        }
        
        // Force reload if image is already loaded but not showing
        if (img.complete && img.naturalHeight === 0) {
          img.src = originalSrc + (originalSrc.includes('?') ? '&' : '?') + 't=' + Date.now()
        }
      })
    }
  })
}

onMounted(() => {
  processImages()
})

// Watch for article changes to process images
watch(foundArticle, () => {
  processImages()
}, { immediate: true })
</script>

<template>
  <div class="article-detail-page">
    <div class="page-header">
      <button class="back-button" @click="goBack">
        <i class="pi pi-arrow-left"></i>
        Back to Article Category List
      </button>
    </div>

    <div v-if="isLoading" class="loading-container">
      <bx-loading :active="isLoading" />
    </div>

    <div v-else-if="error" class="error-container">
      <p class="error-message">
        {{ error instanceof Error ? error.message : 'Failed to load article' }}
      </p>
      <bx-btn @click="goBack">Go Back</bx-btn>
    </div>

    <div v-else-if="!foundArticle" class="not-found-container">
      <p class="not-found-message">Article not found.</p>
      <bx-btn @click="goBack">Go Back</bx-btn>
    </div>

    <div v-else-if="foundArticle" class="article-detail">
      <div class="article-header">
        <h1 class="article-title">{{ foundArticle.title }}</h1>
        <div class="article-meta">
          <span class="meta-item">
            <i class="pi pi-star"></i>
            {{ formatRating(foundArticle.rating) }}
          </span>
          <span class="meta-item">
            <i class="pi pi-eye"></i>
            {{ foundArticle.views }} views
          </span>
          <span v-if="foundArticle.solved_requests" class="meta-item">
            <i class="pi pi-check-circle"></i>
            Solved {{ foundArticle.solved_requests }} requests
          </span>
        </div>
      </div>

      <div class="article-info">
        <div class="info-item">
          <span class="info-label">Created:</span>
          <span class="info-value">{{ formatDate(foundArticle.creation_date) }}</span>
        </div>
        <div v-if="foundArticle.last_update_date !== foundArticle.creation_date" class="info-item">
          <span class="info-label">Last Updated:</span>
          <span class="info-value">{{ formatDate(foundArticle.last_update_date) }}</span>
        </div>
      </div>

      <div class="article-content-wrapper">
        <div class="article-content" v-html="foundArticle.content"></div>
      </div>

      <div v-if="foundArticle.attachments && foundArticle.attachments.length > 0" class="article-attachments">
        <h2 class="attachments-title">Attachments</h2>
        <ul class="attachments-list">
          <li v-for="attachment in foundArticle.attachments" :key="attachment.id" class="attachment-item">
            <a
              :href="attachment.url"
              target="_blank"
              rel="noopener noreferrer"
              class="attachment-link"
            >
              <i class="pi pi-file"></i>
              <span class="attachment-name">{{ attachment.name }}</span>
              <i class="pi pi-external-link"></i>
            </a>
          </li>
        </ul>
      </div>
    </div>
  </div>
</template>

<style scoped>
.article-detail-page {
  padding: 2rem;
  max-width: 1000px;
  margin: 0 auto;
}

.page-header {
  margin-bottom: 2rem;
}

.back-button {
  display: inline-flex;
  align-items: center;
  gap: 0.5rem;
  background: none;
  border: 1px solid var(--cds-border-subtle);
  border-radius: 4px;
  padding: 0.5rem 1rem;
  color: var(--cds-text-primary);
  cursor: pointer;
  font-size: 0.875rem;
  transition: all 0.2s ease;
}

.back-button:hover {
  background-color: var(--cds-layer-hover-01);
  border-color: var(--cds-link-primary);
}

.back-button i {
  font-size: 0.875rem;
}

.loading-container,
.error-container,
.not-found-container {
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  padding: 3rem;
  text-align: center;
  gap: 1rem;
}

.error-message,
.not-found-message {
  color: var(--cds-text-secondary);
  font-size: 1rem;
}

.error-message {
  color: var(--cds-support-error);
}

.article-detail {
  display: flex;
  flex-direction: column;
  gap: 2rem;
}

.article-header {
  display: flex;
  flex-direction: column;
  gap: 1rem;
  padding-bottom: 1.5rem;
  border-bottom: 2px solid var(--cds-border-subtle);
}

.article-title {
  font-size: 2rem;
  font-weight: 600;
  color: var(--cds-text-primary);
  margin: 0;
  line-height: 1.3;
}

.article-meta {
  display: flex;
  flex-wrap: wrap;
  gap: 1.5rem;
  font-size: 0.875rem;
  color: var(--cds-text-secondary);
}

.meta-item {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.meta-item i {
  font-size: 1rem;
}

.meta-item:first-child {
  color: var(--cds-support-warning);
  font-weight: 500;
}

.article-info {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
  padding: 1rem;
  background-color: var(--cds-layer-01);
  border-radius: 8px;
  border: 1px solid var(--cds-border-subtle);
}

.info-item {
  display: flex;
  gap: 0.5rem;
  font-size: 0.875rem;
}

.info-label {
  color: var(--cds-text-secondary);
  font-weight: 500;
}

.info-value {
  color: var(--cds-text-primary);
}

.article-content-wrapper {
  background-color: var(--cds-layer-01);
  border: 1px solid var(--cds-border-subtle);
  border-radius: 8px;
  padding: 2rem;
}

.article-content {
  color: var(--cds-text-primary);
  line-height: 1.8;
  font-size: 1rem;
}

.article-content :deep(p) {
  margin: 0 0 1rem 0;
}

.article-content :deep(p:last-child) {
  margin-bottom: 0;
}

.article-content :deep(h1),
.article-content :deep(h2),
.article-content :deep(h3),
.article-content :deep(h4),
.article-content :deep(h5),
.article-content :deep(h6) {
  margin: 1.5rem 0 1rem 0;
  color: var(--cds-text-primary);
  font-weight: 600;
}

.article-content :deep(h1:first-child),
.article-content :deep(h2:first-child),
.article-content :deep(h3:first-child) {
  margin-top: 0;
}

.article-content :deep(img) {
  max-width: 100% !important;
  width: auto !important;
  height: auto !important;
  border-radius: 8px;
  margin: 1rem 0 !important;
  display: block !important;
  object-fit: contain;
  visibility: visible !important;
  opacity: 1 !important;
  position: relative !important;
  z-index: 1 !important;
}

.article-content :deep(p img),
.article-content :deep(div img),
.article-content :deep(span img) {
  display: block !important;
  margin: 1rem auto;
  max-width: 100%;
}

.article-content :deep(.embeddedContent),
.article-content :deep([data-oembed]) {
  margin: 1rem 0;
  display: block;
}

.article-content :deep(embed),
.article-content :deep(iframe),
.article-content :deep(object) {
  max-width: 100%;
  width: 100%;
  height: auto;
  min-height: 300px;
  border-radius: 8px;
  margin: 1rem 0;
  display: block;
}

.article-content :deep(video) {
  max-width: 100%;
  width: 100%;
  height: auto;
  border-radius: 8px;
  margin: 1rem 0;
  display: block;
}

.article-content :deep(a) {
  color: var(--cds-link-primary);
  text-decoration: none;
}

.article-content :deep(a:hover) {
  text-decoration: underline;
}

.article-content :deep(ul),
.article-content :deep(ol) {
  margin: 1rem 0;
  padding-left: 2rem;
}

.article-content :deep(li) {
  margin: 0.5rem 0;
}

.article-content :deep(blockquote) {
  border-left: 4px solid var(--cds-link-primary);
  padding-left: 1rem;
  margin: 1rem 0;
  color: var(--cds-text-secondary);
  font-style: italic;
}

.article-content :deep(code) {
  background-color: var(--cds-layer-02);
  padding: 0.125rem 0.375rem;
  border-radius: 4px;
  font-family: 'Courier New', monospace;
  font-size: 0.875em;
}

.article-content :deep(pre) {
  background-color: var(--cds-layer-02);
  padding: 1rem;
  border-radius: 8px;
  overflow-x: auto;
  margin: 1rem 0;
}

.article-content :deep(pre code) {
  background: none;
  padding: 0;
}

.article-attachments {
  padding: 1.5rem;
  background-color: var(--cds-layer-01);
  border: 1px solid var(--cds-border-subtle);
  border-radius: 8px;
}

.attachments-title {
  font-size: 1.25rem;
  font-weight: 600;
  color: var(--cds-text-primary);
  margin: 0 0 1rem 0;
}

.attachments-list {
  list-style: none;
  padding: 0;
  margin: 0;
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}

.attachment-item {
  margin: 0;
}

.attachment-link {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 0.75rem 1rem;
  background-color: var(--cds-layer-02);
  border: 1px solid var(--cds-border-subtle);
  border-radius: 8px;
  color: var(--cds-link-primary);
  text-decoration: none;
  font-size: 0.875rem;
  transition: all 0.2s ease;
}

.attachment-link:hover {
  background-color: var(--cds-layer-hover-01);
  border-color: var(--cds-link-primary);
  transform: translateX(4px);
}

.attachment-link i {
  font-size: 1rem;
}

.attachment-name {
  flex: 1;
}

@media (max-width: 768px) {
  .article-detail-page {
    padding: 1rem;
  }

  .page-header {
    margin-bottom: 1.5rem;
  }

  .article-title {
    font-size: 1.5rem;
  }

  .article-meta {
    flex-direction: column;
    gap: 0.75rem;
  }

  .article-content-wrapper {
    padding: 1.5rem;
  }

  .article-info {
    padding: 0.75rem;
  }

  .article-attachments {
    padding: 1rem;
  }
}

@media (max-width: 480px) {
  .article-title {
    font-size: 1.25rem;
  }

  .article-content-wrapper {
    padding: 1rem;
  }

  .back-button {
    width: 100%;
    justify-content: center;
  }
}
</style>

