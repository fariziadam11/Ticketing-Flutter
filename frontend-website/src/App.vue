<script setup lang="ts">
import { computed } from 'vue'
import { useRoute } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import AppHeader from '@/components/AppHeader.vue'
import Toast from '@/components/Toast.vue'
import { RouterView } from 'vue-router'

const route = useRoute()
const authStore = useAuthStore()

const showHeader = computed(() => {
  return authStore.isAuthenticated && route.meta.requiresAuth !== false
})
</script>

<template>
  <div id="app">
    <AppHeader v-if="showHeader" />
    <RouterView />
    <Toast />
  </div>
</template>

<style>
#app {
  min-height: 100vh;
  background-color: var(--cds-background);
  color: var(--cds-text-primary);
}

* {
  box-sizing: border-box;
}

body {
  margin: 0;
  font-family: 'IBM Plex Sans', -apple-system, BlinkMacSystemFont, 'Segoe UI',
    'Roboto', 'Oxygen', 'Ubuntu', 'Cantarell', 'Fira Sans', 'Droid Sans',
    'Helvetica Neue', sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}

bx-loading {
  --cds-loader-size: 1.25rem;
}

bx-loading svg {
  width: 1.25rem;
  height: 1.25rem;
}
</style>
