/**
 * Main Application Entry Point
 * Vue 3 with Vuetify 3, Firebase 10+, and modern tooling
 */

import { createApp } from 'vue'
import App from './App.vue'
import vuetify from './plugins/vuetify'
import { router } from './router'

import { firebaseApp } from './lib/firebase'
import { enableAnalytics, getConsent } from './lib/analytics'

// Only enable analytics if the user previously accepted cookies.
// First-time visitors see the consent banner and analytics stays off
// until they click "Aceitar" (which calls enableAnalytics directly).
if (getConsent() === 'accepted') {
  enableAnalytics(firebaseApp)
}

// Create Vue app
const app = createApp(App)

// Register plugins
app.use(vuetify)
app.use(router)

// Mount app
app.mount('#app')
