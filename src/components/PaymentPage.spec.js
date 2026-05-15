import { mount, flushPromises } from '@vue/test-utils'
import { describe, it, expect, vi, beforeEach } from 'vitest'
import { createVuetify } from 'vuetify'
import * as components from 'vuetify/components'
import * as directives from 'vuetify/directives'
import axios from 'axios'
import PaymentPage from './PaymentPage.vue'

vi.mock('axios')
vi.mock('qrcode', () => ({ default: { toCanvas: vi.fn() } }))

const buildVuetify = () => createVuetify({ components, directives })

describe('PaymentPage', () => {
  beforeEach(() => vi.clearAllMocks())

  it('renders payload after fetch', async () => {
    axios.get.mockResolvedValue({
      data: {
        slug: 'volei',
        beneficiary_name: 'IAGO',
        description: 'VOLEI 18/05',
        amount_cents: 1500,
        br_code: '00020126...',
        expires_at: new Date(Date.now() + 86400000).toISOString(),
      },
    })

    const wrapper = mount(PaymentPage, {
      props: { slug: 'volei' },
      global: { plugins: [buildVuetify()] },
    })

    await flushPromises()

    expect(wrapper.text()).toContain('IAGO')
    expect(wrapper.text()).toContain('VOLEI 18/05')
    // Intl.NumberFormat uses a non-breaking space (U+00A0) between symbol and number
    expect(wrapper.text()).toMatch(/R\$\s15,00/)
    expect(wrapper.find('[data-test="br-code"] textarea').element.value).toBe('00020126...')
  })

  it('shows expired state on 404', async () => {
    axios.get.mockRejectedValue({ response: { status: 404 } })

    const wrapper = mount(PaymentPage, {
      props: { slug: 'gone' },
      global: { plugins: [buildVuetify()] },
    })

    await flushPromises()
    expect(wrapper.text()).toContain('Esse link expirou ou não existe')
  })
})
