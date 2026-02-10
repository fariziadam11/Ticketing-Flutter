<script setup lang="ts">
import { ref, watch } from 'vue'
import { useRouter } from 'vue-router'
import TicketTable from '@/components/tickets/TicketTable.vue'
import { useTickets } from '@/composables/useTickets'

const router = useRouter()
const searchQuery = ref('')
const currentPage = ref(1)
const pageLimit = ref(2) // Set to 2 for testing

const {
  tickets,
  pagination,
  isLoading,
  error,
  goToPage,
  setLimit,
} = useTickets(currentPage, pageLimit)

// Reset to page 1 when search query changes
watch(searchQuery, () => {
  if (currentPage.value !== 1) {
    currentPage.value = 1
  }
})
</script>

<template>
  <div class="tickets-list-page">
    <div class="page-header">
      <h1>Tickets</h1>
      <bx-btn id="ticketsListCreateBtn" @click="router.push('/tickets/create')">
        Create New Ticket
      </bx-btn>
    </div>

    <div class="page-content">
      <div class="search-section">
        <bx-search
          id="ticketsListSearch"
          :value="searchQuery"
          placeholder="Search tickets by title, ID, or status..."
          @bx-search-input="(e: any) => (searchQuery = e.target.value)"
        />
      </div>

      <div v-if="isLoading" class="loading-container">
        <bx-loading id="ticketsListLoading" :active="isLoading" />
      </div>

      <div v-else-if="error" class="error-container">
        <p>Error loading tickets: {{ error.message }}</p>
      </div>

      <TicketTable
        v-else-if="tickets"
        :tickets="tickets"
        :loading="isLoading"
        :search-query="searchQuery"
        :pagination="pagination"
        :current-page="currentPage"
        :page-limit="pageLimit"
        @page-change="goToPage"
        @limit-change="setLimit"
      />
    </div>
  </div>
</template>

<style scoped>
.tickets-list-page {
  padding: 2rem;
  max-width: 1400px;
  margin: 0 auto;
}

.page-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 2rem;
}

.page-header h1 {
  margin: 0;
  font-size: 2rem;
  font-weight: 600;
}

.page-content {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.search-section {
  margin-bottom: 1rem;
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

@media (max-width: 768px) {
  .tickets-list-page {
    padding: 1rem;
  }

  .page-header {
    flex-direction: column;
    align-items: flex-start;
    gap: 1rem;
  }

  .page-header h1 {
    font-size: 1.5rem;
  }

  .page-header ::deep bx-btn {
    width: 100%;
  }
}
</style>
