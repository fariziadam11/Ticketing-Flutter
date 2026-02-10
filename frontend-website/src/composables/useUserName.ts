import { computed, ref, watch } from 'vue'
import { usersApi, type InvGateUser } from '@/api/users'

const userCache = new Map<number, InvGateUser>()

export const useUserName = (authorId?: number) => {
  const user = ref<InvGateUser | null>(null)
  const loading = ref(false)
  const error = ref<Error | null>(null)

  const loadUser = async (id?: number) => {
    if (!id) {
      user.value = null
      return
    }

    if (userCache.has(id)) {
      user.value = userCache.get(id) as InvGateUser
      return
    }

    loading.value = true
    error.value = null

    try {
      const data = await usersApi.getById(id)
      user.value = data
      userCache.set(id, data)
    } catch (err: any) {
      error.value = err
    } finally {
      loading.value = false
    }
  }

  watch(
    () => authorId,
    (id) => {
      void loadUser(id)
    },
    { immediate: true },
  )

  const displayName = computed(() => {
    if (!user.value) return null
    const name = [user.value.name, user.value.lastname].filter(Boolean).join(' ').trim()
    if (name) return name
    if (user.value.email) return user.value.email
    return `User #${user.value.id}`
  })

  const isAgent = computed(() => user.value?.type === 1)
  const isEndUser = computed(() => user.value?.type === 2)

  return {
    user,
    loading,
    error,
    displayName,
    isAgent,
    isEndUser,
  }
}


