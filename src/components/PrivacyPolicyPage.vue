<template>
  <v-container class="py-12" max-width="800">
    <h1 class="text-h4 mb-6">Política de Privacidade</h1>
    <p class="text-caption mb-8">Última atualização: 15 de maio de 2026</p>

    <section class="mb-8">
      <h2 class="text-h6 mb-3">1. Quem somos</h2>
      <p>
        <strong>mepagueoque.dev</strong> é um projeto pessoal mantido por
        Iago Cavalcante, operado a partir do Brasil. Esta política descreve
        como tratamos dados pessoais em conformidade com a Lei Geral de
        Proteção de Dados (LGPD, Lei nº 13.709/2018).
      </p>
      <p class="mt-3">
        <strong>Controlador dos dados:</strong> Iago Cavalcante<br />
        <strong>Contato (encarregado/DPO):</strong>
        <a href="mailto:iagocavalcante@hey.com">iagocavalcante@hey.com</a>
      </p>
    </section>

    <section class="mb-8">
      <h2 class="text-h6 mb-3">2. Quais dados coletamos</h2>
      <p>Coletamos apenas o mínimo necessário para o funcionamento do serviço:</p>
      <ul class="ml-6 mt-3">
        <li><strong>Ao criar um link em /criar:</strong> sua chave PIX (CPF, CNPJ, email, telefone ou chave aleatória), nome, cidade, descrição da cobrança e valor.</li>
        <li><strong>Ao enviar um email pela página inicial:</strong> o email do destinatário, a mensagem e o valor (não armazenamos — apenas repassamos para envio).</li>
        <li><strong>Em todas as requisições:</strong> seu endereço IP (parcialmente mascarado nos logs), enviado também ao Cloudflare Turnstile para verificação anti-bot.</li>
        <li><strong>Se você aceitar cookies:</strong> dados anônimos de navegação via Google Firebase Analytics.</li>
      </ul>
    </section>

    <section class="mb-8">
      <h2 class="text-h6 mb-3">3. Base legal (Art. 7º da LGPD)</h2>
      <ul class="ml-6">
        <li><strong>Execução do serviço solicitado:</strong> ao preencher e enviar um formulário, você nos autoriza a processar seus dados para gerar o link/email.</li>
        <li><strong>Consentimento:</strong> para cookies de análise (Firebase Analytics).</li>
        <li><strong>Legítimo interesse:</strong> para proteção contra abuso (Cloudflare Turnstile, logs com IP parcialmente mascarado).</li>
      </ul>
    </section>

    <section class="mb-8">
      <h2 class="text-h6 mb-3">4. Como armazenamos e por quanto tempo</h2>
      <ul class="ml-6">
        <li><strong>Links PIX:</strong> armazenados em SQLite em volume criptografado na região São Paulo (Fly.io GRU). <strong>Excluídos automaticamente após 90 dias.</strong></li>
        <li><strong>Emails:</strong> não armazenados. Apenas repassados ao Resend para envio.</li>
        <li><strong>Logs:</strong> retenção máxima de 30 dias na infraestrutura. IPs são mascarados (apenas três primeiros octetos) e chaves PIX nunca são logadas em texto pleno.</li>
      </ul>
    </section>

    <section class="mb-8">
      <h2 class="text-h6 mb-3">5. Com quem compartilhamos (operadores)</h2>
      <p>Usamos serviços de terceiros estritamente para operar o produto:</p>
      <ul class="ml-6 mt-3">
        <li><strong>Fly.io</strong> (EUA, com servidor em GRU/Brasil) — hospedagem do backend.</li>
        <li><strong>Netlify</strong> (EUA) — hospedagem do frontend.</li>
        <li><strong>Cloudflare Turnstile</strong> (EUA) — verificação anti-bot.</li>
        <li><strong>Resend</strong> (EUA) — envio de emails.</li>
        <li><strong>Giphy</strong> (EUA) — GIFs decorativos.</li>
        <li><strong>Google Firebase</strong> (EUA) — análise de uso, apenas se você consentir com cookies.</li>
      </ul>
      <p class="mt-3">
        Transferência internacional de dados é amparada pelo Art. 33 da LGPD,
        principalmente cláusulas contratuais padrão e/ou consentimento.
      </p>
    </section>

    <section class="mb-8">
      <h2 class="text-h6 mb-3">6. Seus direitos (Art. 18 da LGPD)</h2>
      <p>Você pode, a qualquer momento, solicitar:</p>
      <ul class="ml-6 mt-3">
        <li>Confirmação da existência de tratamento;</li>
        <li>Acesso aos seus dados;</li>
        <li>Correção de dados incompletos ou desatualizados;</li>
        <li>Anonimização, bloqueio ou eliminação de dados desnecessários;</li>
        <li>Portabilidade;</li>
        <li>Revogação do consentimento.</li>
      </ul>
      <p class="mt-3">
        <strong>Para links PIX:</strong> use o botão "Revogar este link" na
        página /p/{slug} (disponível somente para quem criou o link, no
        mesmo navegador) ou envie email para
        <a href="mailto:iagocavalcante@hey.com">iagocavalcante@hey.com</a>
        com o slug do link.
      </p>
      <p class="mt-3">
        <strong>Outros pedidos:</strong> envie para
        <a href="mailto:iagocavalcante@hey.com">iagocavalcante@hey.com</a>.
        Respondemos em até 15 dias.
      </p>
    </section>

    <section class="mb-8">
      <h2 class="text-h6 mb-3">7. Cookies</h2>
      <p>
        Usamos cookies essenciais (sessão, anti-bot) sem necessidade de
        consentimento. Cookies de análise (Firebase) só são ativados após
        você clicar em "Aceitar" no banner.
      </p>
    </section>

    <section class="mb-8">
      <h2 class="text-h6 mb-3">8. Segurança</h2>
      <p>
        Aplicamos medidas técnicas adequadas: HTTPS em todas as conexões,
        criptografia em repouso no volume de banco de dados, mascaramento
        de IPs em logs, e retenção limitada a 90 dias para dados de
        cobrança.
      </p>
    </section>

    <section class="mb-8">
      <h2 class="text-h6 mb-3">9. Incidentes</h2>
      <p>
        Em caso de incidente de segurança que possa acarretar risco aos
        seus direitos, notificaremos a ANPD e os titulares afetados, dentro
        do prazo razoável.
      </p>
    </section>

    <section class="mb-8">
      <h2 class="text-h6 mb-3">10. Alterações</h2>
      <p>
        Esta política pode ser atualizada. Avisaremos alterações
        significativas via banner no site.
      </p>
    </section>

    <v-btn :to="{ name: 'home' }" variant="text" color="primary">← Voltar</v-btn>
  </v-container>
</template>

<script setup>
// Static content page
</script>
