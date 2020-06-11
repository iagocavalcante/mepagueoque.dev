<template>
  <v-container>
    <v-row class="text-center d-flex align-center">
      <v-col cols="12">
        <v-img :src="require('../assets/logo.png')" class="my-5" contain height="100" />
      </v-col>
      <v-col cols="6" class="mb-4">
        <v-img :src="require('../assets/money_transfer_.svg')" class="my-5" contain height="400" />
      </v-col>
      <v-col cols="6" class="mb-4">
        <v-textarea color="green" label="Escreva uma mensagem para x caloteirx" class="ma-1" outlined="" v-model="message.text" clearable></v-textarea>
        <v-text-field color="green" prefix="R$" label="Qual o valor do golpe?" class="ma-1" outlined="" v-model="message.value" clearable></v-text-field>
        <v-text-field color="green" label="Para qual email você deseja enviar?" class="ma-1" outlined="" v-model="message.email" clearable></v-text-field>
        <v-btn x-large color="success" dark>Cobrar!</v-btn>
      </v-col>
    </v-row>
  </v-container>
</template>

<script>
export default {
  name: 'HelloWorld',

  data: () => ({
    message: {
      text: 'Nossa dívida está completando 1 mês! Você está convidado a pagar.',
      value: '100.00',
      email: 'teste@gmail.com'
    }
  }),
}
</script>
