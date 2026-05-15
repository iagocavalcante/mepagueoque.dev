// Generates a PNG of the PIX BR Code for a given slug.
// Used as the og:image for social-media unfurling, and addressable directly
// at /p/:slug/qr.png.

import type { Context } from "https://edge.netlify.com"
import QRCode from "npm:qrcode@1.5.4"

const API_HOST = Deno.env.get("VITE_API_HOST") || "https://mepagueoque-api.fly.dev"

export default async (request: Request, _context: Context) => {
  const url = new URL(request.url)
  // Path is /p/{slug}/qr.png → parts after filter are ["p", slug, "qr.png"].
  const parts = url.pathname.split("/").filter(Boolean)
  const slug = parts[1]
  if (!slug) return new Response("not found", { status: 404 })

  let brCode: string
  try {
    const res = await fetch(`${API_HOST}/pagamentos/${slug}`)
    if (!res.ok) return new Response("not found", { status: 404 })
    const data = await res.json()
    brCode = data.br_code
  } catch {
    return new Response("not found", { status: 404 })
  }

  if (!brCode) return new Response("not found", { status: 404 })

  // toDataURL works in any environment (no Node Buffer dependency).
  const dataUrl = await QRCode.toDataURL(brCode, {
    width: 500,
    margin: 2,
    errorCorrectionLevel: "M",
    color: { dark: "#000000", light: "#FFFFFF" },
  })

  const base64 = dataUrl.split(",")[1]
  const bytes = Uint8Array.from(atob(base64), (c) => c.charCodeAt(0))

  return new Response(bytes, {
    headers: {
      "content-type": "image/png",
      // QR is deterministic for a given slug; cache for 1 day.
      "cache-control": "public, max-age=86400",
    },
  })
}
