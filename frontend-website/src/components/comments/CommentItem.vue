<script setup lang="ts">
import { computed } from 'vue'
import type { Comment, Attachment } from '@/api/types'
import { formatUnixTimestamp } from '@/utils/date'
import AttachmentPreview from '../attachments/AttachmentPreview.vue'
import { useUserName } from '@/composables/useUserName'

interface Props {
  comment: Comment
}

const props = defineProps<Props>()

const { displayName, isAgent } = useUserName(props.comment.author_id)

const stripHtml = (value?: string) => {
  if (!value) return ''
  return value.replace(/<[^>]*>/g, '').trim()
}

const displayMessage = computed(() => {
  const raw = props.comment.message || props.comment.comment || ''
  return stripHtml(raw)
})

const getAttachments = (comment: Comment): Array<number | Attachment> => {
  const attachments = comment.attached_files || comment.attachments
  if (!attachments || !Array.isArray(attachments)) return []
  
  return attachments.map((item) => {
    if (typeof item === 'number') {
      return item
    }
    return item as Attachment
  })
}
</script>

<template>
  <bx-tile :id="`commentItemTile-${comment.id || 'unknown'}`">
    <div class="comment-item">
      <div class="comment-header">
        <span class="comment-author">
          <span class="comment-author-icon" aria-hidden="true">
            <i v-if="isAgent" class="pi pi-id-card"></i>
            <i v-else class="pi pi-user"></i>
          </span>
          <span class="comment-author-name">
            {{ comment.author || displayName || `User #${comment.author_id || 'Unknown'}` }}
          </span>
        </span>
        <span class="comment-date">
          {{ formatUnixTimestamp(comment.created_at) }}
        </span>
      </div>
      <div class="comment-body">
        {{ displayMessage || 'No message' }}
      </div>
      <div v-if="getAttachments(comment).length > 0" class="comment-attachments">
        <AttachmentPreview
          v-for="(attachment, index) in getAttachments(comment)"
          :key="typeof attachment === 'number' ? attachment : attachment.id || index"
          :attachment-id="typeof attachment === 'number' ? attachment : attachment.id"
          :attachment="typeof attachment === 'number' ? undefined : attachment"
        />
      </div>
    </div>
  </bx-tile>
</template>

<style scoped>
.comment-item {
  padding: 0.5rem;
}

.comment-header {
  display: flex;
  justify-content: space-between;
  margin-bottom: 0.5rem;
  font-size: 0.875rem;
}

.comment-author {
  font-weight: 600;
  display: inline-flex;
  align-items: center;
  gap: 0.25rem;
}

.comment-author-icon {
  display: inline-flex;
  align-items: center;
}

.comment-author-icon i {
  font-size: 1rem;
}

.comment-date {
  color: var(--cds-text-secondary);
}

.comment-body {
  margin-bottom: 0.5rem;
  white-space: pre-wrap;
}

.comment-attachments {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem;
  margin-top: 0.5rem;
}

@media (max-width: 768px) {
  .comment-header {
    flex-direction: column;
    align-items: flex-start;
    gap: 0.25rem;
  }

  .comment-author-name {
    word-break: break-word;
  }
}
</style>
