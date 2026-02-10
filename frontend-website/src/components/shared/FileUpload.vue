<script setup lang="ts">
import { ref, watch, computed } from 'vue'
import { formatFileSize, handleFileInputChange, removeFileFromArray } from '@/utils/file'

interface Props {
  files: File[]
  disabled?: boolean
  multiple?: boolean
  accept?: string
  id?: string
}

interface Emits {
  (e: 'update:files', files: File[]): void
}

const props = withDefaults(defineProps<Props>(), {
  disabled: false,
  multiple: true,
  accept: undefined,
  id: undefined,
})

const emit = defineEmits<Emits>()

const inputId = computed(() => props.id || `fileInput-${Math.random().toString(36).substr(2, 9)}`)

const localFiles = ref<File[]>([...props.files])

watch(
  () => props.files,
  (newFiles) => {
    localFiles.value = [...newFiles]
  },
  { deep: true },
)

const handleFileChange = (event: Event) => {
  const newFiles = handleFileInputChange(event, localFiles.value)
  localFiles.value = newFiles
  emit('update:files', newFiles)
}

const removeFile = (index: number) => {
  const newFiles = removeFileFromArray(localFiles.value, index)
  localFiles.value = newFiles
  emit('update:files', newFiles)
}
</script>

<template>
  <div class="file-upload">
    <div class="file-upload-wrapper">
      <input
        :id="inputId"
        type="file"
        :multiple="multiple"
        :accept="accept"
        class="bx--file-input"
        :disabled="disabled"
        @change="handleFileChange"
      />
      <label :for="inputId" class="bx--file-label">
        <span class="bx--file-label-text">Choose files</span>
        <span class="bx--file-label-button">Browse</span>
      </label>
    </div>
    <div v-if="localFiles.length > 0" class="file-list">
      <div v-for="(file, index) in localFiles" :key="index" class="file-item">
        <span class="file-name">{{ file.name }}</span>
        <span class="file-size">({{ formatFileSize(file.size) }})</span>
        <button
          type="button"
          class="file-remove-btn"
          :disabled="disabled"
          @click="removeFile(index)"
        >
          <i class="pi pi-times"></i>
        </button>
      </div>
    </div>
    <small v-if="localFiles.length > 0" class="helper-text">
      {{ localFiles.length }} file(s) selected
    </small>
  </div>
</template>

<style scoped>
.file-upload {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.file-upload-wrapper {
  position: relative;
}

.bx--file-input {
  position: absolute;
  width: 0.1px;
  height: 0.1px;
  opacity: 0;
  overflow: hidden;
  z-index: -1;
}

.bx--file-label {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  cursor: pointer;
  padding: 0.875rem 1rem;
  background-color: var(--cds-field-01);
  border: 1px solid var(--cds-border-subtle);
  border-radius: 4px;
  transition: all 0.15s ease;
}

.bx--file-label:hover {
  background-color: var(--cds-layer-hover-01);
  border-color: var(--cds-border-strong);
}

.bx--file-label:active {
  background-color: var(--cds-layer-active-01);
}

.bx--file-label-text {
  flex: 1;
  color: var(--cds-text-primary);
  font-size: 0.9375rem;
}

.bx--file-label-button {
  padding: 0.5rem 1rem;
  background-color: var(--cds-button-secondary);
  color: var(--cds-text-on-color);
  border: 1px solid var(--cds-button-secondary);
  border-radius: 4px;
  font-size: 0.875rem;
  font-weight: 400;
  transition: all 0.11s cubic-bezier(0.2, 0, 0.38, 0.9);
}

.bx--file-label:hover .bx--file-label-button {
  background-color: var(--cds-button-secondary-hover);
  border-color: var(--cds-button-secondary-hover);
}

.bx--file-input:disabled + .bx--file-label {
  opacity: 0.5;
  cursor: not-allowed;
  background-color: var(--cds-field-disabled);
}

.bx--file-input:disabled + .bx--file-label:hover {
  background-color: var(--cds-field-disabled);
  border-color: var(--cds-border-subtle);
}

.file-list {
  margin-top: 1rem;
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.file-item {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.75rem 1rem;
  background-color: var(--cds-layer-01);
  border: 1px solid var(--cds-border-subtle);
  border-radius: 4px;
}

.file-name {
  flex: 1;
  color: var(--cds-text-primary);
  font-size: 0.875rem;
}

.file-size {
  color: var(--cds-text-secondary);
  font-size: 0.8125rem;
}

.file-remove-btn {
  background: none;
  border: none;
  color: var(--cds-support-error);
  cursor: pointer;
  padding: 0.25rem 0.5rem;
  border-radius: 4px;
  transition: background-color 0.15s;
  width: 2rem;
  height: 2rem;
  display: flex;
  align-items: center;
  justify-content: center;
}

.file-remove-btn i {
  font-size: 1rem;
}

.file-remove-btn:hover:not(:disabled) {
  background-color: var(--cds-layer-hover-01);
}

.file-remove-btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.helper-text {
  font-size: 0.8125rem;
  color: var(--cds-text-secondary);
  margin-top: 0.25rem;
}
</style>

