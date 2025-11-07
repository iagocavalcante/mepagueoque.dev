import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import { createVuetify } from 'vuetify'
import * as components from 'vuetify/components'
import * as directives from 'vuetify/directives'
import Content from './Content.vue'

// Create Vuetify instance for testing
const vuetify = createVuetify({
  components,
  directives
})

describe('Content Component', () => {
  it('should render the section title', () => {
    const wrapper = mount(Content, {
      global: {
        plugins: [vuetify],
        stubs: {
          VImg: true
        }
      }
    })

    expect(wrapper.text()).toContain('Endividamento no Brasil')
  })

  it('should render all stat cards', () => {
    const wrapper = mount(Content, {
      global: {
        plugins: [vuetify],
        stubs: {
          VImg: true
        }
      }
    })

    expect(wrapper.text()).toContain('Famílias Endividadas')
    expect(wrapper.text()).toContain('66.2%')
    expect(wrapper.text()).toContain('Contas em Atraso')
    expect(wrapper.text()).toContain('25.3%')
    expect(wrapper.text()).toContain('Inadimplentes')
    expect(wrapper.text()).toContain('10.2%')
    expect(wrapper.text()).toContain('Recorde Histórico')
    expect(wrapper.text()).toContain('2020')
  })

  it('should render content paragraphs', () => {
    const wrapper = mount(Content, {
      global: {
        plugins: [vuetify],
        stubs: {
          VImg: true
        }
      }
    })

    expect(wrapper.text()).toContain('O endividamento dos brasileiros atingiu recorde')
    expect(wrapper.text()).toContain('Confederação Nacional do Comércio')
  })

  it('should render source link', () => {
    const wrapper = mount(Content, {
      global: {
        plugins: [vuetify],
        stubs: {
          VImg: true
        }
      }
    })

    expect(wrapper.text()).toContain('Fonte: Exame')
    const link = wrapper.find('a[href*="exame.com"]')
    expect(link.exists()).toBe(true)
  })
})
