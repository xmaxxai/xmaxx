import { AnimatePresence, motion, useReducedMotion } from 'motion/react'
import { useEffect, useId, useRef, useState } from 'react'
import heroImage from './assets/hero.png'
import { BriefModal } from './components/BriefModal'
import { ProfileWorkspace } from './components/ProfileWorkspace'
import {
  InteractiveLink,
  InteractiveSurface,
  Reveal,
  SkeletonBlock,
  StaggerGroup,
  StaggerItem,
} from './components/motion-primitives'
import './index.css'

const navLinks = [
  { label: 'Platform', href: '#platform' },
  { label: 'Profile', href: '#profile' },
  { label: 'Focus', href: '#focus' },
  { label: 'Stack', href: '#stack' },
]

const xmaxxGptUrl =
  'https://chatgpt.com/g/g-69ca32256f08819189506732a7541301-xmaxx'

const metrics = [
  {
    value: '24/7',
    label: 'Operator-aware automation, not passive dashboards.',
  },
  {
    value: '<60s',
    label: 'From signal to surfaced action across the runtime path.',
  },
  {
    value: '3X',
    label: 'Software, AI, and hardware designed as one system.',
  },
  {
    value: 'TLS',
    label: 'Production ingress, live cluster, and trusted HTTPS in motion.',
  },
]

const lenses = [
  {
    id: 'operators',
    label: 'Operators',
    description: 'Pressure-tested control',
    heading: 'Make the operating surface calm, legible, and fast under load.',
    body: 'Operators need interfaces that stay clear when conditions change. XMAXX emphasizes observability, override paths, and actions that can be trusted under pressure.',
  },
  {
    id: 'partners',
    label: 'Partners',
    description: 'Signal with business clarity',
    heading: 'Show external stakeholders a system that is credible, measurable, and integration-ready.',
    body: 'Partners and vendors need disciplined visibility into what is deployed, what can be integrated, and how value will be measured over time.',
  },
  {
    id: 'builders',
    label: 'Builders',
    description: 'Ship the platform cleanly',
    heading: 'Treat infrastructure, release flow, and UI polish as one engineering concern.',
    body: 'Builders need a stack that can move from local iteration to cluster delivery without turning deployment, motion, and accessibility into separate projects.',
  },
]

const capabilities = [
  {
    id: 'telemetry',
    title: 'Field telemetry',
    eyebrow: 'Signal plane',
    body: 'Translate water, air, environment, and equipment behavior into inputs the system can actually reason about.',
    scores: { operators: 95, partners: 72, builders: 82 },
  },
  {
    id: 'control',
    title: 'Operator control surfaces',
    eyebrow: 'Human override',
    body: 'Keep escalation, intervention, and auditability close to the interface rather than buried behind automation.',
    scores: { operators: 97, partners: 70, builders: 86 },
  },
  {
    id: 'delivery',
    title: 'Infrastructure that ships like a product',
    eyebrow: 'Platform delivery',
    body: 'Terraform, Docker, K3s, and Helm are treated as part of the product system, not back-office chores.',
    scores: { operators: 79, partners: 68, builders: 99 },
  },
  {
    id: 'partner',
    title: 'Partner-ready integration layers',
    eyebrow: 'External collaboration',
    body: 'Expose clean operational surfaces to vendors, partners, and future ecosystem collaborators without losing discipline.',
    scores: { operators: 61, partners: 96, builders: 74 },
  },
  {
    id: 'presence',
    title: 'Premium digital presence',
    eyebrow: 'Public interface',
    body: 'The public surface should look deliberate and perform with the same clarity as the systems behind it.',
    scores: { operators: 57, partners: 88, builders: 75 },
  },
  {
    id: 'hardware',
    title: 'Software-to-hardware loop',
    eyebrow: 'Physical systems',
    body: 'Use AI and software to shape how hardware senses, reports, and responds instead of treating devices as isolated endpoints.',
    scores: { operators: 91, partners: 84, builders: 89 },
  },
]

const stackLayers = [
  {
    title: 'Terraform',
    body: 'AWS networking, instance provisioning, load balancers, and security groups are managed as code so the platform stays reproducible.',
  },
  {
    title: 'K3s Cluster',
    body: 'The runtime is lightweight but real: ingress, workers, TLS automation, and app delivery run inside a live Kubernetes surface.',
  },
  {
    title: 'Docker',
    body: 'The `home` app is built into a portable image so the frontend ships as a deployable artifact, not a manual file transfer.',
  },
  {
    title: 'Helm',
    body: 'Release behavior, service rules, and ingress settings are captured in the chart so the site can evolve without cluster drift.',
  },
]

const proofPoints = [
  'AI surfaces for water, air, and environmental systems',
  'Operational control planes for teams under real constraints',
  'High-trust interfaces that still feel premium and modern',
]

const authProviders = [
  {
    id: 'github',
    label: 'GitHub',
    eyebrow: 'Deploy and source control',
    description:
      'Use repo-native identity for operator access, release workflows, and deployment-adjacent actions.',
  },
  {
    id: 'google',
    label: 'Google',
    eyebrow: 'Workspace identity',
    description:
      'Use Google identity for email-based access now and future Workspace-connected operator flows later.',
  },
]

function buildDefaultProviders() {
  return Object.fromEntries(
    authProviders.map(({ id }) => [
      id,
      {
        configured: false,
        configuredReason: '',
      },
    ]),
  )
}

function buildInitialAuthState() {
  return {
    loading: true,
    authenticated: false,
    configured: false,
    configuredReason: '',
    provider: '',
    providers: buildDefaultProviders(),
    user: null,
    error: '',
  }
}

function getProviderLabel(provider) {
  return authProviders.find((entry) => entry.id === provider)?.label ?? 'OAuth'
}

function getConfiguredProviders(authState) {
  return authProviders.filter(({ id }) => authState.providers[id]?.configured)
}

function getProviderState(authState, provider) {
  return authState.providers[provider] ?? {
    configured: false,
    configuredReason: '',
  }
}

function getAuthErrorMessage(provider, code) {
  const label = getProviderLabel(provider)

  switch (code) {
    case 'access_denied':
      return `${label} sign-in was canceled before completion.`
    case 'exchange_failed':
      return `${label} sign-in failed while the backend was exchanging credentials.`
    case 'invalid_secret_format':
      return `The backend ${label} OAuth client secret is not a valid client secret string.`
    case 'missing_code':
      return `${label} did not return an authorization code for this session.`
    case 'missing_client_id':
      return `The backend is missing the ${label} OAuth client ID.`
    case 'missing_client_secret':
      return `The backend is missing the ${label} OAuth client secret.`
    case 'missing_redirect_uri':
      return `The backend is missing the ${label} OAuth redirect URI configuration.`
    case 'no_providers_configured':
      return 'No sign-in providers are configured on the backend yet.'
    case 'not_configured':
      return `${label} auth is not configured on the backend yet.`
    case 'state_mismatch':
      return `${label} sign-in could not be verified. Start a new login attempt.`
    default:
      return `${label} auth returned an unknown error.`
  }
}

function getProviderStatusCopy(provider, configuredReason) {
  if (!configuredReason) {
    return 'Ready for sign-in.'
  }

  return getAuthErrorMessage(provider, configuredReason)
}

function buildAuthReturnPath() {
  if (typeof window === 'undefined') {
    return '/'
  }

  const url = new URL(window.location.href)
  ;['auth', 'login', 'logout', 'error'].forEach((key) => url.searchParams.delete(key))

  const query = url.searchParams.toString()
  return `${url.pathname}${query ? `?${query}` : ''}${url.hash}` || '/'
}

function buildAuthNotice({ provider, error, login, logout }) {
  if (!provider) {
    return null
  }

  const label = getProviderLabel(provider)

  if (login === 'success') {
    return {
      tone: 'success',
      title: `${label} connected`,
      body: `This browser now has an active ${label}-backed session on the XMAXX home surface.`,
    }
  }

  if (logout === 'success') {
    return {
      tone: 'info',
      title: 'Signed out',
      body: `The ${label} session for this browser has been cleared.`,
    }
  }

  if (error) {
    return {
      tone: 'error',
      title: `${label} login failed`,
      body: getAuthErrorMessage(provider, error),
    }
  }

  return null
}

function readAuthNotice() {
  if (typeof window === 'undefined') {
    return null
  }

  const url = new URL(window.location.href)
  const provider = url.searchParams.get('auth')

  const error = url.searchParams.get('error')
  const login = url.searchParams.get('login')
  const logout = url.searchParams.get('logout')

  if (!provider || (!error && !login && !logout)) {
    return null
  }

  const notice = buildAuthNotice({ provider, error, login, logout })

  ;['auth', 'login', 'logout', 'error'].forEach((key) => url.searchParams.delete(key))
  const query = url.searchParams.toString()
  const nextUrl = `${url.pathname}${query ? `?${query}` : ''}${url.hash}`
  window.history.replaceState({}, document.title, nextUrl || '/')

  return notice
}

async function requestAuthSession(signal) {
  const response = await fetch('/api/auth/session/', {
    credentials: 'same-origin',
    headers: { Accept: 'application/json' },
    signal,
  })

  if (!response.ok) {
    throw new Error(`Auth session request failed with status ${response.status}`)
  }

  const payload = await response.json()
  const providerState = buildDefaultProviders()

  authProviders.forEach(({ id }) => {
    providerState[id] = {
      configured: Boolean(payload.providers?.[id]?.configured),
      configuredReason: payload.providers?.[id]?.configuredReason ?? '',
    }
  })

  return {
    loading: false,
    authenticated: Boolean(payload.authenticated),
    configured: Boolean(payload.configured),
    configuredReason: payload.configuredReason ?? '',
    provider: payload.provider ?? '',
    providers: providerState,
    user: payload.user ?? null,
    error: '',
  }
}

async function syncAuthSession(setAuthState, signal) {
  try {
    const payload = await requestAuthSession(signal)
    setAuthState(payload)
  } catch (error) {
    if (signal?.aborted) {
      return
    }

    setAuthState({
      ...buildInitialAuthState(),
      loading: false,
      error: error instanceof Error ? error.message : 'Unable to load auth session',
    })
  }
}

function openAuthPopup(provider, url) {
  const width = 560
  const height = 720
  const left = Math.max(window.screenX + (window.outerWidth - width) / 2, 0)
  const top = Math.max(window.screenY + (window.outerHeight - height) / 2, 0)
  const features = [
    'popup=yes',
    'resizable=yes',
    'scrollbars=yes',
    `width=${Math.round(width)}`,
    `height=${Math.round(height)}`,
    `left=${Math.round(left)}`,
    `top=${Math.round(top)}`,
  ].join(',')

  return window.open(url, `xmaxx-auth-${provider}`, features)
}

function getUserInitial(authState) {
  const seed =
    authState.user?.name ||
    authState.user?.email ||
    authState.user?.login ||
    getProviderLabel(authState.provider)

  return seed.slice(0, 1).toUpperCase()
}

function getUserSecondaryLabel(authState) {
  const providerLabel = getProviderLabel(authState.provider)

  if (authState.provider === 'github' && authState.user?.login) {
    return `${providerLabel} • @${authState.user.login}`
  }

  if (authState.user?.email) {
    return `${providerLabel} • ${authState.user.email}`
  }

  if (authState.user?.login) {
    return `${providerLabel} • ${authState.user.login}`
  }

  return providerLabel
}

function AuthControls({
  authState,
  onOpenLogin,
  onLogout,
  stacked = false,
  onAction,
  busyProvider = '',
}) {
  const className = `auth-actions${stacked ? ' auth-actions--stacked' : ''}`
  const availableProviders = getConfiguredProviders(authState)
  const secondaryLabel = getUserSecondaryLabel(authState)

  const handleLogin = () => {
    onAction?.()
    onOpenLogin()
  }

  const handleLogout = () => {
    onAction?.()
    onLogout()
  }

  if (authState.loading) {
    return (
      <div className={className}>
        <div className="session-pill" aria-live="polite">
          <span className="session-pill__status" />
          <span>Checking operator access</span>
        </div>
      </div>
    )
  }

  if (authState.authenticated && authState.user) {
    return (
      <div className={className}>
        <a
          className="session-pill session-pill--link"
          href={authState.user.profile_url || '#top'}
          target="_blank"
          rel="noreferrer"
        >
          {authState.user.avatar_url ? (
            <img
              className="session-pill__avatar"
              src={authState.user.avatar_url}
              alt={`${authState.user.name} avatar`}
            />
          ) : (
            <span className="session-pill__avatar session-pill__avatar--fallback">
              {getUserInitial(authState)}
            </span>
          )}
          <span className="session-pill__copy">
            <strong>{authState.user.name}</strong>
            <small>{secondaryLabel}</small>
          </span>
        </a>

        <motion.button
          type="button"
          className="button button--ghost button--small"
          onClick={handleLogout}
          whileTap={{ scale: 0.98 }}
        >
          Sign out
        </motion.button>
      </div>
    )
  }

  return (
    <div className={className}>
      <motion.button
        type="button"
        className="button button--ghost button--small"
        onClick={handleLogin}
        disabled={!authState.configured || Boolean(authState.error) || Boolean(busyProvider)}
        whileTap={{
          scale:
            authState.configured && !authState.error && !busyProvider
              ? 0.98
              : 1,
        }}
      >
        {authState.error
          ? 'Auth unavailable'
          : busyProvider
            ? `Finishing ${getProviderLabel(busyProvider)}…`
            : availableProviders.length > 0
              ? 'Choose sign-in'
              : 'Auth not configured'}
      </motion.button>
    </div>
  )
}

function AuthCard({ authState, notice, onOpenLogin, onLogout, busyProvider }) {
  const isAuthenticated = authState.authenticated && authState.user
  const configuredProviders = getConfiguredProviders(authState)
  const configuredProviderNames = configuredProviders.map(({ label }) => label).join(' or ')
  const title = authState.loading
    ? 'Checking operator access for this browser.'
    : authState.error
      ? 'The auth session endpoint is not responding yet.'
      : isAuthenticated
        ? `Welcome back, ${authState.user.name}.`
        : authState.configured
          ? configuredProviders.length > 1
            ? 'Choose Google or GitHub to unlock the private operator surface.'
            : `Sign in with ${configuredProviderNames} to unlock the private operator surface.`
          : 'Operator auth is staged but not configured yet.'

  const body = authState.loading
    ? 'The landing page is verifying whether a session already exists on the home backend.'
    : authState.error
      ? 'The frontend could not load session state from `/api/auth/session/`, so login actions stay disabled until the backend route is reachable.'
      : isAuthenticated
        ? 'This session is tied to the deployed Django backend, so private workflows can recognize the signed-in operator across the same `xmaxx.ai` origin.'
        : authState.configured
          ? 'The auth surface opens a provider chooser in-place, then hands sign-in to a popup so the backend can finish the OAuth exchange without bouncing the landing page away from the user.'
          : 'Once at least one provider has valid OAuth settings in the backend secret, this control will enable the deployed callback flow.'

  const badgeClass = authState.loading
    ? 'auth-badge auth-badge--muted'
    : authState.error
      ? 'auth-badge auth-badge--error'
      : isAuthenticated
        ? 'auth-badge auth-badge--live'
        : authState.configured
          ? 'auth-badge auth-badge--warm'
          : 'auth-badge auth-badge--muted'

  const badgeLabel = authState.loading
    ? 'Checking'
    : authState.error
      ? 'Unavailable'
      : isAuthenticated
        ? 'Connected'
        : authState.configured
          ? 'Ready'
          : 'Pending'

  return (
    <div className="auth-card surface">
      <div className="auth-card__header">
        <div>
          <p className="eyebrow">Operator access</p>
          <h3>{title}</h3>
        </div>
        <span className={badgeClass}>{badgeLabel}</span>
      </div>

      <p className="auth-card__body">{body}</p>

       <div className="auth-provider-strip" aria-label="Available sign-in providers">
        {authProviders.map((provider) => {
          const providerState = getProviderState(authState, provider.id)

          return (
            <div
              key={provider.id}
              className={`auth-provider-chip${
                providerState.configured ? ' auth-provider-chip--live' : ''
              }`}
            >
              <strong>{provider.label}</strong>
              <small>{providerState.configured ? 'Ready' : 'Setup needed'}</small>
            </div>
          )
        })}
      </div>

      {notice ? (
        <div className={`auth-notice auth-notice--${notice.tone}`} role="status">
          <strong>{notice.title}</strong>
          <span>{notice.body}</span>
        </div>
      ) : null}

      <AuthControls
        authState={authState}
        onOpenLogin={onOpenLogin}
        onLogout={onLogout}
        busyProvider={busyProvider}
      />
    </div>
  )
}

function AuthModal({ open, onClose, authState, onSelectProvider, busyProvider = '' }) {
  if (!open) {
    return null
  }

  return (
    <motion.div
      className="overlay"
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      transition={{ duration: 0.2 }}
      onClick={onClose}
    >
      <motion.div
        className="auth-modal surface"
        initial={{ opacity: 0, y: 16, scale: 0.98 }}
        animate={{ opacity: 1, y: 0, scale: 1 }}
        exit={{ opacity: 0, y: 16, scale: 0.98 }}
        transition={{ duration: 0.24, ease: [0.22, 1, 0.36, 1] }}
        onClick={(event) => event.stopPropagation()}
      >
        <div className="auth-modal__header">
          <div>
            <p className="eyebrow">Choose sign-in</p>
            <h2>Select the identity system that should own this browser session.</h2>
          </div>
          <button
            type="button"
            className="icon-button"
            onClick={onClose}
            aria-label="Close sign-in options"
          >
            ×
          </button>
        </div>

        <p className="auth-modal__lede">
          The backend completes the OAuth code exchange on `xmaxx.ai` and sets the
          session cookie there. The popup closes automatically when the flow
          finishes.
        </p>

        {authState.error ? (
          <div className="auth-notice auth-notice--error" role="status">
            <strong>Auth session unavailable</strong>
            <span>{authState.error}</span>
          </div>
        ) : null}

        {busyProvider ? (
          <div className="auth-notice auth-notice--info" role="status">
            <strong>Complete {getProviderLabel(busyProvider)} sign-in</strong>
            <span>
              Finish the flow in the popup window. This page will refresh the
              session automatically when the provider returns.
            </span>
          </div>
        ) : null}

        <div className="auth-provider-grid">
          {authProviders.map((provider) => {
            const providerState = getProviderState(authState, provider.id)
            const disabled =
              Boolean(authState.error) ||
              !providerState.configured ||
              Boolean(busyProvider)

            return (
              <motion.button
                key={provider.id}
                type="button"
                className={`auth-provider-option${
                  providerState.configured ? ' auth-provider-option--ready' : ''
                }`}
                disabled={disabled}
                onClick={() => onSelectProvider(provider.id)}
                whileTap={{ scale: disabled ? 1 : 0.985 }}
              >
                <div className="auth-provider-option__header">
                  <div>
                    <p className="auth-provider-option__eyebrow">{provider.eyebrow}</p>
                    <h3>{provider.label}</h3>
                  </div>
                  <span
                    className={`auth-provider-option__status${
                      providerState.configured
                        ? ' auth-provider-option__status--ready'
                        : ''
                    }`}
                  >
                    {providerState.configured ? 'Ready' : 'Setup needed'}
                  </span>
                </div>
                <p>{provider.description}</p>
                <span className="auth-provider-option__hint">
                  {getProviderStatusCopy(provider.id, providerState.configuredReason)}
                </span>
              </motion.button>
            )
          })}
        </div>
      </motion.div>
    </motion.div>
  )
}

function HeroPreview({ ready, onReady }) {
  const reduceMotion = useReducedMotion()

  return (
    <div className="hero-visual surface surface--dark">
      <div className="hero-visual__header">
        <span>Live surface</span>
        <span>React • Motion • Helm</span>
      </div>

      <div className="hero-visual__media">
        <AnimatePresence>
          {!ready ? (
            <motion.div
              key="skeleton"
              className="hero-visual__skeleton"
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              transition={{ duration: 0.22 }}
            >
              <SkeletonBlock className="hero-visual__skeleton-frame" />
              <div className="hero-visual__skeleton-copy">
                <SkeletonBlock className="hero-visual__skeleton-line hero-visual__skeleton-line--long" />
                <SkeletonBlock className="hero-visual__skeleton-line" />
                <SkeletonBlock className="hero-visual__skeleton-line hero-visual__skeleton-line--short" />
              </div>
            </motion.div>
          ) : null}
        </AnimatePresence>

        <motion.img
          className="hero-visual__image"
          src={heroImage}
          alt="Abstract XMAXX system composition showing layered environmental and digital structure."
          initial={false}
          animate={{ opacity: ready ? 1 : 0, scale: ready ? 1 : 1.03 }}
          transition={{ duration: 0.7, ease: [0.22, 1, 0.36, 1] }}
          onLoad={onReady}
        />

        <motion.div
          className="hero-badge hero-badge--top"
          animate={
            reduceMotion ? undefined : { y: [0, -6, 0], rotate: [0, -1, 0] }
          }
          transition={
            reduceMotion
              ? undefined
              : { duration: 5.6, repeat: Number.POSITIVE_INFINITY, ease: 'easeInOut' }
          }
        >
          ACME-secured HTTPS
        </motion.div>
        <motion.div
          className="hero-badge hero-badge--bottom"
          animate={reduceMotion ? undefined : { y: [0, 8, 0] }}
          transition={
            reduceMotion
              ? undefined
              : { duration: 6.2, repeat: Number.POSITIVE_INFINITY, ease: 'easeInOut' }
          }
        >
          Runtime-ready infrastructure
        </motion.div>
      </div>

      <div className="hero-visual__footer">
        <div>
          <p className="hero-visual__label">Stack posture</p>
          <strong>Production-minded from day one</strong>
        </div>
        <p>
          The public surface is already backed by a live cluster, load-balanced
          ingress, and persisted certificate automation.
        </p>
      </div>
    </div>
  )
}

function App() {
  const [activeLens, setActiveLens] = useState('operators')
  const [isBriefOpen, setIsBriefOpen] = useState(false)
  const [isAuthModalOpen, setIsAuthModalOpen] = useState(false)
  const [isMenuOpen, setIsMenuOpen] = useState(false)
  const [heroReady, setHeroReady] = useState(false)
  const [authNotice, setAuthNotice] = useState(() => readAuthNotice())
  const [authState, setAuthState] = useState(buildInitialAuthState)
  const [authBusyProvider, setAuthBusyProvider] = useState('')
  const menuId = useId()
  const authPopupMonitorRef = useRef(0)

  useEffect(() => {
    if (!isMenuOpen) {
      return undefined
    }

    const handleKeyDown = (event) => {
      if (event.key === 'Escape') {
        setIsMenuOpen(false)
      }
    }

    const previousOverflow = document.body.style.overflow
    document.body.style.overflow = 'hidden'
    window.addEventListener('keydown', handleKeyDown)

    return () => {
      document.body.style.overflow = previousOverflow
      window.removeEventListener('keydown', handleKeyDown)
    }
  }, [isMenuOpen])

  useEffect(() => {
    const controller = new AbortController()

    void syncAuthSession(setAuthState, controller.signal)

    return () => controller.abort()
  }, [])

  useEffect(() => {
    const handleMessage = (event) => {
      if (event.origin !== window.location.origin) {
        return
      }

      if (event.data?.source !== 'xmaxx-oauth') {
        return
      }

      if (authPopupMonitorRef.current) {
        window.clearInterval(authPopupMonitorRef.current)
        authPopupMonitorRef.current = 0
      }

      setAuthBusyProvider('')
      setIsAuthModalOpen(false)

      const notice = buildAuthNotice(event.data)

      if (notice) {
        setAuthNotice(notice)
      }

      void syncAuthSession(setAuthState)
    }

    window.addEventListener('message', handleMessage)

    return () => {
      window.removeEventListener('message', handleMessage)
    }
  }, [])

  useEffect(() => {
    return () => {
      if (authPopupMonitorRef.current) {
        window.clearInterval(authPopupMonitorRef.current)
      }
    }
  }, [])

  const rankedCapabilities = [...capabilities].sort(
    (left, right) => right.scores[activeLens] - left.scores[activeLens],
  )
  const activeLensData =
    lenses.find((lens) => lens.id === activeLens) ?? lenses[0]

  const handleOpenLogin = () => {
    setIsAuthModalOpen(true)
  }

  const handleProviderLogin = (provider) => {
    const nextPath = buildAuthReturnPath()
    const popupUrl = `/api/auth/${provider}/login/?popup=1&next=${encodeURIComponent(nextPath)}`
    const fallbackUrl = `/api/auth/${provider}/login/?next=${encodeURIComponent(nextPath)}`
    const popup = openAuthPopup(provider, popupUrl)

    if (!popup) {
      window.location.assign(fallbackUrl)
      return
    }

    if (authPopupMonitorRef.current) {
      window.clearInterval(authPopupMonitorRef.current)
    }

    popup.focus()
    setAuthBusyProvider(provider)
    setAuthNotice({
      tone: 'info',
      title: `Continue with ${getProviderLabel(provider)}`,
      body: 'Finish sign-in in the popup window. This page will refresh the session when the provider returns.',
    })
    setIsAuthModalOpen(false)

    authPopupMonitorRef.current = window.setInterval(() => {
      if (!popup.closed) {
        return
      }

      window.clearInterval(authPopupMonitorRef.current)
      authPopupMonitorRef.current = 0
      setAuthBusyProvider('')
      void syncAuthSession(setAuthState)
    }, 500)
  }

  const handleLogout = () => {
    window.location.assign(
      `/api/auth/logout/?next=${encodeURIComponent(buildAuthReturnPath())}`,
    )
  }

  return (
    <>
      <main className="app-shell">
        <div className="ambient ambient--one" />
        <div className="ambient ambient--two" />

        <header className="topbar surface">
          <a className="brand" href="#top">
            <span>XMAXX</span>
            <small>software • hardware • AI</small>
          </a>

          <div className="topbar__dock">
            <nav className="topnav" aria-label="Primary">
              {navLinks.map((link) => (
                <InteractiveLink key={link.href} className="topnav__link" href={link.href}>
                  {link.label}
                </InteractiveLink>
              ))}
            </nav>

            <div className="topbar__auth">
              <AuthControls
                authState={authState}
                onOpenLogin={handleOpenLogin}
                onLogout={handleLogout}
                busyProvider={authBusyProvider}
              />
            </div>
          </div>

          <InteractiveLink
            as={motion.button}
            type="button"
            className="menu-toggle"
            aria-controls={menuId}
            aria-expanded={isMenuOpen}
            onClick={() => setIsMenuOpen(true)}
          >
            Menu
          </InteractiveLink>
        </header>

        <Reveal as={motion.section} className="hero section surface" id="top">
          <div className="hero-copy">
            <p className="eyebrow">XMAXX / live systems</p>
            <h1>We maxx the systems that shape how people live.</h1>
            <p className="hero-copy__lede">
              From water and air to infrastructure, interfaces, and physical
              environments, XMAXX builds AI-enabled software and hardware
              systems designed to see more, decide faster, and improve what is
              underperforming.
            </p>

            <div className="hero-copy__actions">
              <InteractiveLink
                as={motion.button}
                type="button"
                className="button button--solid"
                onClick={() => setIsBriefOpen(true)}
              >
                Book a build conversation
              </InteractiveLink>
              <InteractiveLink
                className="button button--ghost"
                href={xmaxxGptUrl}
                target="_blank"
                rel="noreferrer"
              >
                Open the XMAXX GPT
              </InteractiveLink>
              <InteractiveLink className="button button--ghost" href="#focus">
                Explore the focus deck
              </InteractiveLink>
            </div>

            <AuthCard
              authState={authState}
              notice={authNotice}
              onOpenLogin={handleOpenLogin}
              onLogout={handleLogout}
              busyProvider={authBusyProvider}
            />

            <ul className="proof-list" aria-label="XMAXX proof points">
              {proofPoints.map((item) => (
                <motion.li
                  key={item}
                  className="proof-list__item"
                  initial={{ opacity: 0, x: -14 }}
                  whileInView={{ opacity: 1, x: 0 }}
                  viewport={{ once: true, amount: 0.6 }}
                  transition={{ duration: 0.48 }}
                >
                  <span className="proof-list__dot" />
                  {item}
                </motion.li>
              ))}
            </ul>
          </div>

          <HeroPreview ready={heroReady} onReady={() => setHeroReady(true)} />
        </Reveal>

        <StaggerGroup as={motion.section} className="metric-strip" id="platform">
          {metrics.map((item) => (
            <StaggerItem key={item.label}>
              <InteractiveSurface className="metric-card" lift={5}>
                <p className="metric-card__value">{item.value}</p>
                <p className="metric-card__label">{item.label}</p>
              </InteractiveSurface>
            </StaggerItem>
          ))}
        </StaggerGroup>

        <ProfileWorkspace authState={authState} onOpenLogin={handleOpenLogin} />

        <Reveal as={motion.section} className="focus section" id="focus">
          <div className="section-copy">
            <p className="eyebrow">Audience focus</p>
            <h2>One system, different priorities depending on who is in the room.</h2>
            <p>
              The same platform should read differently to operators, partners,
              and builders. Change the lens and the capability deck reorders
              around what matters most.
            </p>
          </div>

          <div className="lens-bar">
            <div className="lens-tabs" role="tablist" aria-label="Audience lenses">
              {lenses.map((lens) => (
                <motion.button
                  key={lens.id}
                  type="button"
                  className={`lens-tab${lens.id === activeLens ? ' lens-tab--active' : ''}`}
                  onClick={() => setActiveLens(lens.id)}
                  role="tab"
                  aria-selected={lens.id === activeLens}
                  layout
                >
                  {lens.id === activeLens ? (
                    <motion.span
                      className="lens-tab__pill"
                      layoutId="active-lens"
                      transition={{ duration: 0.32, ease: [0.22, 1, 0.36, 1] }}
                    />
                  ) : null}
                  <span className="lens-tab__label">{lens.label}</span>
                </motion.button>
              ))}
            </div>

            <p className="lens-bar__note">
              Layout shifts are intentional here: the deck re-prioritizes as the
              audience changes.
            </p>
          </div>

          <motion.div layout className="lens-summary surface">
            <AnimatePresence mode="wait">
              <motion.div
                key={activeLens}
                initial={{ opacity: 0, y: 12 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, y: -10 }}
                transition={{ duration: 0.24 }}
              >
                <p className="eyebrow">{activeLensData.description}</p>
                <h3>{activeLensData.heading}</h3>
                <p>{activeLensData.body}</p>
              </motion.div>
            </AnimatePresence>
          </motion.div>

          <motion.div layout className="capability-grid">
            {rankedCapabilities.map((item, index) => (
              <InteractiveSurface
                as={motion.article}
                layout
                key={item.id}
                className={`capability-card${
                  index < 2 ? ' capability-card--featured' : ''
                }`}
                lift={6}
              >
                <div className="capability-card__head">
                  <p className="capability-card__eyebrow">{item.eyebrow}</p>
                  <span className="capability-card__score">
                    {item.scores[activeLens]}
                  </span>
                </div>
                <h3>{item.title}</h3>
                <p>{item.body}</p>
                <div className="capability-card__meter" aria-hidden="true">
                  <motion.span
                    className="capability-card__meter-fill"
                    initial={false}
                    animate={{ width: `${item.scores[activeLens]}%` }}
                    transition={{ duration: 0.4, ease: [0.22, 1, 0.36, 1] }}
                  />
                </div>
              </InteractiveSurface>
            ))}
          </motion.div>
        </Reveal>

        <StaggerGroup as={motion.section} className="stack section" id="stack">
          <div className="section-copy section-copy--tight">
            <p className="eyebrow">Platform stack</p>
            <h2>Built to look premium and deploy like software.</h2>
            <p>
              The UI is only credible if the delivery path is credible. The
              current platform already connects infrastructure-as-code,
              containerized delivery, cluster runtime, and ingress automation.
            </p>
          </div>

          <div className="stack-grid">
            {stackLayers.map((layer) => (
              <StaggerItem key={layer.title}>
                <InteractiveSurface className="stack-card" lift={5}>
                  <p className="stack-card__title">{layer.title}</p>
                  <p>{layer.body}</p>
                </InteractiveSurface>
              </StaggerItem>
            ))}
          </div>
        </StaggerGroup>

        <Reveal as={motion.section} className="closing-banner surface surface--dark">
          <div className="closing-banner__copy">
            <p className="eyebrow">MAXXER posture</p>
            <h2>Build the software. Build the hardware. Maxx the system end to end.</h2>
            <p>
              XMAXX is aiming at systems that can be measured, improved, and
              continuously refined with AI. The website is the first public
              surface, not the endpoint.
            </p>
          </div>

          <div className="closing-banner__actions">
            <InteractiveLink
              as={motion.button}
              type="button"
              className="button button--solid button--contrast"
              onClick={() => setIsBriefOpen(true)}
            >
              Start the conversation
            </InteractiveLink>
            <InteractiveLink className="button button--ghost button--contrast" href="mailto:info@xmaxx.ai">
              info@xmaxx.ai
            </InteractiveLink>
          </div>
        </Reveal>
      </main>

      <AnimatePresence>
        {isMenuOpen ? (
          <motion.div
            className="overlay"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            transition={{ duration: 0.2 }}
            onClick={() => setIsMenuOpen(false)}
          >
            <motion.aside
              id={menuId}
              className="mobile-panel surface"
              initial={{ x: '100%', opacity: 0.96 }}
              animate={{ x: 0, opacity: 1 }}
              exit={{ x: '100%', opacity: 0.96 }}
              transition={{ duration: 0.3, ease: [0.22, 1, 0.36, 1] }}
              onClick={(event) => event.stopPropagation()}
            >
              <div className="mobile-panel__header">
                <div>
                  <p className="eyebrow">Navigate</p>
                  <h2>Move through the surface cleanly.</h2>
                </div>
                <button
                  type="button"
                  className="icon-button"
                  onClick={() => setIsMenuOpen(false)}
                  aria-label="Close menu"
                >
                  ×
                </button>
              </div>

              <div className="mobile-panel__links">
                {navLinks.map((link) => (
                  <InteractiveLink
                    key={link.href}
                    className="mobile-link"
                    href={link.href}
                    onClick={() => setIsMenuOpen(false)}
                  >
                    {link.label}
                  </InteractiveLink>
                ))}
              </div>

              <div className="mobile-panel__lenses">
                <p className="eyebrow">Audience lens</p>
                <div className="mobile-panel__chips">
                  {lenses.map((lens) => (
                    <motion.button
                      key={lens.id}
                      type="button"
                      className={`mobile-chip${
                        activeLens === lens.id ? ' mobile-chip--active' : ''
                      }`}
                      onClick={() => {
                        setActiveLens(lens.id)
                        setIsMenuOpen(false)
                      }}
                      whileTap={{ scale: 0.98 }}
                    >
                      {lens.label}
                    </motion.button>
                  ))}
                </div>
              </div>

              <div className="mobile-panel__auth">
                <p className="eyebrow">Operator access</p>
                <AuthControls
                  authState={authState}
                  onOpenLogin={handleOpenLogin}
                  onLogout={handleLogout}
                  stacked
                  busyProvider={authBusyProvider}
                  onAction={() => setIsMenuOpen(false)}
                />
              </div>

              <InteractiveLink
                as={motion.button}
                type="button"
                className="button button--solid"
                onClick={() => {
                  setIsMenuOpen(false)
                  setIsBriefOpen(true)
                }}
              >
                Request operator brief
              </InteractiveLink>
            </motion.aside>
          </motion.div>
        ) : null}
      </AnimatePresence>

      <AnimatePresence>
        {isAuthModalOpen ? (
          <AuthModal
            open={isAuthModalOpen}
            onClose={() => setIsAuthModalOpen(false)}
            authState={authState}
            onSelectProvider={handleProviderLogin}
            busyProvider={authBusyProvider}
          />
        ) : null}
      </AnimatePresence>

      <BriefModal open={isBriefOpen} onClose={() => setIsBriefOpen(false)} />
    </>
  )
}

export default App
