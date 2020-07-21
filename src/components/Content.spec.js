/* eslint-disable no-undef */
import '@testing-library/jest-dom'
import Vue from 'vue'
import { render } from '@testing-library/vue'
import Vuetify from 'vuetify'

import Content from '@/components/Content'

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

describe('Content Component', () => {
  it('should render with title', () => {
    const { getByText } = renderWithVuetify(Content)
    expect(getByText('Endividamento no Brasil')).toBeInTheDocument()
  })
})
