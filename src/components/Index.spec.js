import { describe, it, expect, vi, beforeEach } from 'vitest'
import { mount } from '@vue/test-utils'
import { createVuetify } from 'vuetify'
import * as components from 'vuetify/components'
import * as directives from 'vuetify/directives'
import Index from './Index.vue'

// Create Vuetify instance for testing
const vuetify = createVuetify({
  components,
  directives
})

// Mock vue-turnstile
vi.mock('vue-turnstile', () => ({
  default: {
    name: 'VueTurnstile',
    template: '<div class="turnstile-widget"></div>',
    props: ['siteKey'],
    emits: ['success']
  }
}))

// Mock axios
vi.mock('axios', () => ({
  default: {
    post: vi.fn().mockResolvedValue({ data: 'Success' }),
    get: vi.fn().mockResolvedValue({
      data: {
        data: {
          title: 'Test GIF',
          url: 'https://giphy.com/test.gif'
        }
      }
    })
  }
}))

describe('Index Component', () => {
  let wrapper

  beforeEach(() => {
    wrapper = mount(Index, {
      global: {
        plugins: [vuetify],
        stubs: {
          VImg: true
        }
      }
    })
  })

  it('should render the logo title', () => {
    expect(wrapper.text()).toContain('mepagueoque.dev')
  })

  it('should render the logo subtitle', () => {
    expect(wrapper.text()).toContain('(um jeito sutil de cobrar os(as) caloteiros(as))')
  })

  it('should render message textarea label', () => {
    expect(wrapper.text()).toContain('Escreva uma mensagem para o(a) caloteiro(a)')
  })

  it('should render value input label', () => {
    expect(wrapper.text()).toContain('Qual o valor do golpe?')
  })

  it('should have default message value', async () => {
    const textarea = wrapper.find('[data-testid="mensagem"]')
    expect(textarea.exists()).toBe(true)
  })

  it('should have default value', async () => {
    const valueInput = wrapper.find('[data-testid="valor"]')
    expect(valueInput.exists()).toBe(true)
  })

  it('should render chip group with email and whatsapp options', () => {
    expect(wrapper.text()).toContain('Email')
    expect(wrapper.text()).toContain('WhatsApp')
  })

  it('should render the submit button', () => {
    expect(wrapper.text()).toContain('Cobrar!')
  })

  it('should show email input when email chip is selected', async () => {
    await wrapper.vm.$nextTick()
    expect(wrapper.text()).toContain('Para qual email você deseja enviar?')
  })
})
