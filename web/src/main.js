import { createApp } from 'vue'
import { createRouter, createWebHashHistory } from 'vue-router'
import App from './App.vue'
import ChatList from './views/ChatList.vue'
import ChatView from './views/ChatView.vue'
import './style.css'

const router = createRouter({
  history: createWebHashHistory(),
  routes: [
    { path: '/', component: ChatList },
    { path: '/chat/:id', component: ChatView },
  ],
})

const app = createApp(App)
app.use(router)
app.mount('#app')
