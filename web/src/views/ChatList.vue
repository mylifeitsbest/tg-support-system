<template>
  <div class="min-h-screen bg-gray-50 p-4">
    <h1 class="text-xl font-semibold text-gray-800 mb-4">Обращения</h1>

    <div v-if="loading" class="text-gray-500 text-center mt-10">Загрузка…</div>
    <div v-else-if="error" class="text-red-500 text-center mt-10">{{ error }}</div>

    <ul v-else class="space-y-2">
      <li
        v-for="chat in chats"
        :key="chat.id"
        @click="$router.push(`/chat/${chat.id}`)"
        class="bg-white rounded-xl shadow-sm p-4 cursor-pointer active:bg-gray-100 transition"
      >
        <div class="flex justify-between items-center">
          <span class="font-medium text-gray-700">Чат #{{ chat.id }}</span>
          <span
            class="text-xs px-2 py-0.5 rounded-full font-medium"
            :class="statusClass(chat.status)"
          >{{ statusLabel(chat.status) }}</span>
        </div>
        <div class="text-xs text-gray-400 mt-1">
          Пользователь: {{ chat.user_id }} · {{ formatDate(chat.updated_at) }}
        </div>
      </li>
    </ul>
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
  open: 'bg-blue-100 text-blue-700',
  in_progress: 'bg-yellow-100 text-yellow-700',
  closed: 'bg-gray-100 text-gray-500',
}[s] ?? '')
const formatDate = (d) => new Date(d).toLocaleString('ru')

async function load() {
  try {
    chats.value = await api.getChats()
    error.value = null
  } catch (e) {
    error.value = e.message
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  load()
  pollTimer = setInterval(load, 2000)
})
onUnmounted(() => clearInterval(pollTimer))
</script>
