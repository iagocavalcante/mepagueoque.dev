<template>
  <div  class="contain mt-4 mb-4">
    <div class="logo">
      <h1 class="titulo">mepagueoque.dev</h1>
      <h6 class="sub-titulo text--secondary">(um jeito sutil de cobrar os(as) caloteiros(as))</h6>
    </div>
  </div>
</template>

<script>
export default {
}
</script>

<style scoped>
@import url("../assets/css/fonts.css");

.contain{
  display: flex;
  justify-content: center;
}

.logo{
  display: block;
}

.titulo {
  font-family: 'Berlin';
  font-weight: 100;
  font-size: 5.4vw;
  color: #1fc259;
  line-height: 1;
  text-align: right;
}

.sub-titulo{
  font-family: 'Antaro';
  font-size: 1.4vw;
  color: #2d2b33;
  text-align: right;
}
</style>