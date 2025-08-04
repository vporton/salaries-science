import React, { useEffect } from 'react'

interface SuccessNotificationProps {
  message: string
  isVisible: boolean
  onClose: () => void
  autoHideDuration?: number
}

export const SuccessNotification: React.FC<SuccessNotificationProps> = ({
  message,
  isVisible,
  onClose,
  autoHideDuration = 5000
}) => {
  useEffect(() => {
    if (isVisible && autoHideDuration > 0) {
      const timer = setTimeout(() => {
        onClose()
      }, autoHideDuration)

      return () => clearTimeout(timer)
    }
  }, [isVisible, autoHideDuration, onClose])

  if (!isVisible) return null

  return (
    <div className="fixed top-4 right-4 z-50">
      <div className="bg-green-500 text-white px-6 py-4 rounded-lg shadow-lg flex items-center gap-3">
        <div className="text-2xl">✅</div>
        <div>
          <p className="font-medium">{message}</p>
        </div>
        <button
          onClick={onClose}
          className="ml-4 text-white hover:text-gray-200 transition-colors"
        >
          ✕
        </button>
      </div>
    </div>
  )
} 