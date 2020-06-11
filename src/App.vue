<template>
  <v-app>
    <v-content class="grey lighten-5">
      <Index />
    </v-content>
  </v-app>
</template>

<script>
import Index from './components/Index';

export default {
  name: 'App',

  components: {
    Index,
  },

  data: () => ({
    //
  }),
};
</script>
