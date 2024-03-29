/* eslint-disable no-undef */
import '@testing-library/jest-dom'
import Vue from 'vue'
import { render } from '@testing-library/vue'
import Vuetify from 'vuetify'

import Footer from '@/components/Footer'

Vue.use(Vuetify)

const renderWithVuetify = (component, options, callback) => {
  return render(
    component,
    {
      // for Vuetify components that use the $vuetify instance property
      vuetify: new Vuetify(),
      ...options,
    },
    callback,
  )
}

describe('Footer Component', () => {
  it('should render authors footer text', () => {
    const { getByText } = renderWithVuetify(Footer)
    expect(getByText('Iago Cavalcante, Bianca Silva, Thayana Mamore')).toBeInTheDocument()
  })

  const currentYear = new Date().getFullYear()

  it('should render application name in footer text', () => {
    const { getByText } = renderWithVuetify(Footer)
    expect(getByText(`© MePagueOQue.Dev - ${currentYear}`)).toBeInTheDocument()
  })
})
