<script setup lang="ts">
import { ref, computed } from 'vue'

interface Props {
  open: boolean
  mode: 'accept' | 'reject'
  loading?: boolean
}

interface Emits {
  (e: 'close'): void
  (e: 'submit', payload: { rating?: number; comment?: string }): void
}

const props = withDefaults(defineProps<Props>(), {
  loading: false,
})

const emit = defineEmits<Emits>()

const solutionRating = ref(5)
const solutionComment = ref('')
const solutionCommentError = ref('')

const isCommentRequired = computed(() => {
  return props.mode === 'accept' && solutionRating.value < 4
})

const isCommentValid = computed(() => {
  if (props.mode === 'reject') {
    return solutionComment.value.trim().length > 0
  }
  // For accept mode: comment required only if rating < 4
  if (isCommentRequired.value) {
    return solutionComment.value.trim().length > 0
  }
  return true
})

const handleClose = () => {
  solutionComment.value = ''
  solutionCommentError.value = ''
  emit('close')
}

const handleSubmit = () => {
  solutionCommentError.value = ''

  // For reject mode, comment is always required
  if (props.mode === 'reject' && !solutionComment.value.trim()) {
    solutionCommentError.value = 'Comment is required'
    return
  }

  // For accept mode, comment required only if rating < 4
  if (props.mode === 'accept' && isCommentRequired.value && !solutionComment.value.trim()) {
    solutionCommentError.value = 'Comment is required when rating is less than 4'
    return
  }

  const payload: { rating?: number; comment?: string } = {}

  if (props.mode === 'accept') {
    payload.rating = solutionRating.value
    // Only include comment if provided (required when rating < 4)
    if (solutionComment.value.trim()) {
      payload.comment = solutionComment.value.trim()
    }
  } else {
    // Reject mode always requires comment
    payload.comment = solutionComment.value.trim()
  }

  emit('submit', payload)
  solutionComment.value = ''
  solutionCommentError.value = ''
}

const handleCommentInput = () => {
  if (solutionCommentError.value) {
    solutionCommentError.value = ''
  }
}
</script>

<template>
  <bx-modal
    id="ticketSolutionModal"
    :open="open"
    size="sm"
    @bx-modal-closed="handleClose"
  >
    <bx-modal-header>
      <bx-modal-close-button
        id="ticketSolutionModalCloseBtn"
        @click="handleClose"
      ></bx-modal-close-button>
      <bx-modal-heading>
        {{ mode === 'accept' ? 'Accept Solution' : 'Reject Solution' }}
      </bx-modal-heading>
      <p class="ticket-solution-description">
        {{
          mode === 'accept'
            ? 'Please rate the solution. Comment is required if rating is less than 4.'
            : 'Please provide a comment for rejecting this solution.'
        }}
      </p>
    </bx-modal-header>
    <bx-modal-body>
      <div class="solution-form">
        <div
          v-if="mode === 'accept'"
          class="solution-field solution-rating-field"
        >
          <label for="solutionRating" class="solution-label">
            Rating
          </label>
          <bx-select
            id="solutionRating"
            :value="String(solutionRating)"
            @bx-select-selected="
              (event: CustomEvent) => {
                solutionRating = Number(event.detail.value)
              }
            "
          >
            <bx-select-item value="1" label="1" />
            <bx-select-item value="2" label="2" />
            <bx-select-item value="3" label="3" />
            <bx-select-item value="4" label="4" />
            <bx-select-item value="5" label="5" />
          </bx-select>
        </div>

        <div class="solution-field">
          <label for="solutionComment" class="solution-label">
            Comment
            <span v-if="mode === 'reject' || isCommentRequired" class="required-indicator">*</span>
          </label>
          <bx-textarea
            id="solutionComment"
            v-model="solutionComment"
            placeholder="Write your comment..."
            rows="4"
            :invalid="!!solutionCommentError"
            :invalid-text="solutionCommentError"
            @input="handleCommentInput"
          />
        </div>
      </div>
    </bx-modal-body>
    <bx-modal-footer>
      <bx-btn
        id="ticketSolutionModalCancelBtn"
        kind="secondary"
        type="button"
        size="sm"
        :disabled="loading"
        @click="handleClose"
      >
        Cancel
      </bx-btn>
      <bx-btn
        id="ticketSolutionModalSubmitBtn"
        kind="primary"
        type="button"
        size="sm"
        :disabled="loading || !isCommentValid"
        @click="handleSubmit"
      >
        {{ mode === 'accept' ? 'Accept' : 'Reject' }}
      </bx-btn>
    </bx-modal-footer>
  </bx-modal>
</template>

<style scoped>
.solution-form {
  display: flex;
  flex-direction: column;
  gap: 1rem;
  margin-top: 1rem;
}

.solution-field {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
}

.solution-label {
  font-size: 0.875rem;
  font-weight: 500;
  color: var(--cds-text-primary);
  margin-bottom: 0.5rem;
  display: block;
}

.required-indicator {
  color: var(--cds-support-error, #da1e28);
}

.ticket-solution-description {
  margin-top: 0.5rem;
  color: var(--cds-text-secondary, #525252);
  font-size: 0.875rem;
}
</style>

