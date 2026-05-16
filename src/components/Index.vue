<template>
  <v-container>
    <v-row class="text-center align-center justify-center">
      <!-- Logo Section -->
      <v-col cols="12">
        <!-- Mobile icon -->
        <v-img
          :src="moneyTransfer"
          contain
          :height="100"
          class="d-sm-none mb-4"
          alt="Ícone de transferência de dinheiro"
        />
        <Logo />
      </v-col>

      <!-- Illustration - Desktop Only -->
      <v-col
        cols="12"
        md="6"
        class="d-none d-md-flex align-center justify-center"
      >
        <v-img
          :src="moneyTransfer"
          contain
          :max-height="400"
          alt="Ilustração de transferência de dinheiro"
        />
      </v-col>

      <!-- Form Section -->
      <v-col
        cols="12"
        md="6"
      >
        <v-card
          class="form-card elevation-4"
          rounded="xl"
        >
          <v-card-text class="pa-6 pa-md-8">
            <v-form
              ref="formRef"
              v-model="isValid"
              @submit.prevent="handleRecaptcha"
            >
              <!-- Message Input -->
              <v-textarea
                v-model="message.text"
                label="Escreva uma mensagem para o(a) caloteiro(a)"
                placeholder="Nossa dívida está completando 1 mês! Você está convidado a pagar."
                :rules="rules.text"
                color="success"
                variant="outlined"
                rows="4"
                auto-grow
                clearable
                counter
                maxlength="500"
                data-testid="mensagem"
                aria-label="Mensagem de cobrança"
                class="mb-4"
              >
                <template #prepend-inner>
                  <v-icon
                    icon="mdi-message-text"
                    color="success"
                  />
                </template>
              </v-textarea>

              <!-- Value Input -->
              <v-text-field
                v-model="message.value"
                label="Qual o valor do golpe?"
                placeholder="100.00"
                prefix="R$"
                :rules="rules.value"
                color="success"
                variant="outlined"
                type="text"
                clearable
                data-testid="valor"
                aria-label="Valor da dívida"
                class="mb-4"
              >
                <template #prepend-inner>
                  <v-icon
                    icon="mdi-currency-brl"
                    color="success"
                  />
                </template>
              </v-text-field>

              <!-- Shipment Type Selection -->
              <div class="mb-6">
                <p class="text-body-1 text-center mb-3 font-weight-medium">
                  Escolha uma opção de envio:
                </p>
                <v-chip-group
                  v-model="selectedShipmentType"
                  mandatory
                  selected-class="text-success"
                  color="success"
                  class="justify-center"
                >
                  <v-chip
                    value="email"
                    size="large"
                    variant="outlined"
                    prepend-icon="mdi-email"
                    aria-label="Enviar por email"
                  >
                    Email
                  </v-chip>
                  <v-chip
                    value="whatsapp"
                    size="large"
                    variant="outlined"
                    prepend-icon="mdi-whatsapp"
                    aria-label="Enviar por WhatsApp"
                  >
                    WhatsApp
                  </v-chip>
                </v-chip-group>
              </div>

              <!-- Conditional Destination Input -->
              <v-expand-transition>
                <v-text-field
                  v-if="selectedShipmentType === 'email'"
                  v-model="message.destination"
                  label="Para qual email você deseja enviar?"
                  placeholder="caloteiro@example.com"
                  :rules="rules.email"
                  color="success"
                  variant="outlined"
                  type="email"
                  clearable
                  aria-label="Email de destino"
                  class="mb-4"
                >
                  <template #prepend-inner>
                    <v-icon
                      icon="mdi-email-outline"
                      color="success"
                    />
                  </template>
                </v-text-field>
              </v-expand-transition>

              <v-expand-transition>
                <v-text-field
                  v-if="selectedShipmentType === 'whatsapp'"
                  v-model="message.destination"
                  label="Para qual número de WhatsApp você deseja enviar?"
                  placeholder="+55 11 99999-9999"
                  :rules="rules.whatsapp"
                  color="success"
                  variant="outlined"
                  type="tel"
                  clearable
                  aria-label="Número de WhatsApp"
                  class="mb-4"
                >
                  <template #prepend-inner>
                    <v-icon
                      icon="mdi-whatsapp"
                      color="success"
                    />
                  </template>
                </v-text-field>
              </v-expand-transition>

              <!-- Turnstile Widget -->
              <div class="mb-4 d-flex justify-center">
                <VueTurnstile
                  ref="turnstileWidget"
                  :site-key="turnstileSiteKey"
                  :model-value="turnstileToken"
                  v-bind="{
                    appearance: 'always',
                    retry: 'never',
                    'refresh-expired': 'auto'
                  }"
                  @update:model-value="onTurnstileUpdate"
                  @error="onTurnstileError"
                  @expired="onTurnstileExpired"
                  @unsupported="onTurnstileUnsupported"
                />
              </div>

              <!-- Inline error feedback -->
              <v-alert
                v-if="errorMessage"
                type="error"
                variant="tonal"
                density="compact"
                closable
                class="mb-4"
                role="alert"
                data-testid="form-error"
                @click:close="errorMessage = ''"
              >
                {{ errorMessage }}
              </v-alert>

              <!-- Captcha loading hint -->
              <p
                v-if="!turnstileToken && !loading"
                class="text-caption text-medium-emphasis text-center mb-2"
                aria-live="polite"
              >
                <v-icon
                  size="small"
                  icon="mdi-shield-refresh"
                />
                Verificando segurança…
              </p>

              <!-- Submit Button -->
              <v-btn
                type="submit"
                :loading="loading"
                :disabled="loading"
                color="success"
                size="x-large"
                block
                rounded="lg"
                elevation="2"
                aria-label="Enviar cobrança"
              >
                <v-icon
                  start
                  icon="mdi-send"
                />
                Cobrar!
              </v-btn>

              <!-- Payment link CTA -->
              <router-link
                to="/criar"
                class="text-body-2 d-block text-center mt-4 payment-link-cta"
                data-testid="create-payment-link"
              >
                ou crie um link de cobrança compartilhável (PIX) →
              </router-link>
            </v-form>
          </v-card-text>
        </v-card>
      </v-col>
    </v-row>

    <!-- Response Dialog -->
    <v-dialog
      v-model="dialog"
      max-width="450"
      persistent
    >
      <v-card rounded="xl">
        <v-card-title class="text-h5 text-success font-weight-bold">
          Me pague o que dev!
        </v-card-title>

        <v-card-text class="text-body-1 py-4" style="white-space: pre-line;">
          {{ responseMessage }}
        </v-card-text>

        <v-card-actions class="px-6 pb-6">
          <v-spacer />
          <v-btn
            color="success"
            variant="elevated"
            @click="closeDialog"
          >
            Entendido
          </v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>
  </v-container>
</template>

<script>
import { ref, watch } from 'vue'
import VueTurnstile from 'vue-turnstile'
import axios from 'axios'
import Logo from './Logo.vue'
import moneyTransfer from '@/assets/money_transfer_.svg'

export default {
  name: 'Index',

  components: {
    Logo,
    VueTurnstile
  },

  setup() {
    // Refs
    const formRef = ref(null)
    const turnstileWidget = ref(null)
    const isValid = ref(false)
    const loading = ref(false)
    const dialog = ref(false)
    const responseMessage = ref('')
    const selectedShipmentType = ref('email')
    const turnstileToken = ref('')
    const turnstileSiteKey = import.meta.env.VITE_TURNSTILE_SITE_KEY

    const message = ref({
      text: '',
      value: '',
      token: '',
      destination: ''
    })

    const errorMessage = ref('')

    const resetTurnstile = () => {
      turnstileToken.value = ''
      if (turnstileWidget.value?.reset) {
        turnstileWidget.value.reset()
      }
    }

    const clearForm = () => {
      message.value.text = ''
      message.value.value = ''
      message.value.destination = ''
      formRef.value?.resetValidation?.()
    }

    // Watch for shipment type changes and clear destination
    watch(selectedShipmentType, () => {
      message.value.destination = ''
    })

    // Validation Rules
    const rules = {
      text: [
        v => !!v || 'Mensagem é obrigatória',
        v => (v && v.length >= 10) || 'Mensagem deve ter pelo menos 10 caracteres',
        v => (v && v.length <= 500) || 'Mensagem deve ter no máximo 500 caracteres'
      ],
      value: [
        v => !!v || 'Valor é obrigatório',
        v => /^\d+(\.\d{1,2})?$/.test(v) || 'Valor deve ser um número válido (ex: 100.00)'
      ],
      email: [
        v => !!v || 'Email é obrigatório',
        v => /.+@.+\..+/.test(v) || 'Email deve ser válido'
      ],
      whatsapp: [
        v => !!v || 'Número de WhatsApp é obrigatório',
        v => (v && v.length >= 10) || 'Número deve ter pelo menos 10 dígitos'
      ]
    }

    // Methods
    const sendEmail = async (token) => {
      message.value.token = token
      loading.value = true
      errorMessage.value = ''

      try {
        const result = await axios.post(
          import.meta.env.VITE_LAMBDA_HOST,
          message.value
        )

        if (typeof result.data === 'string') {
          responseMessage.value = result.data
        } else if (result.data?.message) {
          responseMessage.value = result.data.message
        } else {
          responseMessage.value = 'Email enviado com sucesso! 💸'
        }

        dialog.value = true
        clearForm()
      } catch (error) {
        console.error('Email send error:', error)

        if (error.response?.status === 401) {
          const details = error.response?.data?.details || ''
          errorMessage.value = details.includes('expired') || details.includes('invalid')
            ? 'Verificação de segurança expirou. Tente novamente.'
            : `Verificação falhou: ${details}`
        } else if (error.response?.data?.message) {
          errorMessage.value = error.response.data.message
        } else if (error.response?.data?.error) {
          errorMessage.value = error.response.data.error
        } else if (typeof error.response?.data === 'string') {
          errorMessage.value = error.response.data
        } else if (error.message) {
          errorMessage.value = `Erro: ${error.message}`
        } else {
          errorMessage.value = 'Erro ao enviar email. Verifique sua conexão e tente novamente.'
        }
      } finally {
        loading.value = false
        resetTurnstile()
      }
    }

    const sendWhatsapp = async (token) => {
      message.value.token = token
      loading.value = true
      errorMessage.value = ''

      try {
        const fetchGif = await axios.get(
          `${import.meta.env.VITE_GIPHY_URL}/random`,
          {
            params: {
              api_key: import.meta.env.VITE_GIPHY_API_KEY,
              tag: 'money',
              rating: 'g'
            }
          }
        )

        const gifUrl = fetchGif.data?.data?.url || ''
        const gifTitle = fetchGif.data?.data?.title || ''
        const content = `${message.value.text}\n\nValor: R$ ${message.value.value}\n\n${gifTitle}\n${gifUrl}`

        const phoneNumber = message.value.destination ? message.value.destination.replace(/\D/g, '') : ''
        const target = phoneNumber
          ? `https://wa.me/${phoneNumber}?text=${encodeURIComponent(content)}`
          : `https://wa.me/?text=${encodeURIComponent(content)}`

        const recipient = message.value.destination
        window.open(target, '_blank')

        responseMessage.value = phoneNumber
          ? `Mensagem enviada para WhatsApp! 💬\nAbrindo conversa com ${recipient}`
          : 'Mensagem preparada para WhatsApp! 💬\nSelecione o contato para enviar.'

        dialog.value = true
        clearForm()
      } catch (error) {
        console.error('WhatsApp send error:', error)

        if (error.response?.status === 404) {
          errorMessage.value = 'Não foi possível encontrar um GIF. Tente novamente.'
        } else if (error.message) {
          errorMessage.value = `Erro ao preparar mensagem: ${error.message}`
        } else {
          errorMessage.value = 'Erro ao preparar mensagem para WhatsApp. Tente novamente.'
        }
      } finally {
        loading.value = false
        resetTurnstile()
      }
    }

    const handleRecaptcha = async () => {
      if (loading.value) {
        return
      }

      errorMessage.value = ''

      const { valid } = await formRef.value.validate()
      if (!valid) {
        errorMessage.value = 'Confira os campos destacados acima.'
        return
      }

      if (!turnstileToken.value) {
        errorMessage.value = 'Aguarde a verificação de segurança terminar e tente de novo.'
        return
      }

      const tokenToUse = turnstileToken.value
      turnstileToken.value = ''

      try {
        if (selectedShipmentType.value === 'email') {
          await sendEmail(tokenToUse)
        } else if (selectedShipmentType.value === 'whatsapp') {
          await sendWhatsapp(tokenToUse)
        }
      } catch (error) {
        console.error('Submission error:', error)
        errorMessage.value = 'Erro ao processar sua solicitação. Tente novamente.'
        loading.value = false
        resetTurnstile()
      }
    }

    const closeDialog = () => {
      dialog.value = false
      responseMessage.value = ''
    }

    // Turnstile event handlers
    const onTurnstileUpdate = (token) => {
      turnstileToken.value = token
    }

    const onTurnstileError = (errorCode) => {
      console.error('Turnstile error:', errorCode)
      errorMessage.value = 'Erro na verificação de segurança. Recarregue a página.'
    }

    const onTurnstileExpired = () => {
      turnstileToken.value = ''
    }

    const onTurnstileUnsupported = () => {
      console.error('Turnstile not supported')
      errorMessage.value = 'Seu navegador não suporta a verificação de segurança.'
    }

    return {
      // Refs
      formRef,
      turnstileWidget,
      isValid,
      loading,
      dialog,
      responseMessage,
      errorMessage,
      selectedShipmentType,
      message,
      moneyTransfer,
      turnstileSiteKey,
      turnstileToken,

      // Validation
      rules,

      // Methods
      handleRecaptcha,
      closeDialog,
      onTurnstileUpdate,
      onTurnstileError,
      onTurnstileExpired,
      onTurnstileUnsupported
    }
  }
}
</script>

<style scoped lang="scss">
@use '@/styles/design-tokens' as *;

.form-card {
  background: rgba(255, 255, 255, 0.95);
  backdrop-filter: blur(10px);
  border: 1px solid rgba(255, 255, 255, 0.2);
  transition: transform $transition-duration-base $transition-timing-ease-out,
              box-shadow $transition-duration-base $transition-timing-ease-out;

  &:hover {
    transform: translateY(-4px);
    box-shadow: $shadow-lg !important;
  }
}

// Smooth transitions for form elements
:deep(.v-field) {
  transition: all $transition-duration-base $transition-timing-ease-in-out;
}

:deep(.v-chip) {
  transition: all $transition-duration-base $transition-timing-ease-in-out;

  &:hover {
    transform: translateY(-2px);
  }
}

// Button hover effect
:deep(.v-btn) {
  transition: all $transition-duration-base $transition-timing-ease-in-out;

  &:not(:disabled):hover {
    transform: translateY(-2px);
    box-shadow: $shadow-md;
  }
}

// Loading state
.v-btn--loading {
  pointer-events: none;
}

// Remove outline on input focus - Vuetify handles focus styling
:deep(.v-field__input),
:deep(.v-field__field),
:deep(input),
:deep(textarea) {
  &:focus,
  &:focus-visible {
    outline: none !important;
  }
}

// Enhance focus state with border color change instead
:deep(.v-field--focused) {
  .v-field__outline {
    --v-field-border-width: 2px;
  }
}
</style>
