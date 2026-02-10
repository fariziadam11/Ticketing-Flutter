import { createApp } from 'vue'
import App from './App.vue'
import router from './router'
import vueQueryPlugin from './plugins/vueQuery'
import piniaPlugin from './plugins/pinia'
import { useAuthStore } from './stores/auth'

import '@carbon/styles/css/styles.css'
import 'primeicons/primeicons.css'

import '@carbon/web-components/es/components/ui-shell/index.js'
import '@carbon/web-components/es/components/button/index.js'
import '@carbon/web-components/es/components/data-table/index.js'
import '@carbon/web-components/es/components/pagination/index.js'
import '@carbon/web-components/es/components/search/index.js'
import '@carbon/web-components/es/components/tag/index.js'
import '@carbon/web-components/es/components/modal/index.js'
import '@carbon/web-components/es/components/input/index.js'
import '@carbon/web-components/es/components/textarea/index.js'
import '@carbon/web-components/es/components/select/index.js'
import '@carbon/web-components/es/components/file-uploader/index.js'
import '@carbon/web-components/es/components/structured-list/index.js'
import '@carbon/web-components/es/components/tile/index.js'
import '@carbon/web-components/es/components/breadcrumb/index.js'
import '@carbon/web-components/es/components/overflow-menu/index.js'
import '@carbon/web-components/es/components/loading/index.js'

const app = createApp(App)

app.use(piniaPlugin)
app.use(vueQueryPlugin)

const authStore = useAuthStore()
authStore.initializeAuth()

app.use(router)

app.mount('#app')
