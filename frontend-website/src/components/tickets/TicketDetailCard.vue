<script setup lang="ts">
import type { Ticket } from '@/api/types'
import { formatUnixTimestamp } from '@/utils/date'

interface Props {
  ticket: Ticket
}

defineProps<Props>()

const getStatusType = (status: string) => {
  const statusLower = status?.toLowerCase() || ''
  if (statusLower.includes('pending')) return 'blue'
  if (statusLower.includes('solved') || statusLower.includes('closed'))
    return 'green'
  if (statusLower.includes('in progress')) return 'purple'
  return 'gray'
}
</script>

<template>
  <bx-tile id="ticketDetailCardTile">
    <h3>Ticket Details</h3>
    <bx-structured-list id="ticketDetailCardStructuredList">
      <bx-structured-list-head>
        <bx-structured-list-header-row>
          <bx-structured-list-header-cell>Field</bx-structured-list-header-cell>
          <bx-structured-list-header-cell>Value</bx-structured-list-header-cell>
        </bx-structured-list-header-row>
      </bx-structured-list-head>
      <bx-structured-list-body>
        <bx-structured-list-row>
          <bx-structured-list-cell>Ticket ID</bx-structured-list-cell>
          <bx-structured-list-cell>
            {{ ticket.pretty_id || `#${ticket.id}` }}
          </bx-structured-list-cell>
        </bx-structured-list-row>
        <bx-structured-list-row>
          <bx-structured-list-cell>Title</bx-structured-list-cell>
          <bx-structured-list-cell>{{ ticket.title }}</bx-structured-list-cell>
        </bx-structured-list-row>
        <bx-structured-list-row>
          <bx-structured-list-cell>Status</bx-structured-list-cell>
          <bx-structured-list-cell>
            <bx-tag id="ticketDetailCardStatusTag" :type="getStatusType(ticket.status)">
              {{ ticket.status }}
            </bx-tag>
          </bx-structured-list-cell>
        </bx-structured-list-row>
        <bx-structured-list-row>
          <bx-structured-list-cell>Description</bx-structured-list-cell>
          <bx-structured-list-cell>
            {{ ticket.description || 'N/A' }}
          </bx-structured-list-cell>
        </bx-structured-list-row>
        <bx-structured-list-row>
          <bx-structured-list-cell>Created At</bx-structured-list-cell>
          <bx-structured-list-cell>
            {{ formatUnixTimestamp(ticket.created_at) }}
          </bx-structured-list-cell>
        </bx-structured-list-row>
        <bx-structured-list-row v-if="ticket.last_update">
          <bx-structured-list-cell>Last Update</bx-structured-list-cell>
          <bx-structured-list-cell>
            {{ formatUnixTimestamp(ticket.last_update) }}
          </bx-structured-list-cell>
        </bx-structured-list-row>
        <bx-structured-list-row v-if="ticket.closed_at">
          <bx-structured-list-cell>Closed At</bx-structured-list-cell>
          <bx-structured-list-cell>
            {{ formatUnixTimestamp(ticket.closed_at) }}
          </bx-structured-list-cell>
        </bx-structured-list-row>
      </bx-structured-list-body>
    </bx-structured-list>
  </bx-tile>
</template>

<style scoped>
@media (max-width: 768px) {
  ::deep bx-structured-list {
    font-size: 0.875rem;
  }

  ::deep bx-structured-list-header-cell,
  ::deep bx-structured-list-cell {
    padding: 0.75rem 0.5rem;
  }
}
</style>