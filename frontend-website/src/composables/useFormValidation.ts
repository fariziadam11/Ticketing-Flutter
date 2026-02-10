import { ref, computed, type Ref } from 'vue'

export interface FormField {
  value: Ref<string>
  required?: boolean
  validator?: (value: string) => string | null
}

export interface UseFormValidationOptions {
  fields: Record<string, FormField>
}

export function useFormValidation(options: UseFormValidationOptions) {
  const { fields } = options
  const touched = ref<Record<string, boolean>>({})
  const submitted = ref(false)

  const markFieldTouched = (fieldName: string) => {
    touched.value[fieldName] = true
  }

  const markAllTouched = () => {
    submitted.value = true
    Object.keys(fields).forEach((key) => {
      touched.value[key] = true
    })
  }

  const reset = () => {
    submitted.value = false
    Object.keys(fields).forEach((key) => {
      touched.value[key] = false
    })
  }

  const getFieldError = (fieldName: string): string => {
    const field = fields[fieldName]
    if (!field) return ''

    const isTouched = touched.value[fieldName] || submitted.value
    if (!isTouched) return ''

    const value = field.value.value

    if (field.required && !value.trim()) {
      return 'This field is required'
    }

    if (field.validator) {
      return field.validator(value) || ''
    }

    return ''
  }

  const isFieldInvalid = (fieldName: string): boolean => {
    return !!getFieldError(fieldName)
  }

  const isFormValid = computed(() => {
    return Object.keys(fields).every((key) => {
      const field = fields[key]
      if (!field) return true
      if (field.required && !field.value.value.trim()) {
        return false
      }
      if (field.validator) {
        const error = field.validator(field.value.value)
        if (error) return false
      }
      return true
    })
  })

  return {
    touched,
    submitted,
    markFieldTouched,
    markAllTouched,
    reset,
    getFieldError,
    isFieldInvalid,
    isFormValid,
  }
}

