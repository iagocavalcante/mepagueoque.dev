<template>
   <v-row
        align="center"
        justify="center"
      >
       <v-col cols="12">
          <p class="text-center">Escolha a opção de envio:</p>
        </v-col>
        <v-btn-toggle
          v-model="toggle_exclusive"
          multiple
          group
          color="green"
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
         <template v-if="toggle_exclusive.includes('email')">
              <v-text-field
                color="green"
                label="Para qual email você deseja enviar?"
                prepend-icon="mdi-email"
                class="ma-1"
                v-model="message.email"
                outlined
                clearable
              ></v-text-field>
          </template>
          <template v-if="toggle_exclusive.includes('whatsapp')">
              <v-text-field
                color="green"
                prepend-icon="mdi-whatsapp"
                label="Para qual número de whatsapp você deseja enviar?"
                class="ma-1"
                v-model="message.whatsapp"
                outlined
                clearable
              ></v-text-field>
          </template>
          <template v-if="toggle_exclusive.includes('telegram')">
              <v-text-field
                color="green"
                label="Para qual conta de telegram você deseja enviar?"
                prepend-icon="mdi-telegram"
                class="ma-1"
                v-model="message.telegram"
                outlined
                clearable
              ></v-text-field>
          </template>
        </v-col>
      </v-row>
</template>

<script>
export default {
    data () {
      return {
        toggle_exclusive: [],
        shipments: ['email', 'whatsapp', 'telegram'],
        message: {
          email: 'teste@gmail.com',
          whatsapp: '00 00000000',
          telegram: '@user',
        },
        tMessage: false
      }
    }
}
</script>

<style>

</style>