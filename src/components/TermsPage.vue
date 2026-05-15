<template>
  <v-container class="py-12" max-width="800">
    <h1 class="text-h4 mb-6">Termos de Uso</h1>
    <p class="text-caption mb-8">Última atualização: 15 de maio de 2026</p>

    <section class="mb-8">
      <h2 class="text-h6 mb-3">1. Sobre o serviço</h2>
      <p>
        <strong>mepagueoque.dev</strong> é um serviço gratuito que permite
        gerar lembretes de cobrança via email/WhatsApp e criar links de
        cobrança PIX compartilháveis. Operado por Iago Cavalcante como
        projeto pessoal, sem fins lucrativos.
      </p>
    </section>

    <section class="mb-8">
      <h2 class="text-h6 mb-3">2. Uso aceitável</h2>
      <p>Ao usar o serviço, você concorda em:</p>
      <ul class="ml-6 mt-3">
        <li>Não usar para fraude, golpe, falsidade ideológica ou qualquer atividade ilegal;</li>
        <li>Fornecer apenas dados verdadeiros, principalmente sua chave PIX e seu nome;</li>
        <li>Não criar links em nome de terceiros sem autorização;</li>
        <li>Não fazer spam, flood ou abuso da API;</li>
        <li>Respeitar a Lei Geral de Proteção de Dados ao usar dados de outras pessoas (ex: emails de destinatários).</li>
      </ul>
    </section>

    <section class="mb-8">
      <h2 class="text-h6 mb-3">3. Sua responsabilidade</h2>
      <p>
        Os dados que você insere (chave PIX, nome, valor) ficam públicos
        para qualquer pessoa com a URL <code>/p/{slug}</code>. Compartilhe
        apenas com quem você quer que pague. O serviço apenas gera o
        QR/copia-e-cola — qualquer transação PIX acontece diretamente
        entre seu banco e o pagador.
      </p>
    </section>

    <section class="mb-8">
      <h2 class="text-h6 mb-3">4. Limitação de responsabilidade</h2>
      <p>
        O serviço é fornecido "como está", sem garantias. Não nos
        responsabilizamos por:
      </p>
      <ul class="ml-6 mt-3">
        <li>Erros na chave PIX que você inseriu;</li>
        <li>Pagamentos feitos para a chave errada;</li>
        <li>Indisponibilidade temporária do serviço;</li>
        <li>Conteúdo das descrições escritas por usuários.</li>
      </ul>
    </section>

    <section class="mb-8">
      <h2 class="text-h6 mb-3">5. Retenção e exclusão</h2>
      <p>
        Links PIX são excluídos automaticamente 90 dias após criação. Você
        pode revogar antes desse prazo pelo botão "Revogar este link" na
        página do link (precisa estar no mesmo navegador onde criou) ou
        solicitando exclusão por email a
        <a href="mailto:iagocavalcante@hey.com">iagocavalcante@hey.com</a>.
      </p>
    </section>

    <section class="mb-8">
      <h2 class="text-h6 mb-3">6. Privacidade</h2>
      <p>
        O tratamento de dados pessoais é descrito na
        <router-link :to="{ name: 'privacy' }">Política de Privacidade</router-link>.
      </p>
    </section>

    <section class="mb-8">
      <h2 class="text-h6 mb-3">7. Alterações</h2>
      <p>
        Estes termos podem ser atualizados. Alterações significativas serão
        avisadas no site.
      </p>
    </section>

    <section class="mb-8">
      <h2 class="text-h6 mb-3">8. Lei aplicável</h2>
      <p>
        Estes termos são regidos pelas leis da República Federativa do
        Brasil. Foro: Belém, Pará.
      </p>
    </section>

    <v-btn :to="{ name: 'home' }" variant="text" color="primary">← Voltar</v-btn>
  </v-container>
</template>

<script setup>
// Static content page
</script>
