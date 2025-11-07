import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import { createVuetify } from 'vuetify'
import * as components from 'vuetify/components'
import * as directives from 'vuetify/directives'
import Footer from './Footer.vue'

// Create Vuetify instance for testing
const vuetify = createVuetify({
  components,
  directives
})

describe('Footer Component', () => {
  it('should render all authors names', () => {
    const wrapper = mount(Footer, {
      global: {
        plugins: [vuetify]
      }
    })

    expect(wrapper.text()).toContain('Iago Cavalcante')
    expect(wrapper.text()).toContain('Bianca Silva')
    expect(wrapper.text()).toContain('Thayana Mamore')
  })

  it('should render copyright with current year', () => {
    const wrapper = mount(Footer, {
      global: {
        plugins: [vuetify]
      }
    })

    const currentYear = new Date().getFullYear()
    expect(wrapper.text()).toContain(`Copyright © ${currentYear}`)
    expect(wrapper.text()).toContain('MePagueOQue.Dev')
  })

  it('should render version number', () => {
    const wrapper = mount(Footer, {
      global: {
        plugins: [vuetify]
      }
    })

    expect(wrapper.text()).toMatch(/Versão \d+\.\d+\.\d+/)
  })

  it('should render disclaimer text', () => {
    const wrapper = mount(Footer, {
      global: {
        plugins: [vuetify]
      }
    })

    expect(wrapper.text()).toContain('Este site é uma ferramenta humorística')
  })

  it('should format authors correctly', () => {
    const wrapper = mount(Footer, {
      global: {
        plugins: [vuetify]
      }
    })

    const authorsText = wrapper.find('.authors').text()
    expect(authorsText).toContain('Iago Cavalcante, Bianca Silva, Thayana Mamore')
  })
})
