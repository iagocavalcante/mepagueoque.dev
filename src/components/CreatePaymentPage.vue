<template>
  <v-container class="py-12" max-width="600">
    <h1 class="text-h4 mb-6">Criar link de cobrança PIX</h1>

    <v-form @submit.prevent="submit" :disabled="loading">
      <v-text-field
        v-model="form.pix_key"
        label="Sua chave PIX"
        placeholder="email, CPF, CNPJ, telefone ou chave aleatória"
        data-test="pix-key"
        required
      />
      <v-text-field
        v-model="form.beneficiary_name"
        label="Seu nome (máx 25)"
        maxlength="25"
        data-test="beneficiary-name"
        required
      />
      <v-text-field
        v-model="form.city"
        label="Cidade (máx 15)"
        maxlength="15"
        placeholder="BRASIL"
        data-test="city"
      />
      <v-text-field
        v-model="form.description"
        label="Descrição (máx 72)"
        maxlength="72"
        data-test="description"
        required
      />
      <v-text-field
        v-model="form.amount"
        label="Valor (R$)"
        type="number"
        step="0.01"
        min="0.01"
        data-test="amount"
        required
      />
      <v-text-field
        v-model="form.slug"
        label="Slug personalizado (opcional)"
        hint="deixe em branco pra gerar automaticamente"
        persistent-hint
        data-test="slug"
      />

      <vue-turnstile
        :site-key="siteKey"
        v-model="turnstileToken"
        class="my-4"
      />

      <v-alert v-if="error" type="error" class="my-3">{{ error }}</v-alert>

      <v-btn
        color="primary"
        type="submit"
        :loading="loading"
        :disabled="!turnstileToken"
        data-test="submit"
        block
      >
        Gerar link
      </v-btn>
    </v-form>
  </v-container>
</template>

<script setup>
import { ref, reactive } from 'vue'
import { useRouter } from 'vue-router'
import axios from 'axios'
import VueTurnstile from 'vue-turnstile'

const router = useRouter()
const siteKey = import.meta.env.VITE_TURNSTILE_SITE_KEY
const apiHost = import.meta.env.VITE_API_HOST || import.meta.env.VITE_LAMBDA_HOST?.replace('/enviar-cobranca', '')

const form = reactive({
  pix_key: '',
  beneficiary_name: '',
  city: '',
  description: '',
  amount: '',
  slug: '',
})

const turnstileToken = ref('')
const loading = ref(false)
const error = ref('')

const submit = async () => {
  error.value = ''
  loading.value = true

  const payload = {
    pix_key: form.pix_key,
    beneficiary_name: form.beneficiary_name,
    city: form.city || 'BRASIL',
    description: form.description,
    amount_cents: Math.round(parseFloat(form.amount) * 100),
    slug: form.slug || undefined,
    token: turnstileToken.value,
  }

  try {
    const { data } = await axios.post(`${apiHost}/pagamentos`, payload)
    router.push({ name: 'payment', params: { slug: data.slug } })
  } catch (e) {
    if (e?.response?.status === 409) {
      error.value = 'esse slug já existe, escolhe outro'
    } else if (e?.response?.status === 400) {
      error.value = 'algum campo está inválido — confere os dados'
    } else if (e?.response?.status === 401) {
      error.value = 'verificação anti-bot falhou, recarrega a página'
    } else {
      error.value = 'algo deu errado, tenta de novo'
    }
  } finally {
    loading.value = false
  }
}

defineExpose({ turnstileToken })
</script>
