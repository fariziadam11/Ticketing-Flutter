<script setup lang="ts">
import { ref, computed } from 'vue'
import { useRouter } from 'vue-router'
import { useLogin } from '@/composables/useAuth'

const router = useRouter()

const email = ref('')
const password = ref('')
const showPassword = ref(false)

const { mutate: login, isPending } = useLogin()

const isFormValid = computed(() => {
  return email.value.trim() !== '' && password.value.length >= 6
})

const handleSubmit = (e?: Event) => {
  if (e) {
    e.preventDefault()
  }

  if (!isFormValid.value) {
    return
  }

  login({
    email: email.value.trim(),
    password: password.value,
  })
}
</script>

<template>
  <div class="auth-page">
    <div class="auth-container">
      <bx-tile id="loginTile" class="auth-card">
        <div class="auth-header">
          <h2 class="auth-title">Welcome Back</h2>
          <p class="auth-subtitle">Sign in to your account</p>
        </div>

        <form @submit.prevent="handleSubmit" class="auth-form">
          <div class="bx--form-item">
            <label for="email" class="bx--label">
              Email <span class="required">*</span>
            </label>
            <input
              id="email"
              v-model="email"
              type="email"
              class="bx--text-input"
              placeholder="your.email@example.com"
              :required="true"
              :disabled="isPending"
              autocomplete="email"
            />
          </div>

          <div class="bx--form-item">
            <label for="password" class="bx--label">
              Password <span class="required">*</span>
            </label>
            <div class="input-wrapper">
              <input
                id="password"
                v-model="password"
                :type="showPassword ? 'text' : 'password'"
                class="bx--text-input"
                placeholder="Enter your password"
                :required="true"
                :disabled="isPending"
                autocomplete="current-password"
              />
              <button
                type="button"
                class="password-toggle-btn"
                :disabled="isPending"
                @click="showPassword = !showPassword"
              >
                {{ showPassword ? 'Hide' : 'Show' }}
              </button>
            </div>
            <div class="input-feedback">
              <small v-if="password.length > 0 && password.length < 6" class="helper-text">
                <span class="icon"><i class="pi pi-exclamation-triangle"></i></span> Password must be at least 6 characters
              </small>
            </div>
          </div>

          <div class="form-actions">
            <button
              type="submit"
              class="bx--btn bx--btn--primary full-width submit-btn"
              :disabled="!isFormValid || isPending"
            >
              <span v-if="isPending" class="btn-content">
                <span class="spinner"></span>
                Signing in...
              </span>
              <span v-else class="btn-content">Sign In</span>
            </button>
          </div>

          <div class="auth-footer">
            <p>
              Don't have an account?
              <a href="#" @click.prevent="router.push('/register')" class="auth-link">
                Create one here
              </a>
            </p>
          </div>
        </form>
      </bx-tile>
    </div>
  </div>
</template>

<style scoped>
.auth-page {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  background-color: var(--cds-background);
  padding: 2rem 1rem;
}

.auth-container {
  width: 100%;
  max-width: 420px;
}

.auth-card {
  padding: 2.5rem;
  background-color: var(--cds-layer-01);
  box-shadow: 0 2px 6px rgba(0, 0, 0, 0.2);
  border-radius: 0;
  border: 1px solid var(--cds-border-subtle);
  display: block;
  width: 100%;
}

.auth-header {
  text-align: center;
  margin-bottom: 2rem;
}

.auth-title {
  margin: 0 0 0.5rem 0;
  font-size: 2rem;
  font-weight: 600;
  color: var(--cds-text-primary);
  letter-spacing: -0.02em;
}

.auth-subtitle {
  margin: 0;
  color: var(--cds-text-secondary);
  font-size: 0.9375rem;
}

.auth-form {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
}

.bx--form-item {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.bx--label {
  display: block;
  margin-bottom: 0.375rem;
  font-size: 0.875rem;
  font-weight: 500;
  color: var(--cds-text-primary);
}

.required {
  color: var(--cds-support-error);
}

.input-wrapper {
  position: relative;
  display: flex;
  align-items: center;
}

.bx--text-input {
  width: 100%;
  padding: 0.875rem 1rem;
  font-size: 0.9375rem;
  background-color: var(--cds-field-01);
  border: 1px solid var(--cds-border-subtle);
  border-radius: 4px;
  color: var(--cds-text-primary);
  transition: all 0.15s ease;
}

.bx--text-input:focus {
  outline: 2px solid var(--cds-focus);
  outline-offset: -2px;
  border-color: var(--cds-focus);
  background-color: var(--cds-field-01);
}

.bx--text-input:disabled {
  background-color: var(--cds-field-disabled);
  color: var(--cds-text-disabled);
  cursor: not-allowed;
  opacity: 0.6;
}

.bx--text-input--invalid {
  border-color: var(--cds-support-error);
}

.bx--text-input--invalid:focus {
  outline-color: var(--cds-support-error);
  border-color: var(--cds-support-error);
}

.password-toggle-btn {
  position: absolute;
  right: 0.5rem;
  top: 50%;
  transform: translateY(-50%);
  background: none;
  border: none;
  color: var(--cds-link-primary);
  font-size: 0.8125rem;
  font-weight: 500;
  cursor: pointer;
  padding: 0.25rem 0.5rem;
  border-radius: 4px;
  transition: background-color 0.15s;
}

.password-toggle-btn:hover:not(:disabled) {
  background-color: var(--cds-layer-hover-01);
}

.password-toggle-btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.input-feedback {
  min-height: 1.25rem;
  margin-top: 0.25rem;
}

.helper-text {
  display: flex;
  align-items: center;
  gap: 0.375rem;
  font-size: 0.8125rem;
  color: var(--cds-text-secondary);
  margin: 0;
}

.icon {
  display: inline-flex;
  align-items: center;
}

.icon i {
  font-size: 0.875rem;
}

.form-actions {
  margin-top: 0.5rem;
}

.full-width {
  width: 100%;
}

.submit-btn {
  padding: 0.875rem 1.5rem;
  font-size: 1rem;
  font-weight: 400;
  min-height: 3rem;
  transition: all 0.11s cubic-bezier(0.2, 0, 0.38, 0.9);
  background-color: #0f62fe;
  color: #ffffff;
  border: 1px solid #0f62fe;
  cursor: pointer;
}

.submit-btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
  background-color: var(--cds-button-disabled);
  border-color: var(--cds-button-disabled);
  color: var(--cds-text-disabled);
}

.submit-btn:not(:disabled):hover {
  background-color: #0043ce;
  border-color: #0043ce;
}

.submit-btn:not(:disabled):active {
  background-color: #002d9c;
  border-color: #002d9c;
}

.btn-content {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 0.5rem;
}

.spinner {
  width: 0.875rem;
  height: 0.875rem;
  border: 2px solid rgba(255, 255, 255, 0.3);
  border-top-color: var(--cds-text-on-color);
  border-radius: 50%;
  animation: spin 0.6s linear infinite;
  flex-shrink: 0;
}

@keyframes spin {
  to {
    transform: rotate(360deg);
  }
}

.auth-footer {
  margin-top: 1.5rem;
  padding-top: 1.5rem;
  border-top: 1px solid var(--cds-border-subtle);
  text-align: center;
  font-size: 0.875rem;
  color: var(--cds-text-secondary);
}

.auth-link {
  color: var(--cds-link-primary);
  text-decoration: none;
  font-weight: 500;
  margin-left: 0.25rem;
  transition: color 0.15s;
}

.auth-link:hover {
  color: var(--cds-link-primary-hover);
  text-decoration: underline;
}

@media (max-width: 640px) {
  .auth-card {
    padding: 2rem 1.5rem;
  }

  .auth-title {
    font-size: 1.75rem;
  }
}
</style>
