<script setup lang="ts">
import { ref, computed } from 'vue'
import CommentItem from './CommentItem.vue'
import FileUpload from '@/components/shared/FileUpload.vue'
import type { Comment } from '@/api/types'
import { useCreateComment } from '@/composables/useComments'

interface Props {
  comments: Comment[]
  ticketId: number
  loading?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  loading: false,
})

const visibleComments = computed(() => {
  return props.comments.filter((comment) => {
    return comment.customer_visible !== false
  })
})

const solutionComments = computed(() => {
  return visibleComments.value.filter((comment) => comment.is_solution === true)
})

const regularComments = computed(() => {
  return visibleComments.value.filter((comment) => comment.is_solution !== true)
})

const showModal = ref(false)
const message = ref('')
const files = ref<File[]>([])

const { mutate: createComment, isPending } = useCreateComment(props.ticketId)

const handleSubmit = () => {
  if (!message.value.trim()) return

  createComment(
    {
      message: message.value,
      attachments: files.value.length > 0 ? files.value : undefined,
    },
    {
      onSuccess: () => {
        message.value = ''
        files.value = []
        showModal.value = false
      },
    }
  )
}

const handleModalClose = () => {
  showModal.value = false
}
</script>

<template>
  <div class="comment-list">
    <div class="comment-list-header">
      <h3>
        Comments ({{ visibleComments.length }})
        <span v-if="solutionComments.length" class="solution-count">
          • Solution {{ solutionComments.length }}
        </span>
      </h3>
      <bx-btn id="commentListAddBtn" @click="showModal = true">Add Comment</bx-btn>
    </div>

    <div v-if="loading" class="loading">Loading comments...</div>
    <div v-else-if="visibleComments.length === 0" class="empty">
      No comments yet. Be the first to comment!
    </div>
    <div v-else>
      <div
        v-if="solutionComments.length > 0"
        class="comments solution-comments"
      >
        <h4 class="section-title">Solution</h4>
        <CommentItem
          v-for="comment in solutionComments"
          :key="comment.id"
          :comment="comment"
        />
      </div>

      <div
        v-if="regularComments.length > 0"
        class="comments regular-comments"
      >
        <h4 class="section-title">
          {{ solutionComments.length ? 'Other comments' : 'Comments' }}
        </h4>
        <CommentItem
          v-for="comment in regularComments"
          :key="comment.id"
          :comment="comment"
        />
      </div>
    </div>

    <bx-modal
      id="commentListModal"
      :open="showModal"
      @bx-modal-closed="handleModalClose"
    >
      <bx-modal-header>
        <bx-modal-close-button
          id="commentListModalCloseBtn"
          @click="handleModalClose"
        ></bx-modal-close-button>
        <bx-modal-heading>Add Comment</bx-modal-heading>
      </bx-modal-header>
      <bx-modal-body>
        <div class="bx--form-item">
          <bx-textarea
            id="commentListModalTextarea"
            v-model="message"
            label-text="Message"
            placeholder="Enter your comment..."
            :rows="5"
          />
        </div>
        <div class="bx--form-item">
          <label class="bx--label" for="commentListModalFileInput">
            Attachments <span class="optional-text">(optional)</span>
          </label>
          <FileUpload
            id="commentListModalFileInput"
            v-model:files="files"
            :disabled="isPending"
          />
        </div>
      </bx-modal-body>
      <bx-modal-footer>
        <bx-btn
          id="commentListModalCancelBtn"
          kind="secondary"
          type="button"
          @click="handleModalClose"
        >
          Cancel
        </bx-btn>
        <bx-btn
          id="commentListModalSubmitBtn"
          type="button"
          :disabled="!message.trim() || isPending"
          @click="handleSubmit"
        >
          {{ isPending ? 'Submitting...' : 'Submit' }}
        </bx-btn>
      </bx-modal-footer>
    </bx-modal>
  </div>
</template>

<style scoped>
.comment-list {
  margin-top: 2rem;
}

.comment-list-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1rem;
}

.comments {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.solution-comments {
  margin-bottom: 1.5rem;
}

.section-title {
  margin: 0 0 0.5rem;
  font-size: 0.9rem;
  font-weight: 600;
}

.solution-count {
  font-size: 0.8rem;
  font-weight: 400;
  color: var(--cds-text-secondary);
  margin-left: 0.25rem;
}

.loading,
.empty {
  padding: 2rem;
  text-align: center;
  color: var(--cds-text-secondary);
}

.bx--form-item {
  margin-bottom: 1rem;
}

.bx--label {
  font-size: 0.875rem;
  font-weight: 500;
  color: var(--cds-text-primary);
  margin-bottom: 0.375rem;
}

.optional-text {
  color: var(--cds-text-secondary);
  font-weight: 400;
  font-size: 0.8125rem;
}

::deep bx-modal-footer {
  display: flex;
  gap: 0.5rem;
  justify-content: flex-end;
}

@media (max-width: 768px) {
  .comment-list-header {
    flex-direction: column;
    align-items: flex-start;
    gap: 1rem;
  }

  .comment-list-header ::deep bx-btn {
    width: 100%;
  }

  ::deep bx-modal {
    max-width: 95vw;
  }

  ::deep bx-modal-footer {
    flex-direction: column-reverse;
  }

  ::deep bx-modal-footer bx-btn {
    width: 100%;
  }
}
</style>
