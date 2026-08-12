<template>
  <div class="flex flex-col h-[100dvh] bg-gradient-to-br from-slate-900 via-purple-900 to-slate-900 relative overflow-hidden">
    <!-- Decorative background elements -->
    <div class="absolute top-[-10%] right-[-10%] w-64 h-64 rounded-full bg-purple-500/20 blur-[100px] pointer-events-none"></div>

    <!-- Header -->
    <div class="glass-dark px-4 py-3 flex items-center gap-3 relative z-20 border-b border-white/5">
      <button @click="goBack" class="w-10 h-10 rounded-full flex items-center justify-center bg-white/5 hover:bg-white/10 active:scale-95 transition">
        <svg class="w-5 h-5 text-white/80" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"></path></svg>
      </button>
      
      <div class="flex-1 overflow-hidden">
        <div class="font-bold text-white text-lg truncate tracking-tight">Чат #{{ chatId }}</div>
        <div class="text-[11px] text-white/50 uppercase tracking-wider font-semibold truncate">Клиент {{ chat?.user_id || '...' }}</div>
      </div>
      
      <div class="flex gap-2 shrink-0">
        <button
          v-if="chat?.status === 'open'"
          @click="claim"
          class="text-xs font-semibold uppercase tracking-wide bg-gradient-to-r from-blue-500 to-purple-500 text-white px-4 py-2 rounded-full shadow-lg hover:shadow-blue-500/25 active:scale-95 transition-all"
        >В работу</button>
        <button
          v-if="chat?.status === 'in_progress'"
          @click="closeChat"
          class="text-xs font-semibold uppercase tracking-wide bg-white/10 hover:bg-white/20 text-white/80 px-4 py-2 rounded-full active:scale-95 transition-all"
        >Закрыть</button>
      </div>
    </div>

    <!-- Messages -->
    <div ref="msgContainer" class="flex-1 overflow-y-auto p-4 space-y-4 relative z-10 scroll-smooth">
      <transition-group name="message">
        <div
          v-for="(msg, i) in messages"
          :key="msg.id"
          class="flex"
          :class="msg.sender === 'operator' ? 'justify-end' : 'justify-start'"
        >
          <div
            class="max-w-[80%] px-4 py-2.5 rounded-2xl text-[15px] leading-relaxed shadow-lg backdrop-blur-md relative"
            :class="msg.sender === 'operator'
              ? 'bg-gradient-to-br from-blue-500 to-blue-600 text-white rounded-br-sm'
              : 'bg-white/10 text-slate-100 rounded-bl-sm border border-white/5'"
          >
            {{ msg.text }}
            <div 
              class="text-[10px] mt-1 font-medium"
              :class="msg.sender === 'operator' ? 'text-blue-200 text-right' : 'text-white/40 text-right'"
            >
              {{ formatTime(msg.created_at) }}
            </div>
          </div>
        </div>
      </transition-group>
    </div>

    <!-- Input Area -->
    <div v-if="chat?.status !== 'closed'" class="glass-dark p-3 pb-safe relative z-20 border-t border-white/5">
      <div class="flex items-end gap-2 bg-black/20 rounded-3xl p-1 border border-white/10 focus-within:border-white/20 transition-colors">
        <textarea
          v-model="draft"
          @keydown.enter.exact.prevent="send"
          placeholder="Напишите ответ..."
          rows="1"
          class="flex-1 bg-transparent px-4 py-3 text-[15px] text-white placeholder-white/40 outline-none resize-none max-h-32 min-h-[44px]"
          @input="adjustHeight"
          ref="textareaRef"
        ></textarea>
        <button
          @click="send"
          :disabled="!draft.trim()"
          class="w-11 h-11 shrink-0 rounded-full flex items-center justify-center bg-gradient-to-r from-blue-500 to-purple-500 text-white shadow-lg disabled:opacity-40 disabled:grayscale transition-all active:scale-90"
        >
          <svg class="w-5 h-5 ml-1" fill="currentColor" viewBox="0 0 24 24"><path d="M2.01 21L23 12 2.01 3 2 10l15 2-15 2z"></path></svg>
        </button>
      </div>
    </div>
    <div v-else class="glass-dark p-4 pb-safe text-center text-white/50 text-sm font-medium border-t border-white/5 relative z-20">
      Диалог завершен
    </div>
  </div>
</template>

<script setup>
import { nextTick, onMounted, onUnmounted, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { api } from '../api'

const route = useRoute()
const router = useRouter()
const chatId = Number(route.params.id)

const chat = ref(null)
const messages = ref([])
const draft = ref('')
const msgContainer = ref(null)
const textareaRef = ref(null)
let pollTimer = null

const formatTime = (d) => new Date(d).toLocaleTimeString('ru', { hour: '2-digit', minute: '2-digit' })

const haptic = (style = 'light') => {
  if (window.Telegram?.WebApp?.HapticFeedback) {
    window.Telegram.WebApp.HapticFeedback.impactOccurred(style)
  }
}

function goBack() {
  haptic('light')
  router.back()
}

async function load() {
  try {
    const newMessages = await api.getMessages(chatId)
    const prevCount = messages.value.length
    messages.value = newMessages
    
    // Fetch chat status if we don't have it, or periodically
    const allChats = await api.getChats()
    chat.value = allChats.find(c => c.id === chatId) || chat.value

    if (newMessages.length > prevCount) {
      await nextTick()
      msgContainer.value?.scrollTo({ top: msgContainer.value.scrollHeight, behavior: 'smooth' })
    }
  } catch { /* silent */ }
}

async function claim() {
  haptic('medium')
  try {
    chat.value = await api.claimChat(chatId)
  } catch (e) {
    if (window.Telegram?.WebApp) {
      window.Telegram.WebApp.showAlert(e.message)
    } else {
      alert(e.message)
    }
  }
}

async function closeChat() {
  haptic('medium')
  try {
    chat.value = await api.updateStatus(chatId, 'closed')
  } catch (e) {
    alert(e.message)
  }
}

function adjustHeight() {
  if (textareaRef.value) {
    textareaRef.value.style.height = 'auto'
    textareaRef.value.style.height = Math.min(textareaRef.value.scrollHeight, 128) + 'px'
  }
}

async function send() {
  const text = draft.value.trim()
  if (!text) return
  
  haptic('light')
  draft.value = ''
  adjustHeight()
  
  try {
    const msg = await api.sendMessage(chatId, text)
    messages.value.push(msg)
    await nextTick()
    msgContainer.value?.scrollTo({ top: msgContainer.value.scrollHeight, behavior: 'smooth' })
  } catch (e) {
    alert(e.message)
  }
}

onMounted(() => {
  load()
  pollTimer = setInterval(load, 2000)
})
onUnmounted(() => clearInterval(pollTimer))
</script>

<style scoped>
.pb-safe {
  padding-bottom: env(safe-area-inset-bottom, 16px);
}
</style>
