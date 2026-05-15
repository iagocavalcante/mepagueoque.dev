<template>
  <v-container class="py-12" max-width="500">
    <v-progress-circular v-if="loading" indeterminate class="d-block mx-auto my-8" />

    <div v-else-if="notFound" class="text-center">
      <h1 class="text-h5 mb-4">Esse link expirou ou não existe</h1>
      <v-btn :to="{ name: 'create-payment' }" color="primary">Criar um novo</v-btn>
    </div>

    <div v-else-if="data">
      <h1 class="text-h4 mb-2">{{ formatBRL(data.amount_cents) }}</h1>
      <p class="text-subtitle-1 mb-2">para <strong>{{ data.beneficiary_name }}</strong></p>
      <p class="text-body-2 mb-6">{{ data.description }}</p>

      <img
        v-if="gifUrl"
        :src="gifUrl"
        :alt="gifTitle"
        class="d-block mx-auto mb-6 rounded"
        style="max-width: 280px; max-height: 200px;"
      />

      <canvas ref="qrCanvas" class="d-block mx-auto mb-6" />

      <v-textarea
        :model-value="data.br_code"
        readonly
        auto-grow
        rows="3"
        data-test="br-code"
        class="mb-2"
      />

      <v-btn block color="primary" @click="copy" class="mb-2">
        {{ copied ? 'Copiado ✓' : 'Copiar código PIX' }}
      </v-btn>
      <v-btn block variant="outlined" @click="share">Compartilhar link</v-btn>

      <v-btn
        v-if="revocationToken && !revoked"
        block
        variant="text"
        color="error"
        class="mt-4"
        :loading="revoking"
        data-test="revoke"
        @click="revoke"
      >
        Revogar este link
      </v-btn>

      <p class="text-caption text-center mt-6">
        Expira em {{ formatDate(data.expires_at) }}
      </p>
    </div>

    <div v-else-if="revoked" class="text-center">
      <h1 class="text-h5 mb-4">Link revogado</h1>
      <v-btn :to="{ name: 'create-payment' }" color="primary">Criar outro</v-btn>
    </div>
  </v-container>
</template>

<script setup>
import { ref, onMounted, watch } from 'vue'
import axios from 'axios'
import QRCode from 'qrcode'

const props = defineProps({ slug: { type: String, required: true } })
const apiHost = import.meta.env.VITE_API_HOST || import.meta.env.VITE_LAMBDA_HOST?.replace('/enviar-cobranca', '')

const loading = ref(true)
const notFound = ref(false)
const data = ref(null)
const copied = ref(false)
const qrCanvas = ref(null)
const gifUrl = ref('')
const gifTitle = ref('')
const revocationToken = ref('')
const revoking = ref(false)
const revoked = ref(false)

// Read the revocation token from localStorage (set by /criar on creation).
// Only the original creator's browser will have this — it's how we know
// to show the "Revogar" button.
try {
  revocationToken.value = localStorage.getItem(`revoke_token:${props.slug}`) || ''
} catch {
  // localStorage unavailable — skip the revoke button
}

const revoke = async () => {
  if (!revocationToken.value) return
  revoking.value = true
  try {
    await axios.delete(`${apiHost}/pagamentos/${props.slug}`, {
      headers: { Authorization: `Bearer ${revocationToken.value}` },
    })
    try {
      localStorage.removeItem(`revoke_token:${props.slug}`)
    } catch {
      // ignore
    }
    revoked.value = true
    data.value = null
  } catch {
    // If the link was already deleted (e.g., TTL hit), treat as success.
    revoked.value = true
    data.value = null
  } finally {
    revoking.value = false
  }
}

const fetchGif = async () => {
  const apiKey = import.meta.env.VITE_GIPHY_API_KEY
  const giphyUrl = import.meta.env.VITE_GIPHY_URL
  if (!apiKey || !giphyUrl) return
  try {
    const res = await axios.get(`${giphyUrl}/random`, {
      params: { api_key: apiKey, tag: 'money', rating: 'g' },
    })
    gifUrl.value = res.data?.data?.images?.fixed_height?.url || ''
    gifTitle.value = res.data?.data?.title || ''
  } catch {
    // GIF is decoration — silent failure is fine
  }
}

// Draw the QR once both data and the canvas element exist. The canvas
// only mounts after loading flips to false, so we can't await its presence
// inline in onMounted.
watch([qrCanvas, data], async ([canvas, payload]) => {
  if (canvas && payload?.br_code) {
    await QRCode.toCanvas(canvas, payload.br_code, { width: 280 })
  }
})

onMounted(async () => {
  try {
    const res = await axios.get(`${apiHost}/pagamentos/${props.slug}`)
    data.value = res.data
    fetchGif()
  } catch (e) {
    notFound.value = true
  } finally {
    loading.value = false
  }
})

const copy = async () => {
  if (!data.value) return
  await navigator.clipboard.writeText(data.value.br_code)
  copied.value = true
  setTimeout(() => (copied.value = false), 2000)
}

const share = async () => {
  const url = window.location.href
  if (navigator.share) {
    try { await navigator.share({ url }) } catch {}
  } else {
    await navigator.clipboard.writeText(url)
  }
}

const formatBRL = (cents) =>
  new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(cents / 100)

const formatDate = (iso) =>
  new Date(iso).toLocaleDateString('pt-BR', { day: '2-digit', month: '2-digit', year: 'numeric' })
</script>
