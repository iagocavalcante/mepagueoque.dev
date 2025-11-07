<template>
  <div class="logo-container">
    <div class="logo">
      <h1 class="logo-title">
        mepagueoque.dev
      </h1>
      <p class="logo-subtitle">
        (um jeito sutil de cobrar os(as) caloteiros(as))
      </p>
    </div>
  </div>
</template>

<script>
export default {
  name: 'Logo'
}
</script>

<style scoped lang="scss">
@use '@/styles/design-tokens' as *;

.logo-container {
  display: flex;
  justify-content: center;
  align-items: center;
  padding: $spacing-8 $spacing-4;
  min-height: clamp(8rem, 12vw, 16rem);

  @media (min-width: $breakpoint-md) {
    padding: $spacing-12 $spacing-8;
  }
}

.logo {
  width: 100%;
  max-width: 1200px;
  text-align: center;

  @media (min-width: $breakpoint-sm) {
    text-align: right;
  }
}

.logo-title {
  font-family: $font-family-logo;
  font-weight: $font-weight-thin;
  font-size: clamp(2rem, 5.4vw, 5rem);
  color: $color-success-dark;
  line-height: $line-height-tight;
  margin: 0;
  padding: 0;
  letter-spacing: $letter-spacing-tight;

  // Improve readability with text shadow
  text-shadow: 0 2px 4px rgba(0, 0, 0, 0.2);

  // Responsive adjustments
  @media (min-width: $breakpoint-sm) {
    font-size: clamp(2.5rem, 5.4vw, 6rem);
  }

  @media (min-width: $breakpoint-md) {
    font-size: clamp(3rem, 5.4vw, 7rem);
  }

  // Animation on hover
  transition: color $transition-duration-base $transition-timing-ease-in-out,
              transform $transition-duration-base $transition-timing-ease-in-out;

  &:hover {
    color: $color-primary-700;
    transform: scale(1.02);
  }
}

.logo-subtitle {
  font-family: $font-family-subtitle;
  font-size: clamp(0.875rem, 1.4vw, 1.25rem);
  color: $color-text-primary;
  line-height: $line-height-snug;
  margin-top: $spacing-2;
  margin-bottom: 0;
  padding: 0;
  letter-spacing: $letter-spacing-normal;
  text-shadow: 0 1px 2px rgba(255, 255, 255, 0.8);

  // Responsive adjustments
  @media (min-width: $breakpoint-sm) {
    font-size: clamp(1rem, 1.4vw, 1.5rem);
    margin-top: $spacing-3;
  }

  @media (min-width: $breakpoint-md) {
    font-size: clamp(1.125rem, 1.4vw, 1.75rem);
  }

  // Smooth transition
  transition: color $transition-duration-base $transition-timing-ease-in-out;

  &:hover {
    color: $color-neutral-900;
  }
}

// Accessibility: Ensure proper contrast
@media (prefers-contrast: high) {
  .logo-title {
    color: $color-success-dark;
    text-shadow: none;
  }

  .logo-subtitle {
    color: $color-text-primary;
  }
}

// Dark mode support (if implemented)
@media (prefers-color-scheme: dark) {
  .logo-title {
    color: $color-primary-200;
    text-shadow: 0 1px 3px rgba(0, 0, 0, 0.3);
  }

  .logo-subtitle {
    color: $color-neutral-400;
  }
}
</style>
