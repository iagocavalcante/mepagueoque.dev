<template>
  <div class="contain mt-5 mb-5">
    <div class="logo">
      <h1 class="titulo mb-0">mepagueoque.dev</h1>
      <h6 class="sub-titulo mt-1 text--secondary">(um jeito sutil de cobrar os(as) caloteiros(as))</h6>
    </div>
  </div>
</template>

<script>
export default {
}
</script>

<style scoped>
.contain{
  display: flex;
  justify-content: center;
  height: 12vw;
}

.logo{
  display: block;
  margin: auto;
  top: 0; left: 0; bottom: 0; right: 0;
}

.titulo {
  font-family: 'BerlinSans';
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
  line-height: 1;
  text-align: right;
}
</style>