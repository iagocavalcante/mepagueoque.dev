/* eslint-disable no-undef */
import '@testing-library/jest-dom'
import Vue from 'vue'
import { render, fireEvent } from '@testing-library/vue'
import Vuetify from 'vuetify'

import Index from '@/components/Index'

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

describe('Index Component', () => {
  it('should render title', () => {
    const { getByText } = renderWithVuetify(Index)
    expect(getByText('mepagueoque.dev')).toBeInTheDocument()
  })
  
  it('should render subtitle', () => {
    const { getByText } = renderWithVuetify(Index)
    expect(getByText('(um jeito sutil de cobrar os(as) caloteiros(as))')).toBeInTheDocument()
  })
  
  it('should render label in text area', () => {
    const { getByText } = renderWithVuetify(Index)
    expect(getByText('Escreva uma mensagem para o(a) caloteiro(a)')).toBeInTheDocument()
  })
  
  it('should render message in textarea', async () => {
    const messageText = 'Ei carinha que mora logo ali, me pague'
    const { getByTestId } = renderWithVuetify(Index)
    const messageInput = getByTestId('mensagem')
    await fireEvent.update(messageInput, messageText)
    expect(messageInput._value).toBe(messageText)
  })
  
  it('should render value input', () => {
    const { getByText } = renderWithVuetify(Index)
    expect(getByText('Qual o valor do golpe?')).toBeInTheDocument()
  })
  
  it('should render value in the input', async () => {
    const { getByTestId } = renderWithVuetify(Index)
    const value = getByTestId('valor')
    await fireEvent.update(value, 10.0)
    expect(value._value).toBe('10')
  })
})
