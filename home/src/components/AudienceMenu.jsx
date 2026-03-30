import { AnimatePresence, motion, useReducedMotion } from 'motion/react'
import { useEffect, useRef, useState } from 'react'

export function AudienceMenu({ activeValue, onSelect, options }) {
  const [open, setOpen] = useState(false)
  const menuRef = useRef(null)
  const reduceMotion = useReducedMotion()
  const activeOption = options.find((option) => option.id === activeValue)

  useEffect(() => {
    if (!open) {
      return undefined
    }

    const handleKeyDown = (event) => {
      if (event.key === 'Escape') {
        setOpen(false)
      }
    }

    const handlePointerDown = (event) => {
      if (menuRef.current && !menuRef.current.contains(event.target)) {
        setOpen(false)
      }
    }

    window.addEventListener('keydown', handleKeyDown)
    document.addEventListener('pointerdown', handlePointerDown)

    return () => {
      window.removeEventListener('keydown', handleKeyDown)
      document.removeEventListener('pointerdown', handlePointerDown)
    }
  }, [open])

  return (
    <div ref={menuRef} className="audience-menu">
      <motion.button
        type="button"
        className="button button--ghost audience-menu__trigger"
        aria-expanded={open}
        aria-haspopup="menu"
        onClick={() => setOpen((current) => !current)}
        whileHover={reduceMotion ? undefined : { y: -2 }}
        whileTap={reduceMotion ? undefined : { scale: 0.985 }}
        transition={{ duration: 0.18 }}
      >
        <span>Audience lens</span>
        <strong>{activeOption?.label}</strong>
      </motion.button>

      <AnimatePresence>
        {open ? (
          <motion.div
            className="audience-menu__panel surface"
            role="menu"
            initial={reduceMotion ? { opacity: 0 } : { opacity: 0, y: 12, scale: 0.98 }}
            animate={reduceMotion ? { opacity: 1 } : { opacity: 1, y: 0, scale: 1 }}
            exit={reduceMotion ? { opacity: 0 } : { opacity: 0, y: 10, scale: 0.98 }}
            transition={{ duration: 0.2, ease: [0.22, 1, 0.36, 1] }}
          >
            {options.map((option) => (
              <motion.button
                key={option.id}
                type="button"
                className={`audience-option${
                  option.id === activeValue ? ' audience-option--active' : ''
                }`}
                role="menuitem"
                onClick={() => {
                  onSelect(option.id)
                  setOpen(false)
                }}
                whileHover={reduceMotion ? undefined : { x: 4 }}
                whileTap={reduceMotion ? undefined : { scale: 0.99 }}
                transition={{ duration: 0.18 }}
              >
                <span>{option.label}</span>
                <small>{option.description}</small>
              </motion.button>
            ))}
          </motion.div>
        ) : null}
      </AnimatePresence>
    </div>
  )
}
