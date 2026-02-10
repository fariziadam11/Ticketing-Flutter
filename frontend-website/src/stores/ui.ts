import { defineStore } from 'pinia'

export const useUiStore = defineStore('ui', {
  state: () => ({
    sidebarOpen: true,
    theme: 'light' as 'light' | 'dark',
  }),

  actions: {
    toggleSidebar() {
      this.sidebarOpen = !this.sidebarOpen
    },

    setTheme(theme: 'light' | 'dark') {
      this.theme = theme
    },
  },
})

