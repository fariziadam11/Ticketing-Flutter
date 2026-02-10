<script setup lang="ts">
import { computed } from 'vue'
import { useToastStore, type Toast } from '@/stores/toast'

const toastStore = useToastStore()

const toasts = computed(() => toastStore.toasts)

const getIconClass = (type: Toast['type']): string => {
  switch (type) {
    case 'success':
      return 'pi-check-circle'
    case 'error':
      return 'pi-times-circle'
    case 'warning':
      return 'pi-exclamation-triangle'
    case 'info':
      return 'pi-info-circle'
    default:
      return 'pi-info-circle'
  }
}

const getToastClass = (type: Toast['type']): string => {
  return `toast toast-${type}`
}
</script>

<template>
  <Teleport to="body">
    <div class="toast-container">
      <TransitionGroup name="toast" tag="div" class="toast-list">
        <div
          v-for="toast in toasts"
          :key="toast.id"
          :class="getToastClass(toast.type)"
          role="alert"
          aria-live="polite"
        >
          <div class="toast-content">
            <i :class="`pi ${getIconClass(toast.type)}`" class="toast-icon"></i>
            <span class="toast-message">{{ toast.message }}</span>
          </div>
          <button
            class="toast-close"
            type="button"
            aria-label="Close notification"
            @click="toastStore.removeToast(toast.id)"
          >
            <i class="pi pi-times"></i>
          </button>
        </div>
      </TransitionGroup>
    </div>
  </Teleport>
</template>

<style scoped>
.toast-container {
  position: fixed;
  top: 1rem;
  right: 1rem;
  z-index: 9999;
  pointer-events: none;
}

.toast-list {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
  align-items: flex-end;
}

.toast {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 1rem;
  min-width: 300px;
  max-width: 500px;
  padding: 1rem 1.25rem;
  border-radius: 4px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
  pointer-events: auto;
  border-left: 4px solid;
  animation: slideIn 0.3s ease-out;
}

.toast-success {
  border-left-color: var(--cds-support-success, #24a148);
  background-color: #ffffff !important;
  border: 1px solid var(--cds-support-success, #24a148);
  opacity: 1 !important;
}

.toast-error {
  border-left-color: var(--cds-support-error, #da1e28);
  background-color: #ffffff !important;
  border: 1px solid var(--cds-support-error, #da1e28);
  opacity: 1 !important;
}

.toast-warning {
  border-left-color: var(--cds-support-warning, #f1c21b);
  background-color: #ffffff !important;
  border: 1px solid var(--cds-support-warning, #f1c21b);
  opacity: 1 !important;
}

.toast-info {
  border-left-color: var(--cds-link-primary, #0f62fe);
  background-color: #ffffff !important;
  border: 1px solid var(--cds-link-primary, #0f62fe);
  opacity: 1 !important;
}

.toast-content {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  flex: 1;
}

.toast-icon {
  font-size: 1.25rem;
  flex-shrink: 0;
}

.toast-success .toast-icon {
  color: var(--cds-support-success, #24a148);
}

.toast-error .toast-icon {
  color: var(--cds-support-error, #da1e28);
}

.toast-warning .toast-icon {
  color: var(--cds-support-warning, #f1c21b);
}

.toast-info .toast-icon {
  color: var(--cds-link-primary, #0f62fe);
}

.toast-message {
  font-size: 0.875rem;
  line-height: 1.5;
  color: var(--cds-text-primary);
  word-wrap: break-word;
}

.toast-close {
  background: none;
  border: none;
  color: var(--cds-text-secondary);
  cursor: pointer;
  padding: 0.25rem;
  border-radius: 4px;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  transition: all 0.15s ease;
  width: 1.5rem;
  height: 1.5rem;
}

.toast-close:hover {
  background-color: var(--cds-layer-hover-01);
  color: var(--cds-text-primary);
}

.toast-close:focus-visible {
  outline: 2px solid var(--cds-focus);
  outline-offset: 2px;
}

@keyframes slideIn {
  from {
    transform: translateX(100%);
    opacity: 0;
  }
  to {
    transform: translateX(0);
    opacity: 1;
  }
}

.toast-enter-active {
  transition: all 0.3s ease-out;
}

.toast-leave-active {
  transition: all 0.3s ease-in;
}

.toast-enter-from {
  transform: translateX(100%);
  opacity: 0;
}

.toast-leave-to {
  transform: translateX(100%);
  opacity: 0;
}

.toast-move {
  transition: transform 0.3s ease;
}

@media (max-width: 640px) {
  .toast-container {
    top: 0.5rem;
    right: 0.5rem;
    left: 0.5rem;
  }

  .toast {
    min-width: auto;
    max-width: 100%;
  }

  .toast-list {
    align-items: stretch;
  }
}
</style>

