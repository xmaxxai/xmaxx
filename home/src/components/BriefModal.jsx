import { AnimatePresence, motion, useReducedMotion } from 'motion/react'
import { useEffect, useId } from 'react'
import { InteractiveLink } from './motion-primitives'

const briefPoints = [
  {
    title: 'System diagnosis',
    body: 'Map what is underperforming, fragmented, or invisible across the current operating environment.',
  },
  {
    title: 'Build path',
    body: 'Outline the software, AI, and hardware layers needed to move from signal collection to operational action.',
  },
  {
    title: 'Deployment posture',
    body: 'Define what can ship now, what should be staged, and what needs a longer integration runway.',
  },
]

export function BriefModal({ open, onClose }) {
  const titleId = useId()
  const reduceMotion = useReducedMotion()

  useEffect(() => {
    if (!open) {
      return undefined
    }

    const handleKeyDown = (event) => {
      if (event.key === 'Escape') {
        onClose()
      }
    }

    const previousOverflow = document.body.style.overflow
    document.body.style.overflow = 'hidden'
    window.addEventListener('keydown', handleKeyDown)

    return () => {
      document.body.style.overflow = previousOverflow
      window.removeEventListener('keydown', handleKeyDown)
    }
  }, [onClose, open])

  return (
    <AnimatePresence>
      {open ? (
        <motion.div
          className="overlay"
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          transition={{ duration: 0.2 }}
          onClick={onClose}
        >
          <motion.div
            className="brief-modal surface"
            role="dialog"
            aria-modal="true"
            aria-labelledby={titleId}
            initial={reduceMotion ? { opacity: 0 } : { opacity: 0, y: 24, scale: 0.98 }}
            animate={reduceMotion ? { opacity: 1 } : { opacity: 1, y: 0, scale: 1 }}
            exit={reduceMotion ? { opacity: 0 } : { opacity: 0, y: 18, scale: 0.98 }}
            transition={{ duration: 0.28, ease: [0.22, 1, 0.36, 1] }}
            onClick={(event) => event.stopPropagation()}
          >
            <div className="brief-modal__header">
              <div>
                <p className="eyebrow">Operator Brief</p>
                <h2 id={titleId}>Take the system from concept to operating posture.</h2>
              </div>
              <button
                type="button"
                className="icon-button"
                onClick={onClose}
                aria-label="Close brief dialog"
              >
                ×
              </button>
            </div>

            <p className="brief-modal__lede">
              XMAXX briefs are build-first conversations. We focus on what to
              instrument, what to automate, what to expose to operators, and
              what should stay under disciplined human control.
            </p>

            <div className="brief-grid">
              {briefPoints.map((item) => (
                <article key={item.title} className="brief-card">
                  <p className="brief-card__title">{item.title}</p>
                  <p>{item.body}</p>
                </article>
              ))}
            </div>

            <div className="brief-modal__actions">
              <InteractiveLink
                className="button button--solid"
                href="mailto:hello@xmaxx.ai?subject=Operator%20Brief"
              >
                hello@xmaxx.ai
              </InteractiveLink>
              <InteractiveLink
                className="button button--ghost"
                href="#stack"
                onClick={onClose}
              >
                Review platform stack
              </InteractiveLink>
            </div>
          </motion.div>
        </motion.div>
      ) : null}
    </AnimatePresence>
  )
}
