import { mount } from '@vue/test-utils'
import { describe, it, expect, vi } from 'vitest'
import { createVuetify } from 'vuetify'
import { createRouter, createWebHistory } from 'vue-router'
import * as components from 'vuetify/components'
import * as directives from 'vuetify/directives'
import axios from 'axios'
import CreatePaymentPage from './CreatePaymentPage.vue'

vi.mock('axios')

vi.mock('vue-turnstile', () => ({
  default: {
    name: 'VueTurnstile',
    template: '<div class="turnstile-widget"></div>',
    props: ['siteKey', 'modelValue'],
    emits: ['update:modelValue'],
  },
}))

const buildVuetify = () => createVuetify({ components, directives })
const buildRouter = () =>
  createRouter({
    history: createWebHistory(),
    routes: [{ path: '/p/:slug', name: 'payment', component: { template: '<div>p</div>' } }],
  })

describe('CreatePaymentPage', () => {
  it('submits form and redirects to /p/:slug on success', async () => {
    axios.post.mockResolvedValue({ data: { slug: 'volei', url: 'https://mepagueoque.dev/p/volei' } })

    const router = buildRouter()
    const push = vi.spyOn(router, 'push')

    const wrapper = mount(CreatePaymentPage, {
      global: { plugins: [buildVuetify(), router] },
    })

    await wrapper.find('[data-test="pix-key"] input').setValue('iago@example.com')
    await wrapper.find('[data-test="beneficiary-name"] input').setValue('IAGO')
    await wrapper.find('[data-test="city"] input').setValue('BELEM')
    await wrapper.find('[data-test="description"] input').setValue('VOLEI')
    await wrapper.find('[data-test="amount"] input').setValue('15.00')
    // Turnstile token is set via prop or refs; in test we cheat:
    wrapper.vm.turnstileToken = 'bypass'
    await wrapper.vm.$nextTick()

    await wrapper.find('form').trigger('submit')
    await new Promise((r) => setTimeout(r, 50))

    expect(axios.post).toHaveBeenCalled()
    expect(push).toHaveBeenCalledWith({ name: 'payment', params: { slug: 'volei' } })
  })

  it('shows inline error on 409 slug_taken', async () => {
    axios.post.mockRejectedValue({ response: { status: 409, data: { error: 'slug_taken' } } })

    const wrapper = mount(CreatePaymentPage, {
      global: { plugins: [buildVuetify(), buildRouter()] },
    })

    await wrapper.find('[data-test="pix-key"] input').setValue('iago@example.com')
    await wrapper.find('[data-test="beneficiary-name"] input').setValue('IAGO')
    await wrapper.find('[data-test="city"] input').setValue('BELEM')
    await wrapper.find('[data-test="description"] input').setValue('VOLEI')
    await wrapper.find('[data-test="amount"] input').setValue('15.00')
    await wrapper.find('[data-test="slug"] input').setValue('dup')
    wrapper.vm.turnstileToken = 'bypass'
    await wrapper.vm.$nextTick()

    await wrapper.find('form').trigger('submit')
    await new Promise((r) => setTimeout(r, 50))

    expect(wrapper.text()).toContain('esse slug já existe')
  })
})
