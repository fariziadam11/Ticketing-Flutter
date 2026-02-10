<script setup lang="ts">
import { ref, watch } from 'vue'
import type { Ticket, Category } from '@/api/types'

interface Props {
  open: boolean
  ticket: Ticket | null
  categories?: Category[]
  types?: Array<{ id: number; name: string }>
  priorities?: Array<{ id: number; name: string }>
  loading?: boolean
}

interface Emits {
  (e: 'close'): void
  (e: 'submit', payload: Record<string, any>): void
}

const props = withDefaults(defineProps<Props>(), {
  loading: false,
})

const emit = defineEmits<Emits>()

const updateTitle = ref('')
const updateDescription = ref('')
const updateCategoryId = ref('')
const updateTypeId = ref('')
const updatePriorityId = ref('')

watch(
  () => props.open,
  (isOpen) => {
    if (isOpen && props.ticket) {
      updateTitle.value = props.ticket.title || ''
      updateDescription.value = props.ticket.description || ''
      updateCategoryId.value = props.ticket.category_id?.toString() || ''
      updateTypeId.value = props.ticket.type_id?.toString() || ''
      updatePriorityId.value = props.ticket.priority_id?.toString() || ''
    }
  },
  { immediate: true },
)

const handleClose = () => {
  emit('close')
}

const handleSubmit = () => {
  if (!props.ticket) return

  const payload: Record<string, any> = {}

  if (updateTitle.value.trim() !== props.ticket.title) {
    payload.title = updateTitle.value.trim()
  }
  if (updateDescription.value.trim() !== props.ticket.description) {
    payload.description = updateDescription.value.trim()
  }
  if (
    updateCategoryId.value &&
    parseInt(updateCategoryId.value, 10) !== props.ticket.category_id
  ) {
    payload.category_id = parseInt(updateCategoryId.value, 10)
  }
  if (
    updateTypeId.value &&
    parseInt(updateTypeId.value, 10) !== props.ticket.type_id
  ) {
    payload.type_id = parseInt(updateTypeId.value, 10)
  }
  if (
    updatePriorityId.value &&
    parseInt(updatePriorityId.value, 10) !== props.ticket.priority_id
  ) {
    payload.priority_id = parseInt(updatePriorityId.value, 10)
  }

  if (Object.keys(payload).length === 0) {
    return
  }

  emit('submit', payload)
}
</script>

<template>
  <bx-modal
    id="ticketUpdateModal"
    :open="open"
    size="md"
    @bx-modal-closed="handleClose"
  >
    <bx-modal-header>
      <bx-modal-close-button
        id="ticketUpdateModalCloseBtn"
        @click="handleClose"
      ></bx-modal-close-button>
      <bx-modal-heading>Update Ticket</bx-modal-heading>
      <p class="ticket-update-description">
        Update ticket information. Only changed fields will be updated.
      </p>
    </bx-modal-header>
    <bx-modal-body>
      <div class="update-form">
        <div class="bx--form-item">
          <bx-text-input
            id="updateTicketTitle"
            v-model="updateTitle"
            label-text="Title *"
            placeholder="Enter ticket title"
            :disabled="loading"
            :required="true"
          />
        </div>

        <div class="bx--form-item">
          <bx-textarea
            id="updateTicketDescription"
            v-model="updateDescription"
            label-text="Description *"
            placeholder="Enter ticket description"
            :rows="6"
            :required="true"
            :disabled="loading"
          />
        </div>

        <div class="bx--form-item">
          <bx-select
            id="updateTicketCategory"
            v-model="updateCategoryId"
            label-text="Category *"
            :disabled="loading"
          >
            <bx-select-item value="" label="Select category" />
            <bx-select-item
              v-for="category in categories"
              :key="category.id"
              :value="String(category.id)"
              :label="category.name"
            />
          </bx-select>
        </div>

        <div class="bx--form-item">
          <bx-select
            id="updateTicketType"
            v-model="updateTypeId"
            label-text="Type *"
            :disabled="loading"
          >
            <bx-select-item value="" label="Select type" />
            <bx-select-item
              v-for="type in types"
              :key="type.id"
              :value="String(type.id)"
              :label="type.name"
            />
          </bx-select>
        </div>

        <div class="bx--form-item">
          <bx-select
            id="updateTicketPriority"
            v-model="updatePriorityId"
            label-text="Priority *"
            :disabled="loading"
          >
            <bx-select-item value="" label="Select priority" />
            <bx-select-item
              v-for="priority in priorities"
              :key="priority.id"
              :value="String(priority.id)"
              :label="priority.name"
            />
          </bx-select>
        </div>
      </div>
    </bx-modal-body>
    <bx-modal-footer>
      <bx-btn
        id="ticketUpdateModalCancelBtn"
        kind="secondary"
        type="button"
        size="sm"
        :disabled="loading"
        @click="handleClose"
      >
        Cancel
      </bx-btn>
      <bx-btn
        id="ticketUpdateModalSubmitBtn"
        kind="primary"
        type="button"
        size="sm"
        :disabled="loading"
        @click="handleSubmit"
      >
        Update
      </bx-btn>
    </bx-modal-footer>
  </bx-modal>
</template>

<style scoped>
.ticket-update-description {
  margin-top: 0.5rem;
  color: var(--cds-text-secondary, #525252);
  font-size: 0.875rem;
}

.update-form {
  display: flex;
  flex-direction: column;
  gap: 1rem;
  margin-top: 1rem;
}
</style>

