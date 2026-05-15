/**
 * Lazy-initialize Firebase Analytics — only after user opts in.
 * The banner calls enableAnalytics() on Accept; main.js calls it on
 * page load if consent was previously granted.
 */

import { getAnalytics } from 'firebase/analytics'

let initialized = false

export const CONSENT_KEY = 'lgpd_consent'

export const getConsent = () => {
  try {
    return localStorage.getItem(CONSENT_KEY) // 'accepted' | 'rejected' | null
  } catch {
    return null
  }
}

export const setConsent = (value) => {
  try {
    localStorage.setItem(CONSENT_KEY, value)
  } catch {
    // localStorage unavailable — fail silent, treat as no consent
  }
}

export const enableAnalytics = (firebaseApp) => {
  if (initialized) return
  if (!import.meta.env.PROD) return
  if (!firebaseApp?.options?.measurementId) return
  try {
    getAnalytics(firebaseApp)
    initialized = true
  } catch (error) {
    console.warn('Analytics initialization failed:', error)
  }
}
