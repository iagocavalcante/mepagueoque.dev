<template>
  <v-container>
    <v-row class="text-center d-flex align-center">
      <v-col cols="12">
        <v-img
          :src="require('../assets/money_transfer_.svg')"
          contain
          height="100"
          class="d-md-none d-lg-none"
        />
        <Logo />
      </v-col>
      <v-col
        cols="12"
        xs="12"
        sm="12"
        md="6"
        lg="6"
        xl="6"
        class="d-none d-md-inline"
      >
        <v-img :src="require('../assets/money_transfer_.svg')" contain height="400" />
      </v-col>
      <v-col cols="12" xs="12" sm="12" md="6" lg="6" xl="6">
        <v-form ref="form"
          v-model="valid"
          :lazy-validation="true"
        >
          <v-textarea
            color="green"
            label="Escreva uma mensagem para o(a) caloteiro(a)"
            class="ma-1"
            outlined
            v-model="message.text"
            clearable
            required
            :rules="rules.text"
          ></v-textarea>
          <v-text-field
            color="green"
            prefix="R$"
            label="Qual o valor do golpe?"
            class="ma-1"
            outlined
            v-model="message.value"
            clearable
            required
            :rules="rules.value"
          ></v-text-field>
          <ToggleInputs @verifyInputType="inputType" v-model="message.destination" />
          <v-btn :loading="loading" :disabled="!valid" x-large color="success" dark @click="recaptcha()">Cobrar!</v-btn>
        </v-form>
      </v-col>
    </v-row>
    <v-row justify="center">
      <v-dialog v-model="dialog" max-width="290">
        <v-card>
          <v-card-title class="headline">Me pague o que dev!</v-card-title>

          <v-card-text>{{responseMessage}}</v-card-text>

          <v-card-actions>
            <v-spacer></v-spacer>
            <v-btn color="green darken-1" text @click="dialog = false">Ok</v-btn>
          </v-card-actions>
        </v-card>
      </v-dialog>
    </v-row>
  </v-container>
</template>

<script>
import axios from 'axios'
import Logo from './Logo'
import ToggleInputs from './ToggleInputs'

export default {
  name: 'Index',
  components: {
    Logo,
    ToggleInputs
  },
  data: () => ({
    valid: false,
    message: {
      text: 'Nossa dívida está completando 1 mês! Você está convidado a pagar.',
      value: '100.00',
      token: '',
      destination: ''
    },
    rules: {
      value: [
        v => !!v || 'Valor obrigatório'
      ],
      text: [
        v => !!v || 'Mensagem é obrigatória',
      ]
    },
    type: 'email',
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
    inputType (type) {
      this.type = type
      console.log(this.type)
    },
    async sendWhatsapp (token) {
      this.message.token = token
      this.loading = true
      const fetchGif = await axios.get(
        `${process.env.VUE_APP_GIPHY_URL}/random`,
        {
          params: {
            api_key: process.env.VUE_APP_GIPHY_API_KEY,
            tag: 'money',
            rating: 'g'
          }
        }
      );
      let content = `${this.message.text} \nValor: ${this.message.value} \n${fetchGif.data.title}`
      let target = `https://api.whatsapp.com/send?`;
      target += `phone=${encodeURIComponent(this.message.destination)}&`;
      target += `text=${encodeURIComponent(content)}`
      window.open(target, "_blank");  
      this.loading = false
    },
    async recaptcha () {
      const isValid = this.$refs.form.validate()
      if (isValid) {
        await this.$recaptchaLoaded()
  
        const token = await this.$recaptcha('login')

        if (this.type === 'email') {
          this.sendEmail(token)
        }

        if (this.type === 'whatsapp') {
          this.sendWhatsapp(token)
        }
      }
    }
  },
}
</script>

<style>
.theme--dark.v-btn.v-btn--disabled:not(.v-btn--flat):not(.v-btn--text):not(.v-btn--outlined) {
  background-color: rgba(5, 128, 11, 0.288) !important;
}
.theme--dark.v-btn.v-btn--disabled {
  color: rgba(255, 255, 255, 0.589) !important;
}
</style>
