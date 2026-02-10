type LogLevel = 'debug' | 'info' | 'warn' | 'error'

interface LogEntry {
  level: LogLevel
  message: string
  data?: any
  timestamp: string
}

class Logger {
  private isDevelopment = import.meta.env.DEV
  private logs: LogEntry[] = []
  private maxLogs = 100

  private formatMessage(level: LogLevel, message: string): string {
    const timestamp = new Date().toISOString()
    return `[${timestamp}] [${level.toUpperCase()}] ${message}`
  }

  private addLog(level: LogLevel, message: string, data?: any): void {
    if (!this.isDevelopment) return

    const entry: LogEntry = {
      level,
      message,
      data,
      timestamp: new Date().toISOString(),
    }

    this.logs.push(entry)
    if (this.logs.length > this.maxLogs) {
      this.logs.shift()
    }
  }

  debug(message: string, ...args: any[]): void {
    this.addLog('debug', message, args.length > 0 ? args : undefined)
  }

  info(message: string, ...args: any[]): void {
    this.addLog('info', message, args.length > 0 ? args : undefined)
  }

  warn(message: string, ...args: any[]): void {
    this.addLog('warn', message, args.length > 0 ? args : undefined)
  }

  error(message: string, error?: Error | any, ...args: any[]): void {
    const errorData = error instanceof Error 
      ? { 
          errorMessage: error.message, 
          stack: error.stack, 
          name: error.name,
          ...(error as any),
        }
      : error
    this.addLog('error', message, errorData || (args.length > 0 ? args : undefined))
  }

  getLogs(level?: LogLevel): LogEntry[] {
    if (level) {
      return this.logs.filter(log => log.level === level)
    }
    return [...this.logs]
  }

  clearLogs(): void {
    this.logs = []
  }
}

export const logger = new Logger()

export type { LogLevel, LogEntry }

