<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { authApi } from '@/api/auth'
import { logger } from '@/utils/logger'
import { useToast } from '@/composables/useToast'

const router = useRouter()
const authStore = useAuthStore()
const toast = useToast()

const isUserSidebarOpen = ref(false)
const windowWidth = ref(window.innerWidth)

const isMobile = computed(() => windowWidth.value <= 768)

const updateWindowWidth = () => {
  windowWidth.value = window.innerWidth
}

onMounted(() => {
  window.addEventListener('resize', updateWindowWidth)
  updateWindowWidth()
})

onUnmounted(() => {
  window.removeEventListener('resize', updateWindowWidth)
})

const toggleUserSidebar = () => {
  isUserSidebarOpen.value = !isUserSidebarOpen.value
}

const closeUserSidebar = () => {
  isUserSidebarOpen.value = false
}

const navigateTo = (path: string) => {
  router.push(path)
  closeUserSidebar()
}

const handleLogout = async () => {
  const token = authStore.token
  if (token) {
    try {
      await authApi.revokeToken(token)
    } catch (error) {
      logger.warn('Failed to revoke token', error)
    }
  }

  authStore.clearAuth()
  toast.info('Logged out successfully')
  router.push('/login')
}
</script>

<template>
  <div>
    <header class="app-header">
      <div class="header-content">
        <div class="header-left">
          <button class="brand" type="button" @click="router.push('/dashboard')">
            <img src="/werk-white.png" alt="Werk logo" class="brand-logo" />
            <span class="app-title">Ticketing</span>
          </button>
          <nav class="header-nav">
            <button
              type="button"
              class="nav-link"
              :class="{ active: router.currentRoute.value.path === '/dashboard' }"
              @click="router.push('/dashboard')"
            >
              Dashboard
            </button>
            <button
              type="button"
              class="nav-link"
              :class="{ active: router.currentRoute.value.path === '/tickets' }"
              @click="router.push('/tickets')"
            >
              Tickets
            </button>
            <button
              type="button"
              class="nav-link"
              :class="{ active: router.currentRoute.value.path === '/articles' }"
              @click="router.push('/articles')"
            >
              Articles
            </button>
          </nav>
        </div>
        <div class="header-right">
          <button
            v-if="authStore.user"
            type="button"
            class="user-sidebar-toggle"
            @click="toggleUserSidebar"
          >
            <span class="user-toggle-icon" aria-hidden="true">
              <i :class="isMobile ? 'pi pi-bars' : 'pi pi-user'"></i>
            </span>
            <span class="user-toggle-name">
              {{ authStore.fullName }}
            </span>
          </button>
        </div>
      </div>
    </header>

    <!-- Overlay -->
    <div
      v-if="isUserSidebarOpen"
      class="sidebar-overlay"
      @click="closeUserSidebar"
    ></div>

    <!-- User Sidebar -->
    <aside v-if="authStore.user" class="user-sidebar" :class="{ open: isUserSidebarOpen }">
      <div class="user-sidebar-header">
        <span class="user-sidebar-title">Menu</span>
        <button type="button" class="user-sidebar-close" @click="closeUserSidebar">
          <i class="pi pi-times"></i>
        </button>
      </div>
      <div class="user-sidebar-body">
        <!-- Mobile Navigation -->
        <nav class="user-sidebar-nav">
          <button
            type="button"
            class="user-sidebar-nav-link"
            :class="{ active: router.currentRoute.value.path === '/dashboard' }"
            @click="navigateTo('/dashboard')"
          >
            <i class="pi pi-home"></i>
            <span>Dashboard</span>
          </button>
          <button
            type="button"
            class="user-sidebar-nav-link"
            :class="{ active: router.currentRoute.value.path === '/tickets' }"
            @click="navigateTo('/tickets')"
          >
            <i class="pi pi-ticket"></i>
            <span>Tickets</span>
          </button>
          <button
            type="button"
            class="user-sidebar-nav-link"
            :class="{ active: router.currentRoute.value.path === '/articles' }"
            @click="navigateTo('/articles')"
          >
            <i class="pi pi-book"></i>
            <span>Articles</span>
          </button>
        </nav>

        <!-- User Info -->
        <div class="user-sidebar-info">
          <span class="user-sidebar-label">Signed in as</span>
          <span class="user-sidebar-name">{{ authStore.fullName }}</span>
        </div>

        <!-- Logout Button -->
        <bx-btn
          id="headerLogoutBtn"
          kind="danger"
          size="sm"
          class="user-sidebar-logout-btn"
          @click="handleLogout"
        >
          Logout
        </bx-btn>
      </div>
    </aside>
  </div>
</template>

<style scoped>
.app-header {
  background-color: #000000;
  border-bottom: 1px solid #262626;
  padding: 0 1rem;
  position: sticky;
  top: 0;
  z-index: 100;
}

.header-content {
  width: 100%;
  display: flex;
  justify-content: space-between;
  align-items: center;
  height: 3rem;
}

.header-left {
  display: flex;
  align-items: center;
  gap: 2rem;
}

.header-nav {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.nav-link {
  background: none;
  border: none;
  color: #ffffff;
  font-size: 0.875rem;
  padding: 0.5rem 1rem;
  border-radius: 4px;
  cursor: pointer;
  transition: background-color 0.2s ease;
}

.nav-link:hover {
  background-color: rgba(255, 255, 255, 0.12);
}

.nav-link.active {
  background-color: rgba(255, 255, 255, 0.2);
  font-weight: 500;
}

.nav-link:focus-visible {
  outline: 2px solid #ffffff;
  outline-offset: 2px;
}

.brand {
  display: inline-flex;
  align-items: center;
  gap: 0.5rem;
  background: none;
  border: none;
  padding: 0;
  margin: 0;
  cursor: pointer;
  color: #ffffff;
}

.brand:focus-visible {
  outline: 2px solid #ffffff;
  outline-offset: 2px;
}

.brand-logo {
  height: 1.4rem;
  width: auto;
  display: block;
}

.app-title {
  margin: 0;
  font-size: 1.25rem;
  font-weight: 500;
  color: #ffffff;
}

.app-title:hover {
  color: #f4f4f4;
}

.header-right {
  display: flex;
  align-items: center;
}

.user-sidebar-toggle {
  border: none;
  background: none;
  color: #ffffff;
  font-size: 0.875rem;
  cursor: pointer;
  padding: 0.25rem 0.75rem;
  border-radius: 999px;
  display: flex;
  align-items: center;
  gap: 0.35rem;
}

.user-sidebar-toggle:hover {
  background-color: rgba(255, 255, 255, 0.12);
}

.user-sidebar-toggle:focus-visible {
  outline: 2px solid #ffffff;
  outline-offset: 2px;
}

.user-toggle-icon {
  display: inline-flex;
  align-items: center;
}

.user-toggle-icon i {
  font-size: 1rem;
}

.user-sidebar-close {
  display: inline-flex;
  align-items: center;
  justify-content: center;
}

.user-sidebar-close i {
  font-size: 1rem;
}

.user-toggle-name {
  max-width: 12rem;
  text-overflow: ellipsis;
  white-space: nowrap;
  overflow: hidden;
}

.user-sidebar {
  position: fixed;
  top: 0;
  right: 0;
  height: 100vh;
  width: 260px;
  background-color: #000000;
  border-left: 1px solid var(--cds-border-subtle);
  box-shadow: -0.25rem 0 0.5rem rgba(0, 0, 0, 0.1);
  padding: 1rem;
  display: flex;
  flex-direction: column;
  gap: 0;
  z-index: 120;
  transform: translateX(100%);
  transition: transform 150ms ease-out;
}

.user-sidebar.open {
  transform: translateX(0);
}

.user-sidebar-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 1rem;
  padding-bottom: 1rem;
  border-bottom: 1px solid var(--cds-border-subtle);
}

.user-sidebar-title {
  font-size: 0.875rem;
  font-weight: 600;
  color: #ffffff;
}

.user-sidebar-close {
  border: none;
  background: none;
  cursor: pointer;
  font-size: 1rem;
  padding: 0.25rem;
  color: #ffffff;
}

.user-sidebar-close:hover {
  color: #f4f4f4;
}

.user-sidebar-body {
  display: flex;
  flex-direction: column;
  gap: 0;
  flex: 1;
  overflow-y: auto;
}

.user-sidebar-nav {
  display: none;
  flex-direction: column;
  gap: 0.5rem;
  margin-bottom: 1rem;
  padding-bottom: 1rem;
  border-bottom: 1px solid var(--cds-border-subtle);
}

.user-sidebar-nav-link {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  background: none;
  border: none;
  color: #ffffff;
  font-size: 0.9375rem;
  padding: 0.875rem 1rem;
  border-radius: 4px;
  cursor: pointer;
  transition: background-color 0.2s ease;
  text-align: left;
  width: 100%;
}

.user-sidebar-nav-link i {
  font-size: 1.125rem;
  width: 1.25rem;
  display: flex;
  align-items: center;
  justify-content: center;
}

.user-sidebar-nav-link:hover {
  background-color: rgba(255, 255, 255, 0.12);
}

.user-sidebar-nav-link.active {
  background-color: rgba(255, 255, 255, 0.2);
  font-weight: 500;
}

.user-sidebar-nav-link:focus-visible {
  outline: 2px solid #ffffff;
  outline-offset: -2px;
}

.user-sidebar-info {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
  margin-top: auto;
  margin-bottom: 1rem;
}

.user-sidebar-label {
  font-size: 0.75rem;
  color: #c6c6c6;
}

.user-sidebar-name {
  font-size: 0.875rem;
  font-weight: 500;
  color: #ffffff;
}

.user-sidebar-logout-btn {
  margin-top: 0;
}

@media (max-width: 768px) {
  .header-left {
    gap: 1rem;
  }

  .header-nav {
    gap: 0.25rem;
  }

  .nav-link {
    padding: 0.5rem 0.75rem;
    font-size: 0.8125rem;
  }

  .app-title {
    font-size: 1rem;
  }

  .brand-logo {
    height: 1.2rem;
  }

  .user-toggle-name {
    display: none;
  }

  .user-sidebar {
    width: 100%;
    max-width: 300px;
  }
}

@media (max-width: 480px) {
  .header-content {
    padding: 0 0.5rem;
  }

  .header-nav {
    display: none;
  }

  .app-title {
    font-size: 0.875rem;
  }

  .sidebar-overlay {
    display: block;
  }

  .user-sidebar-nav {
    display: flex;
    margin-bottom: 1rem;
  }

  .user-sidebar-info {
    margin-bottom: 1rem;
  }

  .user-sidebar {
    width: 100%;
    max-width: 300px;
  }
}
</style>

