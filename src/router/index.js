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
  { path: '/:pathMatch(.*)*', redirect: '/' },
]

export const router = createRouter({
  history: createWebHistory(),
  routes,
})
