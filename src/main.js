import Vue from 'vue'
import App from './App.vue'
import vuetify from './plugins/vuetify';
import firebase from 'firebase';
import Ads from 'vue-google-adsense';

var firebaseConfig = {
  apiKey: process.env.VUE_APP_FIREBASE_API_KEY,
  authDomain:  process.env.VUE_APP_FIREBASE_AUTH_DOMAIN,
  databaseURL: process.env.VUE_APP_FIREBASE_DATABASE_URL,
  projectId: process.env.VUE_APP_FIREBASE_PROJECT_ID,
  storageBucket:  process.env.VUE_APP_FIREBASE_STORAGE_BUCKET,
  messagingSenderId: process.env.VUE_APP_FIREBASE_MESSAGING_SEDNER_ID ,
  appId:  process.env.VUE_APP_FIREBASE_APP_ID,
  measurementId: process.env.VUE_APP_FIREBASE_MEASUREMENT_ID,
};
// Initialize Firebase
firebase.initializeApp(firebaseConfig);
firebase.analytics();

Vue.use(require('vue-script2'))
 
Vue.use(Ads.Adsense)
Vue.config.productionTip = false

import { VueReCaptcha } from 'vue-recaptcha-v3'
 
// For more options see below
Vue.use(VueReCaptcha, { siteKey: process.env.VUE_APP_RECAPTCH_KEY })

new Vue({
  vuetify,
  render: h => h(App)
}).$mount('#app')
