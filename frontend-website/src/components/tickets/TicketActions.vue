<script setup lang="ts">
import type { Ticket } from '@/api/types'

interface Props {
  ticket: Ticket
  isUpdatePending?: boolean
}

interface Emits {
  (e: 'update'): void
  (e: 'accept-solution'): void
  (e: 'reject-solution'): void
}

defineProps<Props>()
const emit = defineEmits<Emits>()
</script>

<template>
  <div class="ticket-header-actions">
    <div class="ticket-header-actions-right">
      <bx-btn
        id="ticketDetailUpdateBtn"
        kind="secondary"
        size="sm"
        :disabled="isUpdatePending"
        @click="emit('update')"
      >
        Update Ticket
      </bx-btn>
      <bx-btn
        v-if="ticket.status === 'Resolved'"
        id="ticketDetailAcceptSolutionBtn"
        kind="primary"
        size="sm"
        @click="emit('accept-solution')"
      >
        Accept Solution
      </bx-btn>
      <bx-btn
        v-if="ticket.status === 'Resolved'"
        id="ticketDetailRejectSolutionBtn"
        kind="ghost"
        size="sm"
        @click="emit('reject-solution')"
      >
        Reject Solution
      </bx-btn>
    </div>
  </div>
</template>

<style scoped>
.ticket-header-actions {
  display: flex;
  justify-content: flex-end;
  margin-top: 1.5rem;
  margin-bottom: 0.5rem;
}

.ticket-header-actions-right {
  display: flex;
  gap: 0.5rem;
}
</style>

