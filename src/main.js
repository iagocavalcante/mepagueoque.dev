/**
 * Main Application Entry Point
 * Vue 3 with Vuetify 3, Firebase 10+, and modern tooling
 */

import { createApp } from 'vue'
import App from './App.vue'
import vuetify from './plugins/vuetify'

// Firebase 10+ modular imports
import { initializeApp } from 'firebase/app'
import { getAnalytics } from 'firebase/analytics'

// Vue reCAPTCHA v3 for Vue 3
import { VueReCaptcha } from 'vue-recaptcha-v3'

// Firebase configuration
const firebaseConfig = {
  apiKey: import.meta.env.VITE_FIREBASE_API_KEY,
  authDomain: import.meta.env.VITE_FIREBASE_AUTH_DOMAIN,
  databaseURL: import.meta.env.VITE_FIREBASE_DATABASE_URL,
  projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID,
  storageBucket: import.meta.env.VITE_FIREBASE_STORAGE_BUCKET,
  messagingSenderId: import.meta.env.VITE_FIREBASE_MESSAGING_SENDER_ID,
  appId: import.meta.env.VITE_FIREBASE_APP_ID,
  measurementId: import.meta.env.VITE_FIREBASE_MEASUREMENT_ID,
}

// Initialize Firebase
const firebaseApp = initializeApp(firebaseConfig)

// Initialize Analytics only in production
if (import.meta.env.PROD && firebaseConfig.measurementId) {
  try {
    getAnalytics(firebaseApp)
  } catch (error) {
    console.warn('Analytics initialization failed:', error)
  }
}

// Create Vue app
const app = createApp(App)

// Register plugins
app.use(vuetify)

// Register Vue reCAPTCHA v3
app.use(VueReCaptcha, {
  siteKey: import.meta.env.VITE_RECAPTCHA_KEY,
  loaderOptions: {
    autoHideBadge: false,
    explicitRenderParameters: {
      badge: 'bottomright',
    },
  },
})

// Mount app
app.mount('#app')
