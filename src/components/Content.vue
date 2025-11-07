<template>
  <v-container>
    <v-row class="align-center justify-center">
      <!-- Section Header -->
      <v-col cols="12" class="mb-8">
        <h2 class="section-title text-center text-md-left">
          Endividamento no Brasil
        </h2>
      </v-col>

      <!-- Stats Cards Row -->
      <v-col cols="12" class="mb-8">
        <v-row>
          <v-col
            v-for="stat in stats"
            :key="stat.title"
            cols="12"
            sm="6"
            md="3"
          >
            <v-card
              class="stat-card text-center"
              rounded="xl"
              elevation="3"
            >
              <v-card-text class="pa-6">
                <v-icon
                  :icon="stat.icon"
                  :color="stat.color"
                  size="48"
                  class="mb-4"
                />
                <div class="stat-value">{{ stat.value }}</div>
                <div class="stat-title">{{ stat.title }}</div>
              </v-card-text>
            </v-card>
          </v-col>
        </v-row>
      </v-col>

      <!-- Content Area -->
      <v-col
        cols="12"
        md="8"
      >
        <article>
          <p class="content-text">
            O endividamento dos brasileiros atingiu recorde em março, informou nesta segunda-feira, 30,
            a Confederação Nacional do Comércio de Bens, Serviços e Turismo (CNC).
          </p>

          <p class="content-text">
            Após ter recuado a 65,1% em fevereiro, o porcentual de famílias com dívidas saltou para 66,2%
            este mês, o maior patamar da série histórica da Pesquisa de Endividamento e Inadimplência do
            Consumidor (Peic), iniciada em janeiro de 2010.
          </p>

          <p class="content-text">
            A inadimplência também subiu e a expectativa da entidade é que aumente por causa do coronavírus.
            De acordo com o levantamento da CNC, o porcentual de famílias com dívidas ou contas em atraso
            chegou a 25,3% em março, contra 24,1% no mês anterior.
          </p>

          <p class="content-text">
            O levantamento considera como dívidas as contas a pagar em cheque pré-datado, cartão de crédito,
            cheque especial, carnê de loja, empréstimo pessoal, prestação de carro e seguro.
          </p>

          <p class="content-text">
            O total de famílias que declararam não ter condições de pagar suas contas ou dívidas em atraso
            e que, portanto, permaneceriam inadimplentes passou de 9,7% em fevereiro para 10,2% em março.
            Os indicadores também registraram aumento no comparativo anual.
          </p>

          <v-btn
            href="https://exame.com/economia/endividamento-no-brasil-bate-recorde-e-deve-aumentar-devido-ao-coronavirus/"
            target="_blank"
            rel="noopener noreferrer"
            color="success"
            variant="outlined"
            size="large"
            prepend-icon="mdi-fire"
            class="mt-6"
            aria-label="Ler artigo completo na Exame"
          >
            Fonte: Exame
          </v-btn>
        </article>
      </v-col>

      <!-- Illustration - Desktop Only -->
      <v-col
        cols="12"
        md="4"
        class="d-none d-md-flex align-center justify-center"
      >
        <v-img
          :src="wallet"
          contain
          :max-height="400"
          alt="Ilustração de carteira"
          class="illustration"
        />
      </v-col>
    </v-row>
  </v-container>
</template>

<script>
import { ref } from 'vue'
import wallet from '@/assets/wallet.svg'

export default {
  name: 'Content',

  setup() {
    const stats = ref([
      {
        title: 'Famílias Endividadas',
        value: '66.2%',
        icon: 'mdi-credit-card-outline',
        color: 'error'
      },
      {
        title: 'Contas em Atraso',
        value: '25.3%',
        icon: 'mdi-clock-alert-outline',
        color: 'warning'
      },
      {
        title: 'Inadimplentes',
        value: '10.2%',
        icon: 'mdi-alert-circle-outline',
        color: 'error'
      },
      {
        title: 'Recorde Histórico',
        value: '2020',
        icon: 'mdi-trending-up',
        color: 'info'
      }
    ])

    return {
      wallet,
      stats
    }
  }
}
</script>

<style scoped lang="scss">
@use '@/styles/design-tokens' as *;

.section-title {
  font-size: $font-size-2xl;
  font-weight: $font-weight-black;
  color: $color-success-dark;
  line-height: $line-height-tight;
  margin-bottom: $spacing-6;

  @media (min-width: $breakpoint-md) {
    text-align: left;
  }
}

// Stats Cards
.stat-card {
  height: 100%;
  background: linear-gradient(135deg, rgba(255, 255, 255, 0.95) 0%, rgba(245, 245, 245, 0.95) 100%);
  border: 1px solid rgba(76, 175, 80, 0.1);
  transition: transform $transition-duration-base $transition-timing-ease-out,
              box-shadow $transition-duration-base $transition-timing-ease-out;

  &:hover {
    transform: translateY(-8px) scale(1.02);
    box-shadow: $shadow-xl !important;
  }
}

.stat-value {
  font-size: $font-size-2xl;
  font-weight: $font-weight-bold;
  color: $color-success-dark;
  margin-bottom: $spacing-2;
  line-height: $line-height-tight;
}

.stat-title {
  font-size: $font-size-sm;
  font-weight: $font-weight-medium;
  color: $color-text-secondary;
  text-transform: uppercase;
  letter-spacing: $letter-spacing-wide;
}

// Content Text
.content-text {
  font-size: $font-size-base;
  line-height: $line-height-relaxed;
  color: $color-success-dark;
  margin-bottom: $spacing-6;
  text-align: justify;
  font-weight: $font-weight-medium;

  &:last-of-type {
    margin-bottom: 0;
  }
}

// Illustration
.illustration {
  filter: drop-shadow($shadow-base);
  transition: transform $transition-duration-slow $transition-timing-ease-out;

  &:hover {
    transform: scale(1.05) rotate(2deg);
  }
}

// Source button
:deep(.v-btn) {
  text-transform: none;
  font-weight: $font-weight-medium;
  letter-spacing: $letter-spacing-normal;
  transition: all $transition-duration-base $transition-timing-ease-in-out;

  &:hover {
    transform: translateY(-2px);
    box-shadow: $shadow-md;
  }
}

// Accessibility
article {
  // Ensure proper focus outline for screen readers
  &:focus-within {
    outline: 2px solid $color-primary-500;
    outline-offset: 4px;
    border-radius: $border-radius-base;
  }
}

// Responsive adjustments
@media (max-width: $breakpoint-md) {
  .section-title {
    font-size: $font-size-xl;
    text-align: center;
  }

  .content-text {
    text-align: left;
  }
}

// Dark mode support
@media (prefers-color-scheme: dark) {
  .stat-card {
    background: linear-gradient(135deg, rgba(66, 66, 66, 0.95) 0%, rgba(48, 48, 48, 0.95) 100%);
    border-color: rgba(76, 175, 80, 0.2);
  }

  .section-title {
    color: $color-success-light;
  }

  .stat-value {
    color: $color-success-light;
  }

  .stat-title {
    color: $color-neutral-400;
  }

  .content-text {
    color: $color-success-light;
  }
}
</style>
