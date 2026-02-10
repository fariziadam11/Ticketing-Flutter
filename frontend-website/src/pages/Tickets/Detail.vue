<script setup lang="ts">
import { computed, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import TicketDetailCard from '@/components/tickets/TicketDetailCard.vue'
import TicketActions from '@/components/tickets/TicketActions.vue'
import CommentList from '@/components/comments/CommentList.vue'
import AttachmentPreview from '@/components/attachments/AttachmentPreview.vue'
import SolutionModal from '@/components/tickets/SolutionModal.vue'
import UpdateTicketModal from '@/components/tickets/UpdateTicketModal.vue'
import { useTicketDetail } from '@/composables/useTicketDetail'
import { useComments } from '@/composables/useComments'
import { useTicketSolution } from '@/composables/useTicketSolution'
import { useUpdateTicket } from '@/composables/useUpdateTicket'
import { useCategories } from '@/composables/useCategories'
import { useTicketMeta } from '@/composables/useTicketMeta'
import type { Attachment } from '@/api/types'

interface Props {
  id: string
}

const props = defineProps<Props>()
const route = useRoute()
const router = useRouter()

const ticketId = computed(() => parseInt(props.id || String(route.params.id), 10))

const { data: ticket, isLoading: ticketLoading, error: ticketError } =
  useTicketDetail(ticketId.value)
const { data: comments, isLoading: commentsLoading } = useComments(ticketId.value)

const { acceptMutation, rejectMutation } = useTicketSolution(ticketId.value)
const { mutate: updateTicket, isPending: isUpdatePending } = useUpdateTicket(ticketId.value)

const { data: categories } = useCategories()
const { data: ticketMeta } = useTicketMeta()

const showSolutionModal = ref(false)
const showUpdateModal = ref(false)
const solutionMode = ref<'accept' | 'reject'>('accept')

const isSolutionLoading = computed(
  () => acceptMutation.isPending.value || rejectMutation.isPending.value,
)

const openAcceptSolution = () => {
  solutionMode.value = 'accept'
  showSolutionModal.value = true
}

const openRejectSolution = () => {
  solutionMode.value = 'reject'
  showSolutionModal.value = true
}

const handleSolutionSubmit = async (payload: { rating?: number; comment?: string }) => {
  try {
    if (solutionMode.value === 'accept') {
      await acceptMutation.mutateAsync({
        rating: payload.rating || 5,
        ...(payload.comment && { comment: payload.comment }),
      })
    } else {
      if (!payload.comment) {
        throw new Error('Comment is required for rejecting solution')
      }
      await rejectMutation.mutateAsync({
        comment: payload.comment,
      })
    }
    showSolutionModal.value = false
  } catch (error) {
    // Error handled by mutation
  }
}

const openUpdateModal = () => {
  showUpdateModal.value = true
}

const handleUpdateSubmit = (payload: Record<string, any>) => {
  updateTicket(payload, {
    onSuccess: () => {
      showUpdateModal.value = false
    },
  })
}

const getAttachments = (): Array<number | Attachment> => {
  if (!ticket.value?.attachments) return []
  if (!Array.isArray(ticket.value.attachments)) return []

  return ticket.value.attachments.map((item) => {
    if (typeof item === 'number') {
      return item
    }
    return item as Attachment
  })
}
</script>

<template>
  <div class="ticket-detail-page">
    <bx-breadcrumb id="ticketDetailBreadcrumb">
      <bx-breadcrumb-item @click="router.push('/tickets')">
        Tickets
      </bx-breadcrumb-item>
      <bx-breadcrumb-item>
        {{ ticket?.pretty_id || `#${ticketId}` }}
      </bx-breadcrumb-item>
    </bx-breadcrumb>

    <div v-if="ticketLoading" class="loading-container">
      <bx-loading id="ticketDetailLoading" :active="ticketLoading" />
    </div>

    <div v-else-if="ticketError" class="error-container">
      <p>Error loading ticket: {{ ticketError.message }}</p>
      <bx-btn id="ticketDetailBackBtn" @click="router.push('/tickets')">
        Back to Tickets
      </bx-btn>
    </div>

    <div v-else-if="ticket" class="ticket-content">
      <TicketActions
        :ticket="ticket"
        :is-update-pending="isUpdatePending"
        @update="openUpdateModal"
        @accept-solution="openAcceptSolution"
        @reject-solution="openRejectSolution"
      />

      <div class="bx--grid">
        <div class="bx--row">
          <div class="bx--col-lg-8 bx--col-md-8 bx--col-sm-4">
            <TicketDetailCard :ticket="ticket" />
          </div>
          <div v-if="getAttachments().length > 0" class="bx--col-lg-4 bx--col-md-8 bx--col-sm-4">
            <div class="attachments-section">
              <h3>Attachments</h3>
              <div class="attachments-list">
                <AttachmentPreview
                  v-for="(attachment, index) in getAttachments()"
                  :key="typeof attachment === 'number' ? attachment : attachment.id || index"
                  :attachment-id="typeof attachment === 'number' ? attachment : attachment.id"
                  :attachment="typeof attachment === 'number' ? undefined : attachment"
                />
              </div>
            </div>
          </div>
        </div>
        <div class="bx--row">
          <div class="bx--col-lg-12 bx--col-md-8 bx--col-sm-4">
            <CommentList
              :comments="comments || []"
              :ticket-id="ticketId"
              :loading="commentsLoading"
            />
          </div>
        </div>
      </div>
    </div>

    <SolutionModal
      :open="showSolutionModal"
      :mode="solutionMode"
      :loading="isSolutionLoading"
      @close="showSolutionModal = false"
      @submit="handleSolutionSubmit"
    />

    <UpdateTicketModal
      :open="showUpdateModal"
      :ticket="ticket || null"
      :categories="categories"
      :types="ticketMeta?.types"
      :priorities="ticketMeta?.priorities"
      :loading="isUpdatePending"
      @close="showUpdateModal = false"
      @submit="handleUpdateSubmit"
    />
  </div>
</template>

<style scoped>
.ticket-detail-page {
  padding: 2rem;
  max-width: 1400px;
  margin: 0 auto;
}

.loading-container,
.error-container {
  padding: 2rem;
  text-align: center;
  display: flex;
  align-items: center;
  justify-content: center;
}

.loading-container ::deep bx-loading {
  --cds-loader-size: 1.25rem;
  width: 1.25rem;
  height: 1.25rem;
  display: inline-block;
}

.loading-container ::deep bx-loading svg {
  width: 1.25rem;
  height: 1.25rem;
}

.error-container {
  color: var(--cds-support-error);
}

.ticket-content {
  margin-top: 2rem;
}

.attachments-section {
  margin-top: 1rem;
}

.attachments-section h3 {
  margin-bottom: 1rem;
}

.attachments-list {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

@media (max-width: 768px) {
  .ticket-detail-page {
    padding: 1rem;
  }
}
</style>
