import { createPinia } from 'pinia'
import type { App } from 'vue'

const pinia = createPinia()

export default {
  install(app: App) {
    app.use(pinia)
  },
}

