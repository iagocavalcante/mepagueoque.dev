import { createRouter, createWebHistory } from 'vue-router'
import Home from '@/components/Index.vue'

const routes = [
  { path: '/', name: 'home', component: Home },
  {
    path: '/criar',
    name: 'create-payment',
    component: () => import('@/components/CreatePaymentPage.vue'),
  },
  {
    path: '/p/:slug',
    name: 'payment',
    component: () => import('@/components/PaymentPage.vue'),
    props: true,
  },
  {
    path: '/politica-de-privacidade',
    name: 'privacy',
    component: () => import('@/components/PrivacyPolicyPage.vue'),
  },
  {
    path: '/termos',
    name: 'terms',
    component: () => import('@/components/TermsPage.vue'),
  },
  { path: '/:pathMatch(.*)*', redirect: '/' },
]

export const router = createRouter({
  history: createWebHistory(),
  routes,
})
