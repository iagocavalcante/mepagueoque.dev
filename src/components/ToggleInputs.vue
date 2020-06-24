<template>
  <v-row
    align="center"
    justify="center"
  >
    <v-col cols="12">
      <p class="text-center">Escolha uma opção de envio:</p>
    </v-col>
    <v-btn-toggle
      v-model="toggle_exclusive"
      one
      group
      color="green darken-1"
    >
      <v-btn 
        v-for="shipment of shipments"
        :key="shipment"
        :value="`${shipment}`"
      >
        <v-icon> {{`mdi-${shipment}`}} </v-icon>
        <span> {{shipment}} </span>
      </v-btn>
    </v-btn-toggle>

    <v-col
      cols="12"
      class="text-center"
    >
      <template v-if="verifyInputType() === 'email'">
        <v-text-field
          color="green"
          label="Para qual email você deseja enviar?"
          prepend-icon="mdi-email"
          class="ma-1"
          :value="value"
          @input="update"
          outlined
          clearable
          :rules="ruleEmail"
        ></v-text-field>
      </template>
      <template v-if="verifyInputType() === 'whatsapp'">
        <v-text-field
          color="green"
          prepend-icon="mdi-whatsapp"
          label="Para qual número de whatsapp você deseja enviar?"
          class="ma-1"
          :value="value"
          @input="update"
          outlined
          clearable
          :rules="ruleWhatsapp"
        ></v-text-field>
      </template>
      <!-- <template v-if="toggle_exclusive.includes('telegram')">
        <v-text-field
          color="green"
          label="Para qual conta de telegram você deseja enviar?"
          prepend-icon="mdi-telegram"
          class="ma-1"
          :value="value"
          @input="update"
          outlined
          clearable
        ></v-text-field>
      </template> -->
    </v-col>
  </v-row>
</template>

<script>
export default {
  name: 'Toggle',
  props: ["value"],
  data: () => ({
    toggle_exclusive: 'email',
    shipments: ['email', 'whatsapp'], // , 'telegram'],
    tMessage: false,
    ruleEmail: [
      v => !!v || 'Campo e-mail obrigatório',
      v => /.+@.+\..+/.test(v) || 'E-mail must be valid',
    ],
    ruleWhatsapp: [
      v => !!v || 'Campo número de whatsapp'
    ]
  }),
  methods: {
    update(newValue) {
      this.$emit('input', newValue);
    },
    verifyInputType () {
      if (this.toggle_exclusive.includes('email')) {
        this.$emit('verifyInputType', 'email')
        return 'email'
      }
      
      if (this.toggle_exclusive.includes('whatsapp')) {
        this.$emit('verifyInputType', 'whatsapp')
        return 'whatsapp'
      }
    }
  }
}
</script>
