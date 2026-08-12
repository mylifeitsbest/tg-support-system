<template>
  <div class="min-h-screen bg-gradient-to-br from-slate-900 via-purple-900 to-slate-900 p-4 sm:p-6 overflow-hidden relative">
    <!-- Decorative background elements -->
    <div class="absolute top-[-10%] left-[-10%] w-64 h-64 rounded-full bg-purple-500/20 blur-[100px] pointer-events-none"></div>
    <div class="absolute bottom-[-10%] right-[-10%] w-80 h-80 rounded-full bg-blue-500/20 blur-[120px] pointer-events-none"></div>

    <div class="max-w-3xl mx-auto relative z-10">
      <header class="flex items-center justify-between mb-8 mt-2">
        <h1 class="text-3xl font-bold bg-clip-text text-transparent bg-gradient-to-r from-white to-white/70 tracking-tight">
          Обращения
        </h1>
        <div class="w-10 h-10 rounded-full glass flex items-center justify-center shadow-lg cursor-help transition-transform hover:scale-105 active:scale-95">
          <svg class="w-5 h-5 text-white/80" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>
        </div>
      </header>

      <transition name="fade" mode="out-in">
        <div v-if="loading" class="flex flex-col items-center justify-center py-20">
          <div class="w-12 h-12 border-4 border-purple-500/30 border-t-purple-500 rounded-full animate-spin mb-4"></div>
          <span class="text-white/60 font-medium tracking-wide animate-pulse">Синхронизация...</span>
        </div>

        <div v-else-if="error" class="glass-dark rounded-2xl p-6 text-center border-red-500/30">
          <svg class="w-12 h-12 text-red-400 mx-auto mb-3" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"></path></svg>
          <div class="text-red-200 font-medium">{{ error }}</div>
          <button @click="load" class="mt-4 px-6 py-2 bg-red-500/20 hover:bg-red-500/30 text-red-100 rounded-lg transition-colors">Повторить</button>
        </div>

        <div v-else-if="chats.length === 0" class="glass rounded-2xl p-10 text-center flex flex-col items-center">
          <div class="w-16 h-16 rounded-full bg-white/5 flex items-center justify-center mb-4">
            <svg class="w-8 h-8 text-white/40" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z"></path></svg>
          </div>
          <h3 class="text-xl font-medium text-white/90 mb-1">Нет активных обращений</h3>
          <p class="text-white/50 text-sm">Новые запросы появятся здесь автоматически.</p>
        </div>

        <ul v-else class="space-y-4 pb-10">
          <transition-group name="message">
            <li
              v-for="chat in chats"
              :key="chat.id"
              @click="$router.push(`/chat/${chat.id}`)"
              class="glass rounded-2xl p-5 cursor-pointer relative overflow-hidden group hover:-translate-y-1 transition-all duration-300"
            >
              <div class="absolute inset-0 bg-gradient-to-r from-white/0 via-white/5 to-white/0 translate-x-[-100%] group-hover:translate-x-[100%] transition-transform duration-1000"></div>
              
              <div class="flex justify-between items-start mb-3 relative z-10">
                <div class="flex items-center gap-3">
                  <div class="w-10 h-10 rounded-full bg-gradient-to-tr from-purple-500 to-blue-500 flex items-center justify-center shadow-inner font-bold text-white shadow-lg">
                    #{{ chat.id }}
                  </div>
                  <div>
                    <h3 class="font-semibold text-white text-lg leading-none mb-1">Клиент {{ chat.user_id }}</h3>
                    <div class="text-xs text-white/50 font-medium">{{ formatDate(chat.updated_at) }}</div>
                  </div>
                </div>
                <span
                  class="text-[11px] px-3 py-1 rounded-full font-bold uppercase tracking-wider shadow-sm border"
                  :class="statusClass(chat.status)"
                >
                  {{ statusLabel(chat.status) }}
                </span>
              </div>
              <div class="pl-13 text-sm text-white/70 line-clamp-1 relative z-10">
                Нажмите, чтобы просмотреть историю сообщений и ответить.
              </div>
            </li>
          </transition-group>
        </ul>
      </transition>
    </div>
  </div>
</template>

<script setup>
import { onMounted, onUnmounted, ref } from 'vue'
import { api } from '../api'

const chats = ref([])
const loading = ref(true)
const error = ref(null)
let pollTimer = null

const statusLabel = (s) => ({ open: 'Открыт', in_progress: 'В работе', closed: 'Закрыт' }[s] ?? s)
const statusClass = (s) => ({
  open: 'bg-emerald-500/20 text-emerald-300 border-emerald-500/30',
  in_progress: 'bg-amber-500/20 text-amber-300 border-amber-500/30',
  closed: 'bg-white/10 text-white/50 border-white/10',
}[s] ?? '')

const formatDate = (d) => {
  const date = new Date(d)
  return date.toLocaleTimeString('ru-RU', { hour: '2-digit', minute: '2-digit' }) + ' · ' + date.toLocaleDateString('ru-RU', { day: 'numeric', month: 'short' })
}

async function load() {
  try {
    const newChats = await api.getChats()
    // Simple update to maintain transitions
    chats.value = newChats
    error.value = null
  } catch (e) {
    if (!chats.value.length) {
      error.value = "Ошибка подключения: " + e.message
    }
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  if (window.Telegram?.WebApp) {
    window.Telegram.WebApp.ready()
    window.Telegram.WebApp.expand()
  }
  load()
  pollTimer = setInterval(load, 3000)
})
onUnmounted(() => clearInterval(pollTimer))
</script>
