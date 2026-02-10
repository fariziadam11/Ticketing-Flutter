export interface CookieOptions {
  expires?: Date | number
  path?: string
  domain?: string
  secure?: boolean
  sameSite?: 'strict' | 'lax' | 'none'
}

export function setCookie(
  name: string,
  value: string,
  options: CookieOptions = {}
): void {
  let cookieString = `${encodeURIComponent(name)}=${encodeURIComponent(value)}`

  if (options.expires) {
    let expiresDate: Date
    if (typeof options.expires === 'number') {
      expiresDate = new Date()
      expiresDate.setTime(
        expiresDate.getTime() + options.expires * 24 * 60 * 60 * 1000
      )
    } else {
      expiresDate = options.expires
    }
    cookieString += `; expires=${expiresDate.toUTCString()}`
  }

  if (options.path) {
    cookieString += `; path=${options.path}`
  } else {
    cookieString += '; path=/'
  }

  if (options.domain) {
    cookieString += `; domain=${options.domain}`
  }

  if (options.secure) {
    cookieString += '; secure'
  }

  if (options.sameSite) {
    cookieString += `; samesite=${options.sameSite}`
  }

  document.cookie = cookieString
}

export function getCookie(name: string): string | null {
  const nameEQ = encodeURIComponent(name) + '='
  const cookies = document.cookie.split(';')

  for (let i = 0; i < cookies.length; i++) {
    const cookieItem = cookies[i]
    if (!cookieItem) continue
    
    let cookie = cookieItem.trim()
    if (cookie.indexOf(nameEQ) === 0) {
      return decodeURIComponent(cookie.substring(nameEQ.length))
    }
  }

  return null
}

export function removeCookie(name: string, options: Pick<CookieOptions, 'path' | 'domain'> = {}): void {
  setCookie(name, '', {
    ...options,
    expires: new Date(0),
  })
}

