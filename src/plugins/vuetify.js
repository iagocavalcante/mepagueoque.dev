/**
 * Vuetify 3 Plugin Configuration
 * Modern design system with Material Design 3 components
 * WCAG AA accessibility compliant color palette
 */

import 'vuetify/styles'
import { createVuetify } from 'vuetify'
import * as components from 'vuetify/components'
import * as directives from 'vuetify/directives'
import { aliases, mdi } from 'vuetify/iconsets/mdi'
import '@mdi/font/css/materialdesignicons.css'

// Design tokens
const colors = {
  primary: {
    lighten5: '#e8f5e9',
    lighten4: '#c8e6c9',
    lighten3: '#a5d6a7',
    lighten2: '#81c784',
    lighten1: '#66bb6a',
    base: '#4caf50',
    darken1: '#43a047',
    darken2: '#388e3c',
    darken3: '#2e7d32',
    darken4: '#1b5e20',
  },
  success: {
    lighten1: '#1fc259',
    base: '#4caf50',
    darken1: '#388e3c',
  },
  error: {
    lighten1: '#ef5350',
    base: '#d32f2f',
    darken1: '#c62828',
  },
  warning: {
    lighten1: '#ff9800',
    base: '#f57c00',
    darken1: '#e65100',
  },
  info: {
    lighten1: '#03a9f4',
    base: '#0288d1',
    darken1: '#01579b',
  },
  neutral: {
    white: '#ffffff',
    50: '#fafafa',
    100: '#f5f5f5',
    200: '#eeeeee',
    300: '#e0e0e0',
    400: '#bdbdbd',
    500: '#9e9e9e',
    600: '#757575',
    700: '#616161',
    800: '#424242',
    900: '#2d2b33',
    950: '#212121',
  },
}

// Theme configuration
const lightTheme = {
  dark: false,
  colors: {
    primary: colors.primary.base,
    'primary-lighten-1': colors.primary.lighten1,
    'primary-lighten-2': colors.primary.lighten2,
    'primary-darken-1': colors.primary.darken1,
    'primary-darken-2': colors.primary.darken2,

    success: colors.success.base,
    'success-lighten-1': colors.success.lighten1,
    'success-darken-1': colors.success.darken1,

    error: colors.error.base,
    'error-lighten-1': colors.error.lighten1,
    'error-darken-1': colors.error.darken1,

    warning: colors.warning.base,
    'warning-lighten-1': colors.warning.lighten1,
    'warning-darken-1': colors.warning.darken1,

    info: colors.info.base,
    'info-lighten-1': colors.info.lighten1,
    'info-darken-1': colors.info.darken1,

    background: colors.neutral.white,
    surface: colors.neutral.white,
    'surface-variant': colors.neutral[100],
    'on-surface': colors.neutral[900],
    'on-surface-variant': colors.neutral[700],

    // Additional semantic colors
    'text-primary': colors.neutral[900],
    'text-secondary': colors.neutral[700],
    'text-disabled': colors.neutral[500],
  },
}

const darkTheme = {
  dark: true,
  colors: {
    primary: colors.primary.lighten2,
    'primary-lighten-1': colors.primary.lighten3,
    'primary-lighten-2': colors.primary.lighten4,
    'primary-darken-1': colors.primary.base,
    'primary-darken-2': colors.primary.darken1,

    success: colors.success.lighten1,
    error: colors.error.lighten1,
    warning: colors.warning.lighten1,
    info: colors.info.lighten1,

    background: colors.neutral[950],
    surface: colors.neutral[900],
    'surface-variant': colors.neutral[800],
    'on-surface': colors.neutral[100],
    'on-surface-variant': colors.neutral[400],
  },
}

export default createVuetify({
  components,
  directives,

  icons: {
    defaultSet: 'mdi',
    aliases,
    sets: {
      mdi,
    },
  },

  theme: {
    defaultTheme: 'light',
    themes: {
      light: lightTheme,
      dark: darkTheme,
    },
    variations: {
      colors: ['primary', 'success', 'error', 'warning', 'info'],
      lighten: 5,
      darken: 5,
    },
  },

  defaults: {
    VBtn: {
      style: [{ textTransform: 'none' }],
      rounded: 'lg',
      elevation: 0,
    },
    VCard: {
      rounded: 'lg',
      elevation: 2,
    },
    VTextField: {
      variant: 'outlined',
      color: 'primary',
      rounded: 'lg',
    },
    VTextarea: {
      variant: 'outlined',
      color: 'primary',
      rounded: 'lg',
    },
    VChip: {
      rounded: 'lg',
    },
    VDialog: {
      rounded: 'xl',
    },
  },

  // Display configuration
  display: {
    mobileBreakpoint: 'sm',
    thresholds: {
      xs: 0,
      sm: 600,
      md: 960,
      lg: 1264,
      xl: 1904,
    },
  },
})
