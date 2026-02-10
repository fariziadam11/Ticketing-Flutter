<script setup lang="ts">
import { ref, computed } from 'vue'
import { useRouter } from 'vue-router'
import { useCreateTicket } from '@/composables/useCreateTicket'
import { useCategories } from '@/composables/useCategories'
import { useTicketMeta } from '@/composables/useTicketMeta'
import { useFormValidation } from '@/composables/useFormValidation'
import FileUpload from '@/components/shared/FileUpload.vue'
import { TICKET_DEFAULTS } from '@/utils/constants'

const router = useRouter()

const title = ref('')
const description = ref('')
const categoryId = ref<string>('')
const typeId = ref<string>('')
const priorityId = ref<string>('')
const dateOccurred = ref<string>('')
const files = ref<File[]>([])

const now = new Date()
const yyyy = now.getFullYear()
const mm = String(now.getMonth() + 1).padStart(2, '0')
const dd = String(now.getDate()).padStart(2, '0')
const today = `${yyyy}-${mm}-${dd}`

if (today) {
  dateOccurred.value = today
}

const { data: categories, isLoading: categoriesLoading } = useCategories()
const { data: ticketMeta, isLoading: metaLoading } = useTicketMeta()
const { mutate: createTicket, isPending, error } = useCreateTicket()

const categoryOptions = computed(() => categories.value || [])
const typeOptions = computed(() => ticketMeta.value?.types || [])
const priorityOptions = computed(() => ticketMeta.value?.priorities || [])

const validation = useFormValidation({
  fields: {
    title: { value: title, required: true },
    description: { value: description, required: true },
    categoryId: { value: categoryId, required: true },
    typeId: { value: typeId, required: true },
    priorityId: { value: priorityId, required: true },
    dateOccurred: { value: dateOccurred, required: true },
  },
})

const handleSubmit = () => {
  validation.markAllTouched()

  if (!validation.isFormValid.value) {
    return
  }

  const dateTimestamp = dateOccurred.value
    ? Math.floor(new Date(dateOccurred.value).getTime() / 1000)
    : Math.floor(Date.now() / 1000)

  createTicket({
    source_id: TICKET_DEFAULTS.SOURCE_ID,
    category_id: parseInt(categoryId.value, 10),
    type_id: parseInt(typeId.value, 10),
    priority_id: parseInt(priorityId.value, 10),
    title: title.value,
    description: description.value,
    date_ocurred: dateTimestamp,
    attachments: files.value.length > 0 ? files.value : undefined,
  })
}
</script>

<template>
  <div class="create-ticket-page">
    <bx-breadcrumb id="createTicketBreadcrumb">
      <bx-breadcrumb-item @click="router.push('/tickets')">
        Tickets
      </bx-breadcrumb-item>
      <bx-breadcrumb-item>Create Ticket</bx-breadcrumb-item>
    </bx-breadcrumb>

    <div class="page-header">
      <h1>Create New Ticket</h1>
    </div>

    <form @submit.prevent="handleSubmit" class="bx--form">
      <div class="bx--form-item">
        <bx-input
          id="createTicketTitleInput"
          v-model="title"
          label-text="Title *"
          placeholder="Enter ticket title"
          :required="true"
          :disabled="isPending"
          :invalid="validation.isFieldInvalid('title')"
          :invalid-text="validation.getFieldError('title')"
          @blur="validation.markFieldTouched('title')"
        />
      </div>

      <div class="bx--form-item">
        <bx-textarea
          id="createTicketDescriptionTextarea"
          v-model="description"
          label-text="Description *"
          placeholder="Enter ticket description"
          :rows="6"
          :required="true"
          :disabled="isPending"
          :invalid="validation.isFieldInvalid('description')"
          :invalid-text="validation.getFieldError('description')"
          @blur="validation.markFieldTouched('description')"
        />
      </div>

      <div class="bx--form-item">
        <bx-select
          id="createTicketCategorySelect"
          v-model="categoryId"
          label-text="Category *"
          placeholder="Select a category"
          :disabled="categoriesLoading || isPending"
          :required="true"
          :invalid="validation.isFieldInvalid('categoryId')"
          :invalid-text="validation.getFieldError('categoryId')"
          @blur="validation.markFieldTouched('categoryId')"
        >
          <bx-select-item value="" disabled hidden>Select a category</bx-select-item>
          <bx-select-item
            v-for="category in categoryOptions"
            :key="category.id"
            :value="String(category.id)"
          >
            {{ category.name }}
          </bx-select-item>
        </bx-select>
        <bx-loading
          id="createTicketCategoriesLoading"
          v-if="categoriesLoading"
          :active="true"
        />
      </div>

      <div class="bx--form-item">
        <bx-select
          id="createTicketTypeSelect"
          v-model="typeId"
          label-text="Type *"
          placeholder="Select a type"
          :disabled="metaLoading || isPending"
          :required="true"
          :invalid="validation.isFieldInvalid('typeId')"
          :invalid-text="validation.getFieldError('typeId')"
          @blur="validation.markFieldTouched('typeId')"
        >
          <bx-select-item value="" disabled hidden>Select a type</bx-select-item>
          <bx-select-item v-for="type in typeOptions" :key="type.id" :value="String(type.id)">
            {{ type.name }}
          </bx-select-item>
        </bx-select>
        <bx-loading id="createTicketTypeLoading" v-if="metaLoading" :active="true" />
      </div>

      <div class="bx--form-item">
        <bx-select
          id="createTicketPrioritySelect"
          v-model="priorityId"
          label-text="Priority *"
          placeholder="Select a priority"
          :disabled="metaLoading || isPending"
          :required="true"
          :invalid="validation.isFieldInvalid('priorityId')"
          :invalid-text="validation.getFieldError('priorityId')"
          @blur="validation.markFieldTouched('priorityId')"
        >
          <bx-select-item value="" disabled hidden>Select a priority</bx-select-item>
          <bx-select-item
            v-for="priority in priorityOptions"
            :key="priority.id"
            :value="String(priority.id)"
          >
            {{ priority.name }}
          </bx-select-item>
        </bx-select>
        <bx-loading id="createTicketPriorityLoading" v-if="metaLoading" :active="true" />
      </div>

      <div class="bx--form-item">
        <label class="bx--label" for="createTicketDateOccurred">
          Date Occurred <span class="required">*</span>
        </label>
        <div class="bx--date-input-wrapper">
          <input
            id="createTicketDateOccurred"
            v-model="dateOccurred"
            type="date"
            class="bx--date-input"
            :class="{ 'bx--date-input--invalid': validation.isFieldInvalid('dateOccurred') }"
            :required="true"
            :disabled="isPending"
            :max="today"
            @blur="validation.markFieldTouched('dateOccurred')"
          />
        </div>
        <div v-if="validation.isFieldInvalid('dateOccurred')" class="bx--form-requirement">
          {{ validation.getFieldError('dateOccurred') }}
        </div>
        <small v-else class="helper-text">
          Select the date when the incident occurred
        </small>
      </div>

      <div class="bx--form-item">
        <label class="bx--label" for="createTicketFileInput">
          Attachments <span class="optional-text">(optional)</span>
        </label>
        <FileUpload v-model:files="files" :disabled="isPending" />
      </div>

      <div v-if="error" class="error-message">
        Error: {{ error.message }}
      </div>

      <div class="form-actions">
        <button
          id="createTicketCancelBtn"
          type="button"
          class="btn btn-secondary"
          @click="router.push('/tickets')"
        >
          Cancel
        </button>
        <button
          id="createTicketSubmitBtn"
          type="submit"
          class="btn btn-primary"
          :disabled="!validation.isFormValid || isPending"
        >
          {{ isPending ? 'Creating...' : 'Create Ticket' }}
        </button>
      </div>
    </form>
  </div>
</template>

<style scoped>
.create-ticket-page {
  padding: 2rem;
  max-width: 800px;
  margin: 0 auto;
}

.page-header {
  margin: 2rem 0;
}

.page-header h1 {
  margin: 0;
  font-size: 2rem;
  font-weight: 600;
}

.bx--form {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
}

.bx--form-item {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.bx--form-item ::deep bx-loading {
  --cds-loader-size: 1rem;
  width: 1rem;
  height: 1rem;
  margin-top: 0.5rem;
  display: inline-block;
}

.bx--form-item ::deep bx-loading svg {
  width: 1rem;
  height: 1rem;
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

.required {
  color: var(--cds-support-error);
}

.helper-text {
  font-size: 0.8125rem;
  color: var(--cds-text-secondary);
  margin-top: 0.25rem;
}

.bx--date-input-wrapper {
  position: relative;
  width: 100%;
}

.bx--date-input {
  width: 100%;
  padding: 0.875rem 1rem;
  font-size: 0.9375rem;
  background-color: var(--cds-field-01);
  border: 1px solid var(--cds-border-subtle);
  border-radius: 4px;
  color: var(--cds-text-primary);
  transition: all 0.15s ease;
  font-family: inherit;
  line-height: 1.5;
  min-height: 2.5rem;
}

.bx--date-input:focus {
  outline: 2px solid var(--cds-focus);
  outline-offset: -2px;
  border-color: var(--cds-focus);
  background-color: var(--cds-field-01);
}

.bx--date-input:disabled {
  background-color: var(--cds-field-disabled);
  color: var(--cds-text-disabled);
  cursor: not-allowed;
  opacity: 0.6;
  border-color: var(--cds-border-disabled);
}

.bx--date-input--invalid {
  border-color: var(--cds-support-error);
  box-shadow: 0 0 0 1px var(--cds-support-error);
}

.bx--date-input--invalid:focus {
  outline-color: var(--cds-support-error);
  border-color: var(--cds-support-error);
  box-shadow: 0 0 0 2px var(--cds-support-error);
}

.bx--form-requirement {
  color: #da1e28 !important;
  font-size: 0.75rem;
  margin-top: 0.25rem;
  display: block;
  font-weight: 400;
  line-height: 1.34;
}

.bx--date-input::-webkit-calendar-picker-indicator {
  cursor: pointer;
  opacity: 1;
  filter: invert(0.5);
}

.bx--date-input::-webkit-calendar-picker-indicator:hover {
  opacity: 0.8;
}

.bx--date-input:disabled::-webkit-calendar-picker-indicator {
  cursor: not-allowed;
  opacity: 0.3;
}

.error-message {
  padding: 1rem;
  background-color: var(--cds-support-error-inverse);
  color: var(--cds-support-error);
  border-radius: 4px;
  margin-bottom: 1rem;
}

.form-actions {
  display: flex;
  gap: 0.5rem;
  justify-content: flex-end;
  margin-top: 2rem;
  padding-top: 1rem;
  border-top: 1px solid var(--cds-border-subtle);
}

.btn {
  min-height: 3rem;
  padding: 0.875rem 1.5rem;
  font-size: 0.875rem;
  font-weight: 400;
  line-height: 1.29;
  letter-spacing: 0.16px;
  border: 1px solid transparent;
  border-radius: 0;
  cursor: pointer;
  transition: all 0.11s cubic-bezier(0.2, 0, 0.38, 0.9);
  text-align: center;
  text-decoration: none;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  position: relative;
  outline: none;
  font-family: inherit;
  flex-shrink: 0;
}

.btn:focus-visible {
  outline: 2px solid var(--cds-focus, #0f62fe);
  outline-offset: -2px;
}

.btn-primary {
  background-color: var(--cds-button-primary, #0f62fe);
  color: var(--cds-text-on-color, #ffffff);
  border-color: var(--cds-button-primary, #0f62fe);
}

.btn-primary:hover:not(:disabled) {
  background-color: var(--cds-button-primary-hover, #0043ce);
  border-color: var(--cds-button-primary-hover, #0043ce);
}

.btn-primary:active:not(:disabled) {
  background-color: var(--cds-button-primary-active, #002d9c);
  border-color: var(--cds-button-primary-active, #002d9c);
}

.btn-primary:disabled {
  opacity: 0.5;
  cursor: not-allowed;
  background-color: var(--cds-button-disabled, #c6c6c6);
  border-color: var(--cds-button-disabled, #c6c6c6);
  color: var(--cds-text-disabled, #8d8d8d);
}

.btn-secondary {
  background-color: var(--cds-button-secondary, #393939);
  color: var(--cds-text-on-color, #ffffff);
  border-color: var(--cds-button-secondary, #393939);
}

.btn-secondary:hover:not(:disabled) {
  background-color: var(--cds-button-secondary-hover, #4c4c4c);
  border-color: var(--cds-button-secondary-hover, #4c4c4c);
}

.btn-secondary:active:not(:disabled) {
  background-color: var(--cds-button-secondary-active, #6f6f6f);
  border-color: var(--cds-button-secondary-active, #6f6f6f);
}

.btn-secondary:disabled {
  opacity: 0.5;
  cursor: not-allowed;
  background-color: var(--cds-button-disabled, #c6c6c6);
  border-color: var(--cds-button-disabled, #c6c6c6);
  color: var(--cds-text-disabled, #8d8d8d);
}

@media (max-width: 768px) {
  .create-ticket-page {
    padding: 1rem;
  }

  .page-header {
    margin: 1rem 0;
  }

  .page-header h1 {
    font-size: 1.5rem;
  }

  .form-actions {
    flex-direction: column-reverse;
    gap: 0.5rem;
    width: 100%;
  }

  .form-actions .btn {
    width: 100%;
  }
}

@media (max-width: 480px) {
  .form-actions {
    gap: 0.5rem;
    width: 100%;
  }

  .form-actions .btn {
    width: 100%;
    min-height: 2.5rem;
    padding: 0.75rem 1rem;
    font-size: 0.875rem;
  }
}
</style>
