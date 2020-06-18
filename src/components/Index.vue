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
        <v-textarea color="green" label="Escreva uma mensagem para o(a) caloteiro(a)" class="ma-1" outlined="" v-model="message.text" clearable></v-textarea>
        <v-text-field color="green" prefix="R$" label="Qual o valor do golpe?" class="ma-1" outlined="" v-model="message.value" clearable></v-text-field>
        <v-text-field color="green" label="Para qual email você deseja enviar?" class="ma-1" outlined="" v-model="message.email" clearable></v-text-field>
        <v-btn :loading="loading" x-large color="success" dark @click="recaptcha">Cobrar!</v-btn>
      </v-col>
    </v-row>
    <v-row justify="center">
      <v-dialog
        v-model="dialog"
        max-width="290"
      >
        <v-card>
          <v-card-title class="headline">Me pague o que dev!</v-card-title>

          <v-card-text>
            {{responseMessage}}
          </v-card-text>

          <v-card-actions>
            <v-spacer></v-spacer>
            <v-btn
              color="green darken-1"
              text
              @click="dialog = false"
            >
              Ok
            </v-btn>
          </v-card-actions>
        </v-card>
      </v-dialog>
    </v-row>
  </v-container>
</template>

<script>
import axios from 'axios'
export default {
  name: 'HelloWorld',

  data: () => ({
    message: {
      text: 'Nossa dívida está completando 1 mês! Você está convidado a pagar.',
      value: '100.00',
      email: 'teste@gmail.com',
      token: ''
    },
    dialog: false,
    responseMessage: '',
    loading: false
  }),
  methods: {
    async sendEmail (token) {
      this.message.token = token
      this.loading = true
      try {
        const result = await axios.post(process.env.VUE_APP_LAMBDA_HOST, this.message)
        this.responseMessage = result.data
        this.dialog = true
        this.loading = false
      } catch (error) {
        this.dialog = true
        this.loading = false
        this.responseMessage = error
      }
    },
    async recaptcha() {
      await this.$recaptchaLoaded()

      const token = await this.$recaptcha('login')

      this.sendEmail(token)
    }
  },
}
</script>
