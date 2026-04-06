import { motion, useReducedMotion } from 'motion/react'

const ease = [0.22, 1, 0.36, 1]
const viewport = { once: true, amount: 0.12 }

export function Reveal({
  as: Component = motion.div,
  children,
  className,
  delay = 0,
  ...props
}) {
  const reduceMotion = useReducedMotion()

  return (
    <Component
      className={className}
      initial={reduceMotion ? { opacity: 0 } : { opacity: 0, y: 34 }}
      whileInView={reduceMotion ? { opacity: 1 } : { opacity: 1, y: 0 }}
      viewport={viewport}
      transition={{ duration: 0.72, delay, ease }}
      {...props}
    >
      {children}
    </Component>
  )
}

export function StaggerGroup({
  as: Component = motion.div,
  children,
  className,
  delayChildren = 0.12,
  staggerChildren = 0.16,
  ...props
}) {
  const reduceMotion = useReducedMotion()
  const variants = reduceMotion
    ? undefined
    : {
        hidden: { opacity: 1 },
        visible: {
          opacity: 1,
          transition: { delayChildren, staggerChildren },
        },
      }

  return (
    <Component
      className={className}
      variants={variants}
      initial={reduceMotion ? false : 'hidden'}
      whileInView={reduceMotion ? undefined : 'visible'}
      viewport={viewport}
      {...props}
    >
      {children}
    </Component>
  )
}

export function StaggerItem({
  as: Component = motion.div,
  children,
  className,
  ...props
}) {
  const reduceMotion = useReducedMotion()

  return (
    <Component
      className={className}
      variants={
        reduceMotion
          ? undefined
          : {
              hidden: { opacity: 0, y: 26 },
              visible: {
                opacity: 1,
                y: 0,
                transition: { duration: 0.62, ease },
              },
            }
      }
      {...props}
    >
      {children}
    </Component>
  )
}

export function InteractiveLink({
  as: Component = motion.a,
  children,
  className,
  ...props
}) {
  const reduceMotion = useReducedMotion()

  return (
    <Component
      className={className}
      whileHover={reduceMotion ? undefined : { y: -1, scale: 1.02 }}
      whileTap={reduceMotion ? undefined : { scale: 0.985 }}
      transition={{ duration: 0.18, ease }}
      {...props}
    >
      {children}
    </Component>
  )
}

export function InteractiveSurface({
  as: Component = motion.article,
  children,
  className,
  lift = 4,
  ...props
}) {
  const reduceMotion = useReducedMotion()

  return (
    <Component
      className={className}
      whileHover={reduceMotion ? undefined : { y: -lift, scale: 1.02 }}
      whileTap={reduceMotion ? undefined : { scale: 0.992 }}
      transition={{ duration: 0.2, ease }}
      {...props}
    >
      {children}
    </Component>
  )
}

export function SkeletonBlock({ className, ...props }) {
  const reduceMotion = useReducedMotion()

  return (
    <motion.div
      className={`skeleton${className ? ` ${className}` : ''}`}
      animate={reduceMotion ? { opacity: 0.78 } : { opacity: [0.44, 0.92, 0.44] }}
      transition={
        reduceMotion
          ? { duration: 0 }
          : { duration: 1.4, repeat: Number.POSITIVE_INFINITY, ease: 'easeInOut' }
      }
      {...props}
    />
  )
}
