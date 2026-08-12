<template>
  <div class="flex flex-col h-screen bg-gray-50">
    <!-- Header -->
    <div class="bg-white shadow-sm px-4 py-3 flex items-center gap-3">
      <button @click="$router.back()" class="text-blue-500 text-sm">← Назад</button>
      <div class="flex-1">
        <div class="font-semibold text-gray-800">Чат #{{ chatId }}</div>
        <div class="text-xs text-gray-400">Пользователь {{ chat?.user_id }}</div>
      </div>
      <div class="flex gap-2">
        <button
          v-if="chat?.status === 'open'"
          @click="claim"
          class="text-xs bg-blue-500 text-white px-3 py-1 rounded-full"
        >Взять в работу</button>
        <button
          v-if="chat?.status === 'in_progress'"
          @click="closeChat"
          class="text-xs bg-gray-400 text-white px-3 py-1 rounded-full"
        >Закрыть</button>
      </div>
    </div>

    <!-- Messages -->
    <div ref="msgContainer" class="flex-1 overflow-y-auto p-4 space-y-2">
      <div
        v-for="msg in messages"
        :key="msg.id"
        class="flex"
        :class="msg.sender === 'operator' ? 'justify-end' : 'justify-start'"
      >
        <div
          class="max-w-[75%] px-3 py-2 rounded-2xl text-sm"
          :class="msg.sender === 'operator'
            ? 'bg-blue-500 text-white rounded-br-sm'
            : 'bg-white text-gray-800 shadow-sm rounded-bl-sm'"
        >
          {{ msg.text }}
          <div class="text-xs opacity-60 mt-0.5 text-right">{{ formatTime(msg.created_at) }}</div>
        </div>
      </div>
    </div>

    <!-- Input -->
    <div class="bg-white border-t px-4 py-3 flex gap-2">
      <input
        v-model="draft"
        @keydown.enter="send"
        placeholder="Ответить..."
        class="flex-1 bg-gray-100 rounded-full px-4 py-2 text-sm outline-none"
      />
      <button
        @click="send"
        :disabled="!draft.trim()"
        class="bg-blue-500 disabled:opacity-40 text-white rounded-full px-4 py-2 text-sm font-medium"
      >→</button>
    </div>
  </div>
</template>

<script setup>
import { nextTick, onMounted, onUnmounted, ref } from 'vue'
import { useRoute } from 'vue-router'
import { api } from '../api'

const route = useRoute()
const chatId = Number(route.params.id)

const chat = ref(null)
const messages = ref([])
const draft = ref('')
const msgContainer = ref(null)
let pollTimer = null

const formatTime = (d) => new Date(d).toLocaleTimeString('ru', { hour: '2-digit', minute: '2-digit' })

async function load() {
  try {
    messages.value = await api.getMessages(chatId)
    await nextTick()
    msgContainer.value?.scrollTo(0, msgContainer.value.scrollHeight)
  } catch { /* silent */ }
}

async function claim() {
  try {
    chat.value = await api.claimChat(chatId)
  } catch (e) {
    alert(e.message)
  }
}

async function closeChat() {
  try {
    chat.value = await api.updateStatus(chatId, 'closed')
  } catch (e) {
    alert(e.message)
  }
}

async function send() {
  const text = draft.value.trim()
  if (!text) return
  draft.value = ''
  try {
    const msg = await api.sendMessage(chatId, text)
    messages.value.push(msg)
    await nextTick()
    msgContainer.value?.scrollTo(0, msgContainer.value.scrollHeight)
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
