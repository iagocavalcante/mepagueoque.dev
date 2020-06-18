import Vue from 'vue'
import App from './App.vue'
import vuetify from './plugins/vuetify';

Vue.config.productionTip = false

import { VueReCaptcha } from 'vue-recaptcha-v3'
 
// For more options see below
Vue.use(VueReCaptcha, { siteKey: process.env.VUE_APP_RECAPTCH_KEY })

new Vue({
  vuetify,
  render: h => h(App)
}).$mount('#app')
