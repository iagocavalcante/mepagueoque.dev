<template>
  <v-footer>
    <v-col
      class="text-center"
      cols="12"
    >
      <strong>{{authorsFormated}} </strong> &copy; MePagueOQue.Dev - {{ new Date().getFullYear() }}
      <p><strong>Versão - {{version}} </strong></p>
    </v-col>
  </v-footer>
</template>

<script>
export default {
  name: 'Footer',
  data: () => ({
    version: JSON.parse(unescape(process.env.PACKAGE_JSON || '%7B%7D')).version,
    authors: [
      'Iago Cavalcante',
      'Bianca Silva',
      'Thayana Mamore'
    ]
  }),
  computed: {
    authorsFormated () {
      return this.authors.map(author => author).join(', ')
    }
  }
}
</script>