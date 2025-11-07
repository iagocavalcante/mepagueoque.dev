<template>
  <v-footer
    class="footer"
    color="surface-variant"
    role="contentinfo"
    aria-label="Rodapé do site"
  >
    <v-container>
      <v-row class="align-center justify-center">
        <!-- Copyright and Authors -->
        <v-col
          cols="12"
          md="6"
          class="text-center text-md-left"
        >
          <div class="footer-content">
            <p class="authors mb-2">
              <strong>{{ authorsFormatted }}</strong>
            </p>
            <p class="copyright mb-0">
              Copyright &copy; {{ currentYear }} MePagueOQue.Dev
            </p>
          </div>
        </v-col>

        <!-- Version and Social Links -->
        <v-col
          cols="12"
          md="6"
          class="text-center text-md-right"
        >
          <div class="footer-meta">
            <v-chip
              variant="outlined"
              color="success"
              size="small"
              prepend-icon="mdi-information-outline"
              class="mb-2"
            >
              Versão {{ version }}
            </v-chip>

            <div class="social-links mt-2">
              <v-btn
                icon
                variant="text"
                size="small"
                href="https://github.com/IagoCavalcante/mepagueoque.dev"
                target="_blank"
                rel="noopener noreferrer"
                aria-label="Visite nosso GitHub"
              >
                <v-icon icon="mdi-github" />
              </v-btn>
            </div>
          </div>
        </v-col>

        <!-- Disclaimer -->
        <v-col cols="12" class="mt-4">
          <v-divider class="mb-4" />
          <p class="disclaimer text-center">
            Este site é uma ferramenta humorística para cobrar dívidas de forma sutil.
            Use com responsabilidade e bom senso.
          </p>
        </v-col>
      </v-row>
    </v-container>
  </v-footer>
</template>

<script>
import { ref, computed } from 'vue'
import packageInfo from '../../package.json'

export default {
  name: 'Footer',

  setup() {
    const authors = ref([
      'Iago Cavalcante',
      'Bianca Silva',
      'Thayana Mamore'
    ])

    const currentYear = ref(new Date().getFullYear())

    const version = ref(packageInfo.version || '1.1.0')

    const authorsFormatted = computed(() => {
      return authors.value.join(', ')
    })

    return {
      authors,
      currentYear,
      version,
      authorsFormatted
    }
  }
}
</script>

<style scoped lang="scss">
@use '@/styles/design-tokens' as *;

.footer {
  padding: $spacing-8 0;
  background: linear-gradient(180deg, $color-neutral-50 0%, $color-neutral-100 100%);
  border-top: 1px solid $color-border-light;
  margin-top: $spacing-16;

  @media (min-width: $breakpoint-md) {
    padding: $spacing-10 0;
  }
}

.footer-content {
  .authors {
    font-size: $font-size-base;
    font-weight: $font-weight-medium;
    color: $color-text-primary;
    line-height: $line-height-normal;

    strong {
      color: $color-success-main;
    }
  }

  .copyright {
    font-size: $font-size-sm;
    color: $color-text-secondary;
    line-height: $line-height-normal;
  }
}

.footer-meta {
  display: flex;
  flex-direction: column;
  align-items: center;

  @media (min-width: $breakpoint-md) {
    align-items: flex-end;
  }
}

.social-links {
  display: flex;
  gap: $spacing-2;
  align-items: center;
  justify-content: center;

  @media (min-width: $breakpoint-md) {
    justify-content: flex-end;
  }

  :deep(.v-btn) {
    transition: all $transition-duration-base $transition-timing-ease-in-out;

    &:hover {
      transform: translateY(-2px);
      color: $color-success-main;
    }
  }
}

.disclaimer {
  font-size: $font-size-xs;
  color: $color-text-disabled;
  line-height: $line-height-relaxed;
  max-width: 800px;
  margin: 0 auto;
}

// Accessibility improvements
:deep(.v-divider) {
  opacity: 0.3;
}

// Chip styling
:deep(.v-chip) {
  font-weight: $font-weight-medium;
  transition: all $transition-duration-base $transition-timing-ease-in-out;

  &:hover {
    transform: scale(1.05);
  }
}

// Dark mode support
@media (prefers-color-scheme: dark) {
  .footer {
    background: linear-gradient(180deg, $color-neutral-900 0%, $color-neutral-950 100%);
    border-top-color: $color-border-dark;
  }

  .footer-content {
    .authors {
      color: $color-neutral-100;

      strong {
        color: $color-success-light;
      }
    }

    .copyright {
      color: $color-neutral-400;
    }
  }

  .disclaimer {
    color: $color-neutral-500;
  }
}

// Print styles
@media print {
  .footer {
    background: transparent;
    border-top: 1px solid #000;
    padding: $spacing-4 0;
  }

  .social-links {
    display: none;
  }
}
</style>
