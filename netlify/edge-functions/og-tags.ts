// Returns OG/Twitter-card HTML to social-media crawlers visiting /p/:slug.
// Real users pass through to the SPA (public/_redirects → index.html).

import type { Context } from "https://edge.netlify.com"

const CRAWLER_PATTERNS = [
  /facebookexternalhit/i,
  /facebookcatalog/i,
  /twitterbot/i,
  /whatsapp/i,
  /linkedinbot/i,
  /telegrambot/i,
  /discordbot/i,
  /slackbot/i,
  /skypeuripreview/i,
  /applebot/i,
  /googlebot/i,
  /bingbot/i,
  /duckduckbot/i,
  /pinterest/i,
  /redditbot/i,
]

const API_HOST = Deno.env.get("VITE_API_HOST") || "https://mepagueoque-api.fly.dev"

export default async (request: Request, context: Context) => {
  const ua = request.headers.get("user-agent") || ""
  const isCrawler = CRAWLER_PATTERNS.some((re) => re.test(ua))

  // Real users get the SPA.
  if (!isCrawler) return context.next()

  const url = new URL(request.url)
  const slug = url.pathname.split("/").filter(Boolean)[1] // /p/{slug}
  if (!slug) return context.next()

  let data: {
    slug: string
    beneficiary_name: string
    description: string
    amount_cents: number
    br_code: string
    expires_at: string
  }

  try {
    const res = await fetch(`${API_HOST}/pagamentos/${slug}`)
    if (!res.ok) return context.next()
    data = await res.json()
  } catch {
    return context.next()
  }

  const amountBRL = new Intl.NumberFormat("pt-BR", {
    style: "currency",
    currency: "BRL",
  }).format(data.amount_cents / 100)

  const title = `${amountBRL} para ${data.beneficiary_name} via PIX`
  const description = `${data.description} — toque para ver o QR code e copia-e-cola.`
  const ogImage = `${url.origin}/p/${slug}/qr.png`
  const canonical = `${url.origin}/p/${slug}`

  const html = `<!DOCTYPE html>
<html lang="pt-BR">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>${esc(title)}</title>
<meta name="description" content="${esc(description)}">
<link rel="canonical" href="${esc(canonical)}">

<meta property="og:type" content="website">
<meta property="og:site_name" content="mepagueoque.dev">
<meta property="og:url" content="${esc(canonical)}">
<meta property="og:title" content="${esc(title)}">
<meta property="og:description" content="${esc(description)}">
<meta property="og:image" content="${esc(ogImage)}">
<meta property="og:image:width" content="500">
<meta property="og:image:height" content="500">
<meta property="og:image:alt" content="QR Code PIX para ${esc(data.beneficiary_name)}">

<meta name="twitter:card" content="summary_large_image">
<meta name="twitter:title" content="${esc(title)}">
<meta name="twitter:description" content="${esc(description)}">
<meta name="twitter:image" content="${esc(ogImage)}">
</head>
<body>
<h1>${esc(title)}</h1>
<p>${esc(description)}</p>
<p><a href="${esc(canonical)}">Abrir página de pagamento</a></p>
</body>
</html>`

  return new Response(html, {
    headers: {
      "content-type": "text/html; charset=utf-8",
      // Crawlers cache aggressively; let them re-check at most every 10 min.
      "cache-control": "public, max-age=600",
    },
  })
}

function esc(s: string): string {
  return s.replace(/[&<>"']/g, (c) =>
    ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]!),
  )
}
