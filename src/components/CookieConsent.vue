<template>
  <v-snackbar
    v-model="visible"
    :timeout="-1"
    location="bottom"
    multi-line
    color="surface"
    elevation="8"
    class="cookie-consent"
  >
    <div class="text-body-2 mb-2">
      Usamos cookies essenciais para o funcionamento do site. Com seu
      consentimento, também usamos cookies analíticos (Firebase Analytics)
      para entender como o site é usado. Veja a
      <router-link :to="{ name: 'privacy' }" class="consent-link">
        Política de Privacidade
      </router-link>.
    </div>

    <template #actions>
      <v-btn variant="text" @click="reject">Recusar</v-btn>
      <v-btn color="primary" @click="accept">Aceitar</v-btn>
    </template>
  </v-snackbar>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { firebaseApp } from '@/lib/firebase'
import { getConsent, setConsent, enableAnalytics } from '@/lib/analytics'

const visible = ref(false)

onMounted(() => {
  // Show banner only if user hasn't made a choice yet.
  visible.value = getConsent() === null
})

const accept = () => {
  setConsent('accepted')
  enableAnalytics(firebaseApp)
  visible.value = false
}

const reject = () => {
  setConsent('rejected')
  visible.value = false
}
</script>

<style scoped>
.consent-link {
  color: inherit;
  text-decoration: underline;
}
</style>
