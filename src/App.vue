<template>
  <v-app>
    <v-content class="my-content">
      <Index />
    </v-content>
<<<<<<< HEAD
    <v-content class="mt-5">
=======
    <v-content class="mt-5 pt-5">
>>>>>>> bdcf2f2350992a3f61dfe55c377e118bf6a7fed4
      <Content />
    </v-content>
    <Footer />
  </v-app>
</template>

<script>
import Index from './components/Index';
import Content from './components/Content';
import Footer from './components/Footer';

export default {
  name: 'App',

  components: {
    Index,
    Content,
    Footer
  },

  data: () => ({
    //
  }),
};
</script>
<style lang="sass">
@import url("~@/assets/css/fonts.scss")

.my-content
  background-color: #f5f5f5
  background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='100%25' height='100%25' viewBox='0 0 2 1'%3E%3Cdefs%3E%3ClinearGradient id='a' gradientUnits='userSpaceOnUse' x1='0' x2='0' y1='0' y2='1'%3E%3Cstop offset='0' stop-color='%23f5f5f5'/%3E%3Cstop offset='1' stop-color='%23e3e1de'/%3E%3C/linearGradient%3E%3ClinearGradient id='b' gradientUnits='userSpaceOnUse' x1='0' y1='0' x2='0' y2='1'%3E%3Cstop offset='0' stop-color='%23ffffff' stop-opacity='0'/%3E%3Cstop offset='1' stop-color='%23ffffff' stop-opacity='1'/%3E%3C/linearGradient%3E%3ClinearGradient id='c' gradientUnits='userSpaceOnUse' x1='0' y1='0' x2='2' y2='2'%3E%3Cstop offset='0' stop-color='%23ffffff' stop-opacity='0'/%3E%3Cstop offset='1' stop-color='%23ffffff' stop-opacity='1'/%3E%3C/linearGradient%3E%3C/defs%3E%3Crect x='0' y='0' fill='url(%23a)' width='2' height='1'/%3E%3Cg fill-opacity='0.5'%3E%3Cpolygon fill='url(%23b)' points='0 1 0 0 2 0'/%3E%3Cpolygon fill='url(%23c)' points='2 1 2 0 0 0'/%3E%3C/g%3E%3C/svg%3E")
  background-attachment: fixed
  background-size: cover

</style>
