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

              <!-- Submit Button -->
              <v-btn
                type="submit"
                :loading="loading"
                :disabled="!isValid || loading"
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
            </v-form>
          </v-card-text>
        </v-card>
      </v-col>
    </v-row>

    <!-- Response Dialog -->
    <v-dialog
      v-model="dialog"
      max-width="400"
      persistent
    >
      <v-card rounded="xl">
        <v-card-title class="text-h5 text-success font-weight-bold">
          Me pague o que dev!
        </v-card-title>

        <v-card-text class="text-body-1 py-4">
          {{ responseMessage }}
        </v-card-text>

        <v-card-actions class="px-6 pb-6">
          <v-spacer />
          <v-btn
            color="success"
            variant="elevated"
            @click="closeDialog"
          >
            Ok
          </v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>
  </v-container>
</template>

<script>
import { ref, computed } from 'vue'
import { useReCaptcha } from 'vue-recaptcha-v3'
import axios from 'axios'
import Logo from './Logo.vue'
import moneyTransfer from '@/assets/money_transfer_.svg'

export default {
  name: 'Index',

  components: {
    Logo
  },

  setup() {
    // Refs
    const formRef = ref(null)
    const isValid = ref(false)
    const loading = ref(false)
    const dialog = ref(false)
    const responseMessage = ref('')
    const selectedShipmentType = ref('email')

    const message = ref({
      text: 'Nossa dívida está completando 1 mês! Você está convidado a pagar.',
      value: '100.00',
      token: '',
      destination: ''
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

    // reCAPTCHA
    const { executeRecaptcha, recaptchaLoaded } = useReCaptcha()

    // Methods
    const sendEmail = async (token) => {
      message.value.token = token
      loading.value = true

      try {
        const result = await axios.post(
          import.meta.env.VITE_LAMBDA_HOST,
          message.value
        )
        responseMessage.value = result.data
        dialog.value = true
      } catch (error) {
        responseMessage.value = error.response?.data || 'Erro ao enviar email. Tente novamente.'
        dialog.value = true
      } finally {
        loading.value = false
      }
    }

    const sendWhatsapp = async (token) => {
      message.value.token = token
      loading.value = true

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

        const content = `${message.value.text}\nValor: R$ ${message.value.value}\n${fetchGif.data.data.title || ''}\n${fetchGif.data.data.url || ''}`
        const target = `https://wa.me/?text=${encodeURIComponent(content)}`
        window.open(target, '_blank')

        responseMessage.value = 'Mensagem preparada! Verifique o WhatsApp.'
        dialog.value = true
      } catch (error) {
        responseMessage.value = 'Erro ao preparar mensagem. Tente novamente.'
        dialog.value = true
      } finally {
        loading.value = false
      }
    }

    const handleRecaptcha = async () => {
      // Validate form
      const { valid } = await formRef.value.validate()

      if (!valid) {
        return
      }

      try {
        // Load reCAPTCHA
        await recaptchaLoaded()

        // Execute reCAPTCHA
        const token = await executeRecaptcha('submit')

        // Send based on selected type
        if (selectedShipmentType.value === 'email') {
          await sendEmail(token)
        } else if (selectedShipmentType.value === 'whatsapp') {
          await sendWhatsapp(token)
        }
      } catch (error) {
        responseMessage.value = 'Erro ao validar reCAPTCHA. Tente novamente.'
        dialog.value = true
        loading.value = false
      }
    }

    const closeDialog = () => {
      dialog.value = false
      responseMessage.value = ''
    }

    return {
      // Refs
      formRef,
      isValid,
      loading,
      dialog,
      responseMessage,
      selectedShipmentType,
      message,
      moneyTransfer,

      // Validation
      rules,

      // Methods
      handleRecaptcha,
      closeDialog
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
