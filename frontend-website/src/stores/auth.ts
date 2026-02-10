import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import type { AuthResponse } from '@/api/auth'
import { getCookie, setCookie, removeCookie } from '@/utils/cookies'
import { COOKIE_NAMES, COOKIE_OPTIONS } from '@/utils/constants'

export const useAuthStore = defineStore('auth', () => {
  const getUserFromCookie = (): {
    name: string
    lastname: string
    email: string
  } | null => {
    const stored = getCookie(COOKIE_NAMES.USER)
    if (stored) {
      try {
        return JSON.parse(stored)
      } catch {
        return null
      }
    }
    return null
  }

  const token = ref<string | null>(getCookie(COOKIE_NAMES.ACCESS_TOKEN))
  const refreshToken = ref<string | null>(getCookie(COOKIE_NAMES.REFRESH_TOKEN))
  const user = ref<{
    name: string
    lastname: string
    email: string
  } | null>(getUserFromCookie())

  const isAuthenticated = computed(() => !!token.value)

  const fullName = computed(() => {
    if (!user.value) return ''
    return `${user.value.name} ${user.value.lastname}`.trim()
  })

  function setAuth(authData: AuthResponse) {
    token.value = authData.token
    refreshToken.value = authData.refresh_token || null
    user.value = {
      name: authData.name,
      lastname: authData.lastname,
      email: authData.email,
    }

    setCookie(COOKIE_NAMES.ACCESS_TOKEN, authData.token, {
      expires: COOKIE_OPTIONS.EXPIRES_DAYS,
      path: COOKIE_OPTIONS.PATH,
      secure: import.meta.env.PROD,
      sameSite: COOKIE_OPTIONS.SAME_SITE,
    })
    if (authData.refresh_token) {
      setCookie(COOKIE_NAMES.REFRESH_TOKEN, authData.refresh_token, {
        expires: COOKIE_OPTIONS.EXPIRES_DAYS,
        path: COOKIE_OPTIONS.PATH,
        secure: import.meta.env.PROD,
        sameSite: COOKIE_OPTIONS.SAME_SITE,
      })
    }
    setCookie(COOKIE_NAMES.USER, JSON.stringify(user.value), {
      expires: COOKIE_OPTIONS.EXPIRES_DAYS,
      path: COOKIE_OPTIONS.PATH,
      secure: import.meta.env.PROD,
      sameSite: COOKIE_OPTIONS.SAME_SITE,
    })
  }

  function clearAuth() {
    token.value = null
    refreshToken.value = null
    user.value = null

    removeCookie(COOKIE_NAMES.ACCESS_TOKEN, { path: COOKIE_OPTIONS.PATH })
    removeCookie(COOKIE_NAMES.REFRESH_TOKEN, { path: COOKIE_OPTIONS.PATH })
    removeCookie(COOKIE_NAMES.USER, { path: COOKIE_OPTIONS.PATH })
  }

  function initializeAuth() {
    const cookieToken = getCookie(COOKIE_NAMES.ACCESS_TOKEN)
    const cookieRefreshToken = getCookie(COOKIE_NAMES.REFRESH_TOKEN)
    const cookieUser = getCookie(COOKIE_NAMES.USER)

    if (cookieToken) {
      token.value = cookieToken
    }
    if (cookieRefreshToken) {
      refreshToken.value = cookieRefreshToken
    }
    if (cookieUser) {
      try {
        user.value = JSON.parse(cookieUser)
      } catch {
        user.value = null
      }
    }
  }

  return {
    token,
    refreshToken,
    user,
    isAuthenticated,
    fullName,
    setAuth,
    clearAuth,
    initializeAuth,
  }
})

