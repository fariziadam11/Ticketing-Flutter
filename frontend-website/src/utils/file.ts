/**
 * Format file size in bytes to human readable format
 */
export function formatFileSize(bytes: number): string {
  if (bytes === 0) return '0 Bytes'
  const k = 1024
  const sizes = ['Bytes', 'KB', 'MB', 'GB']
  const i = Math.floor(Math.log(bytes) / Math.log(k))
  return Math.round((bytes / Math.pow(k, i)) * 100) / 100 + ' ' + sizes[i]
}

/**
 * Handle file input change event
 */
export function handleFileInputChange(
  event: Event,
  currentFiles: File[],
): File[] {
  const target = event.target as HTMLInputElement
  if (target.files && target.files.length > 0) {
    const newFiles = Array.from(target.files)
    return [...currentFiles, ...newFiles]
  }
  return currentFiles
}

/**
 * Remove file from array by index
 */
export function removeFileFromArray(files: File[], index: number): File[] {
  const newFiles = [...files]
  newFiles.splice(index, 1)
  return newFiles
}

