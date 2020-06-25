<template>
  <v-container>
    <v-row class="text-center d-flex align-center">
      <v-col cols="12" class="mt-md-5 mt-lg-5 mt-xl-5 mb-md-5 mb-lg-5 mb-xl-5">
        <h1 class="text-center font-weight-black text-left green--text darken-1--text">
          Endividamento no Brasil
        </h1>
      </v-col>
      <v-col cols="12" xs="12" sm="12" md="8" lg="8" xl="8" class="mt-md-5 mt-lg-5 mt-xl-5">
        <p class="text-justify">
          O endividamento dos brasileiros atingiu recorde em março, informou nesta segunda-feira, 30, a Confederação Nacional do Comércio de Bens, Serviços e Turismo (CNC). 
          
          Após ter recuado a 65,1% em fevereiro, o porcentual de famílias com dívidas saltou para 66,2% este mês, o maior patamar da série histórica da Pesquisa de Endividamento e Inadimplência do Consumidor (Peic), 
          iniciada em janeiro de 2010.
        </p>
        <p class="text-justify">
          A inadimplência também subiu e a expectativa da entidade é que aumente por causa do coronavírus. 
          De acordo com o levantamento da CNC, o porcentual de famílias com dívidas ou contas em atraso chegou a 25,3% em março, 
          contra 24,1% no mês anterior.
        </p>
        <p class="text-justify">
          O levantamento considera como dívidas as contas a pagar em cheque pré-datado, 
          cartão de crédito, cheque especial, carnê de loja, empréstimo pessoal, prestação de carro e seguro.
        </p>
        <p class="text-justify">
          O total de famílias que declararam não ter condições de pagar suas contas ou dívidas em atraso e que, portanto, permaneceriam inadimplentes passou de 9,7% em fevereiro para 10,2% em março. 
          Os indicadores também registraram aumento no comparativo anual.
        </p>
        <a style="text-decoration: none;" target="_blank" href="https://exame.com/economia/endividamento-no-brasil-bate-recorde-e-deve-aumentar-devido-ao-coronavirus/">
          <v-chip
            class="ma-2"
            color="green darken-1"
            outlined
          >
            <v-icon left>mdi-fire</v-icon>
            Fonte: Exame
          </v-chip>
        </a>
      </v-col>
      <v-col
        cols="12"
        xs="12"
        sm="12"
        md="4"
        lg="4"
        xl="4"
        class="mt-md-5 mt-lg-5 mt-xl-5 d-none d-md-inline"
      >
        <v-img :src="require('../assets/wallet.svg')" contain height="400" />
      </v-col>
    </v-row>
  </v-container>
</template>

<script>
export default {
  name: 'Index',
}
</script>
