<template>
  <v-app>
    <!-- Main hero section with gradient background -->
    <v-main class="hero-section">
      <Index />
    </v-main>

    <!-- Content section -->
    <v-main class="content-section">
      <Content />
    </v-main>

    <!-- Footer -->
    <Footer />
  </v-app>
</template>

<script>
import Index from './components/Index.vue'
import Content from './components/Content.vue'
import Footer from './components/Footer.vue'

export default {
  name: 'App',

  components: {
    Index,
    Content,
    Footer
  },
}
</script>

<style lang="scss">
@use '@/styles/design-tokens' as *;
@import url("@/assets/css/fonts.scss");

// Global styles
* {
  box-sizing: border-box;
}

// Hero section with gradient background
.hero-section {
  background-color: $color-background-gradient-start;
  background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='100%25' height='100%25' viewBox='0 0 2 1'%3E%3Cdefs%3E%3ClinearGradient id='a' gradientUnits='userSpaceOnUse' x1='0' x2='0' y1='0' y2='1'%3E%3Cstop offset='0' stop-color='%23f5f5f5'/%3E%3Cstop offset='1' stop-color='%23e3e1de'/%3E%3C/linearGradient%3E%3ClinearGradient id='b' gradientUnits='userSpaceOnUse' x1='0' y1='0' x2='0' y2='1'%3E%3Cstop offset='0' stop-color='%23ffffff' stop-opacity='0'/%3E%3Cstop offset='1' stop-color='%23ffffff' stop-opacity='1'/%3E%3C/linearGradient%3E%3ClinearGradient id='c' gradientUnits='userSpaceOnUse' x1='0' y1='0' x2='2' y2='2'%3E%3Cstop offset='0' stop-color='%23ffffff' stop-opacity='0'/%3E%3Cstop offset='1' stop-color='%23ffffff' stop-opacity='1'/%3E%3C/linearGradient%3E%3C/defs%3E%3Crect x='0' y='0' fill='url(%23a)' width='2' height='1'/%3E%3Cg fill-opacity='0.5'%3E%3Cpolygon fill='url(%23b)' points='0 1 0 0 2 0'/%3E%3Cpolygon fill='url(%23c)' points='2 1 2 0 0 0'/%3E%3C/g%3E%3C/svg%3E");
  background-attachment: fixed;
  background-size: cover;
  min-height: 100vh;
}

// Content section
.content-section {
  background-color: $color-background-primary;
  padding-top: $spacing-16;
  padding-bottom: $spacing-16;
}

// Global accessibility improvements
.v-application {
  font-family: $font-family-primary;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}

// Focus visible for keyboard navigation (only for buttons and links, not inputs)
button:focus-visible,
a:focus-visible,
.v-btn:focus-visible {
  outline: 2px solid $color-primary-500;
  outline-offset: 2px;
}

// Remove outline from all input fields
input:focus,
input:focus-visible,
textarea:focus,
textarea:focus-visible,
.v-field:focus,
.v-field:focus-visible {
  outline: none !important;
}

// Skip to main content link for screen readers
.skip-to-main {
  position: absolute;
  top: -100px;
  left: 0;
  background: $color-primary-500;
  color: $color-text-on-primary;
  padding: $spacing-2 $spacing-4;
  text-decoration: none;
  z-index: $z-index-tooltip;

  &:focus {
    top: 0;
  }
}
</style>
