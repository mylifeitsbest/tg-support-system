/**
 * API client for the operator Mini App.
 * Automatically injects Telegram initData as Authorization header.
 */
const BASE_URL = import.meta.env.VITE_API_BASE_URL || 'http://localhost:8000'

function getInitData() {
  try {
    return window.Telegram?.WebApp?.initData || ''
  } catch {
    return ''
  }
}

async function request(path, options = {}) {
  const initData = getInitData()
  const res = await fetch(`${BASE_URL}${path}`, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      ...(initData ? { Authorization: `tma ${initData}` } : {}),
      ...(options.headers || {}),
    },
  })
  if (!res.ok) throw new Error(`API error ${res.status}: ${await res.text()}`)
  return res.json()
}

export const api = {
  getChats: () => request('/chats'),
  getMessages: (chatId) => request(`/chats/${chatId}/messages`),
  sendMessage: (chatId, text) =>
    request(`/chats/${chatId}/messages`, {
      method: 'POST',
      body: JSON.stringify({ sender: 'operator', text }),
    }),
  claimChat: (chatId) => request(`/chats/${chatId}/claim`, { method: 'POST' }),
  updateStatus: (chatId, status) =>
    request(`/chats/${chatId}/status`, {
      method: 'PATCH',
      body: JSON.stringify({ status }),
    }),
}
