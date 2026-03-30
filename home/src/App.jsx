import { AnimatePresence, motion } from 'motion/react'
import {
  startTransition,
  useDeferredValue,
  useEffect,
  useEffectEvent,
  useId,
  useRef,
  useState,
} from 'react'
import {
  InteractiveLink,
  InteractiveSurface,
  Reveal,
  StaggerGroup,
  StaggerItem,
} from './components/motion-primitives'
import './index.css'

const navLinks = [
  { id: 'overview', label: 'Overview' },
  { id: 'feed', label: 'Feed' },
  { id: 'board', label: 'Board' },
  { id: 'stack', label: 'Stack' },
]

const workspaceStats = [
  {
    value: 'Cmd + K',
    label: 'Every core action routes through the command center.',
  },
  {
    value: 'Live',
    label: 'Agent rail stays pinned to the workspace and responds in place.',
  },
  {
    value: '0 hops',
    label: 'Cards expand inline instead of kicking users into dead screens.',
  },
  {
    value: '240ms',
    label: 'Motion stays sharp, short, and system-like rather than decorative.',
  },
]

const streams = [
  {
    id: 'surface',
    lane: 'Control surface',
    title: 'Operator surface',
    summary:
      'Dense, command-first UI with state awareness, fast feedback, and no dead zones.',
    status: 'Pinned',
    metrics: ['Command center', 'Activity memory', 'Inline expansion'],
    notes: [
      'Selected state is visible without adding visual noise.',
      'Every action responds immediately and logs itself into recent activity.',
      'The shell behaves like a tool, not a brochure.',
    ],
    actionId: 'open-command',
    actionLabel: 'Open command center',
  },
  {
    id: 'runtime',
    lane: 'Runtime',
    title: 'Runtime delivery',
    summary:
      'Ingress, TLS, Helm, and release posture stay on the main surface so infra feels productized.',
    status: 'Hot path',
    metrics: ['Helm', 'Ingress', 'TLS'],
    notes: [
      'Delivery state is visible next to the product surface.',
      'Infrastructure language stays concise and operator-readable.',
      'The board can be re-prioritized without leaving home.',
    ],
    actionId: 'focus-runtime',
    actionLabel: 'Promote runtime',
  },
  {
    id: 'access',
    lane: 'Access',
    title: 'Operator identity',
    summary:
      'OAuth is treated as a live system capability, not a disconnected settings page.',
    status: 'Armed',
    metrics: ['GitHub', 'Google', 'Session'],
    notes: [
      'Provider readiness is visible before a user clicks sign-in.',
      'Popup auth keeps the workspace intact while the backend handles the exchange.',
      'The command layer can route straight into auth review.',
    ],
    actionId: 'auth-audit',
    actionLabel: 'Audit access',
  },
  {
    id: 'field',
    lane: 'Signal plane',
    title: 'Environmental intelligence',
    summary:
      'Water, air, and physical systems stay present in the feed so the interface feels grounded.',
    status: 'Queued',
    metrics: ['Water', 'Air', 'Hardware'],
    notes: [
      'The feed keeps physical-world work visible beside software work.',
      'Signals can be elevated without rebuilding the layout.',
      'This card is built to flex into richer system telemetry later.',
    ],
    actionId: 'run-sweep',
    actionLabel: 'Run system sweep',
  },
]

const initialProcesses = [
  {
    id: 'agent',
    label: 'Agent assist',
    detail: 'Suggestions, inline commands, and live results.',
    status: 'live',
  },
  {
    id: 'runtime',
    label: 'Runtime delivery',
    detail: 'Release posture, ingress health, and deployment focus.',
    status: 'stable',
  },
  {
    id: 'access',
    label: 'Operator access',
    detail: 'Popup OAuth, provider readiness, and session continuity.',
    status: 'standby',
  },
  {
    id: 'memory',
    label: 'Activity memory',
    detail: 'Recent actions stay visible so the interface never feels idle.',
    status: 'running',
  },
]

const initialActivity = [
  {
    id: 'activity-01',
    lane: 'Workspace',
    title: 'Home switched from landing page to operating layer.',
    detail: 'The shell now centers live state, not marketing copy.',
    time: 'Now',
    tone: 'neutral',
  },
  {
    id: 'activity-02',
    lane: 'Agent',
    title: 'Persistent right rail pinned and ready.',
    detail: 'Suggestions can execute actions without leaving the page.',
    time: '1m',
    tone: 'accent',
  },
  {
    id: 'activity-03',
    lane: 'Speed',
    title: 'Command center primed for keyboard-first control.',
    detail: 'Cmd/Ctrl + K opens navigation, actions, and agent triggers.',
    time: '3m',
    tone: 'neutral',
  },
  {
    id: 'activity-04',
    lane: 'Access',
    title: 'OAuth session watcher is live.',
    detail: 'The surface refreshes auth state when a popup completes.',
    time: '6m',
    tone: 'muted',
  },
]

const agentSuggestions = [
  {
    id: 'suggestion-sweep',
    label: 'Run system sweep',
    detail: 'Refresh priorities and promote the sharpest next action.',
    actionId: 'run-sweep',
  },
  {
    id: 'suggestion-runtime',
    label: 'Promote runtime delivery',
    detail: 'Shift the board toward release health and infra credibility.',
    actionId: 'focus-runtime',
  },
  {
    id: 'suggestion-auth',
    label: 'Audit operator access',
    detail: 'Check provider readiness and session posture.',
    actionId: 'auth-audit',
  },
  {
    id: 'suggestion-brief',
    label: 'Draft build brief',
    detail: 'Prepare the next conversation around what should be maxxed.',
    actionId: 'compose-brief',
  },
]

const stackLayers = [
  {
    title: 'Terraform',
    body: 'Infrastructure stays reproducible so the product surface and runtime posture ship together.',
  },
  {
    title: 'K3s',
    body: 'Lightweight Kubernetes keeps the runtime real without dragging the UI into infra bloat.',
  },
  {
    title: 'Docker',
    body: 'The frontend is packaged as a deployable artifact, not a one-off upload.',
  },
  {
    title: 'Helm',
    body: 'Release behavior lives next to the app so changes stay intentional and reviewable.',
  },
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

function getProcessStatusLabel(status) {
  switch (status) {
    case 'live':
      return 'Live'
    case 'running':
      return 'Running'
    case 'stable':
      return 'Stable'
    case 'attention':
      return 'Needs review'
    case 'standby':
      return 'Standby'
    default:
      return 'Queued'
  }
}

function createActivityEntry({ lane, title, detail, tone = 'neutral' }) {
  return {
    id: `${lane}-${Date.now()}-${Math.random().toString(36).slice(2, 7)}`,
    lane,
    title,
    detail,
    time: 'Now',
    tone,
  }
}

function StatusPill({ status }) {
  return (
    <span className={`status-pill status-pill--${status}`}>
      <span className="status-pill__dot" />
      {getProcessStatusLabel(status)}
    </span>
  )
}

function AuthControls({
  authState,
  onOpenLogin,
  onLogout,
  busyProvider = '',
  compact = false,
}) {
  const className = `auth-actions${compact ? ' auth-actions--compact' : ''}`
  const availableProviders = getConfiguredProviders(authState)
  const secondaryLabel = getUserSecondaryLabel(authState)

  if (authState.loading) {
    return (
      <div className={className}>
        <div className="session-pill">
          <span className="session-pill__status" />
          <span>Checking access</span>
        </div>
      </div>
    )
  }

  if (authState.authenticated && authState.user) {
    return (
      <div className={className}>
        <a
          className="session-pill session-pill--link"
          href={authState.user.profile_url || '#overview'}
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
          className="ghost-button"
          onClick={onLogout}
          whileTap={{ scale: 0.985 }}
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
        className="ghost-button"
        onClick={onOpenLogin}
        disabled={!authState.configured || Boolean(authState.error) || Boolean(busyProvider)}
        whileTap={{
          scale:
            authState.configured && !authState.error && !busyProvider ? 0.985 : 1,
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

function OperatorAccessCard({
  authState,
  notice,
  onOpenLogin,
  onLogout,
  busyProvider,
}) {
  const isAuthenticated = authState.authenticated && authState.user
  const configuredProviders = getConfiguredProviders(authState)
  const configuredProviderNames = configuredProviders.map(({ label }) => label).join(' or ')
  const title = authState.loading
    ? 'Checking operator access.'
    : authState.error
      ? 'Auth endpoint is not responding.'
      : isAuthenticated
        ? `Operator session live for ${authState.user.name}.`
        : authState.configured
          ? configuredProviders.length > 1
            ? 'Choose Google or GitHub to unlock the private surface.'
            : `Sign in with ${configuredProviderNames} to unlock the private surface.`
          : 'Operator auth is staged but not configured yet.'

  const body = authState.loading
    ? 'The workspace is checking whether a browser session already exists.'
    : authState.error
      ? 'Login actions stay disabled until `/api/auth/session/` is reachable from the frontend.'
      : isAuthenticated
        ? 'The session is owned by the deployed backend, so private workflows can stay inside the same XMAXX surface.'
        : authState.configured
          ? 'Sign-in opens in a popup so the backend can complete the OAuth exchange without interrupting the workspace.'
          : 'Once at least one provider has valid OAuth settings, this control will unlock the deployed callback flow.'

  const status = authState.loading
    ? 'running'
    : authState.error
      ? 'attention'
      : isAuthenticated
        ? 'live'
        : authState.configured
          ? 'stable'
          : 'standby'

  return (
    <section className="panel operator-card">
      <div className="panel-heading">
        <div>
          <p className="eyebrow">Operator access</p>
          <h3>{title}</h3>
        </div>
        <StatusPill status={status} />
      </div>

      <p className="operator-card__body">{body}</p>

      <div className="provider-strip" aria-label="Available sign-in providers">
        {authProviders.map((provider) => {
          const providerState = getProviderState(authState, provider.id)

          return (
            <div
              key={provider.id}
              className={`provider-chip${
                providerState.configured ? ' provider-chip--ready' : ''
              }`}
            >
              <strong>{provider.label}</strong>
              <small>{providerState.configured ? 'Ready' : 'Setup needed'}</small>
            </div>
          )
        })}
      </div>

      {notice ? (
        <div className={`workspace-notice workspace-notice--${notice.tone}`} role="status">
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
    </section>
  )
}

function AuthModal({ open, onClose, authState, onSelectProvider, busyProvider = '' }) {
  if (!open) {
    return null
  }

  return (
    <motion.div
      className="command-overlay"
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      transition={{ duration: 0.2 }}
      onClick={onClose}
    >
      <motion.div
        className="auth-dialog panel"
        role="dialog"
        aria-modal="true"
        initial={{ opacity: 0, y: 18, scale: 0.985 }}
        animate={{ opacity: 1, y: 0, scale: 1 }}
        exit={{ opacity: 0, y: 14, scale: 0.985 }}
        transition={{ duration: 0.24, ease: [0.22, 1, 0.36, 1] }}
        onClick={(event) => event.stopPropagation()}
      >
        <div className="dialog-head">
          <div>
            <p className="eyebrow">Choose sign-in</p>
            <h2>Select the identity system that should own this browser session.</h2>
          </div>
          <button type="button" className="icon-button" onClick={onClose} aria-label="Close">
            ×
          </button>
        </div>

        <p className="dialog-copy">
          The backend completes the OAuth code exchange on the XMAXX origin and
          keeps the workspace intact while the popup finishes.
        </p>

        {authState.error ? (
          <div className="workspace-notice workspace-notice--error" role="status">
            <strong>Auth session unavailable</strong>
            <span>{authState.error}</span>
          </div>
        ) : null}

        {busyProvider ? (
          <div className="workspace-notice workspace-notice--info" role="status">
            <strong>Complete {getProviderLabel(busyProvider)} sign-in</strong>
            <span>
              Finish the flow in the popup window. This page will refresh the
              session automatically when the provider returns.
            </span>
          </div>
        ) : null}

        <div className="provider-grid">
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
                className={`provider-option${
                  providerState.configured ? ' provider-option--ready' : ''
                }`}
                disabled={disabled}
                onClick={() => onSelectProvider(provider.id)}
                whileTap={{ scale: disabled ? 1 : 0.985 }}
              >
                <div className="provider-option__head">
                  <div>
                    <p className="provider-option__eyebrow">{provider.eyebrow}</p>
                    <h3>{provider.label}</h3>
                  </div>
                  <StatusPill status={providerState.configured ? 'stable' : 'attention'} />
                </div>
                <p>{provider.description}</p>
                <span className="provider-option__hint">
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

function CommandCenter({
  open,
  onClose,
  query,
  onQueryChange,
  commands,
  selectedIndex,
  onSelectIndex,
  onRunCommand,
}) {
  const titleId = useId()
  const inputRef = useRef(null)

  useEffect(() => {
    if (!open) {
      return
    }

    const nextFrame = window.requestAnimationFrame(() => {
      inputRef.current?.focus()
    })

    return () => window.cancelAnimationFrame(nextFrame)
  }, [open])

  if (!open) {
    return null
  }

  const activeIndex = commands.length === 0 ? -1 : Math.min(selectedIndex, commands.length - 1)

  return (
    <motion.div
      className="command-overlay"
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      transition={{ duration: 0.2 }}
      onClick={onClose}
    >
      <motion.div
        className="command-center panel"
        role="dialog"
        aria-modal="true"
        aria-labelledby={titleId}
        initial={{ opacity: 0, y: 22, scale: 0.985 }}
        animate={{ opacity: 1, y: 0, scale: 1 }}
        exit={{ opacity: 0, y: 16, scale: 0.985 }}
        transition={{ duration: 0.24, ease: [0.22, 1, 0.36, 1] }}
        onClick={(event) => event.stopPropagation()}
      >
        <div className="command-center__head">
          <div>
            <p className="eyebrow">Command center</p>
            <h2 id={titleId}>Navigate, run actions, or trigger the agent without leaving home.</h2>
          </div>
          <div className="command-center__keys">
            <kbd>↑</kbd>
            <kbd>↓</kbd>
            <kbd>Enter</kbd>
          </div>
        </div>

        <label className="command-search" htmlFor="command-search-input">
          <span className="command-search__label">Query</span>
          <input
            ref={inputRef}
            id="command-search-input"
            type="text"
            value={query}
            onChange={(event) => onQueryChange(event.target.value)}
            onKeyDown={(event) => {
              if (event.key === 'ArrowDown') {
                event.preventDefault()
                onSelectIndex(Math.min(activeIndex + 1, commands.length - 1))
                return
              }

              if (event.key === 'ArrowUp') {
                event.preventDefault()
                onSelectIndex(Math.max(activeIndex - 1, 0))
                return
              }

              if (event.key === 'Enter' && activeIndex >= 0) {
                event.preventDefault()
                onRunCommand(commands[activeIndex])
              }
            }}
            placeholder="Search commands, surfaces, and agent actions"
            autoComplete="off"
          />
        </label>

        <div className="command-results">
          {commands.length > 0 ? (
            commands.map((command, index) => (
              <motion.button
                key={command.id}
                type="button"
                className={`command-row${index === activeIndex ? ' command-row--active' : ''}`}
                onMouseEnter={() => onSelectIndex(index)}
                onFocus={() => onSelectIndex(index)}
                onClick={() => onRunCommand(command)}
                whileTap={{ scale: 0.99 }}
              >
                <div className="command-row__copy">
                  <strong>{command.label}</strong>
                  <span>{command.detail}</span>
                </div>
                <small>{command.group}</small>
              </motion.button>
            ))
          ) : (
            <div className="command-empty">
              <strong>No commands match that query.</strong>
              <span>Try `agent`, `runtime`, `auth`, or `feed`.</span>
            </div>
          )}
        </div>
      </motion.div>
    </motion.div>
  )
}

function App() {
  const [activeNav, setActiveNav] = useState('overview')
  const [activeStreamId, setActiveStreamId] = useState('surface')
  const [expandedStreamId, setExpandedStreamId] = useState('surface')
  const [workspaceNote, setWorkspaceNote] = useState(
    'Ship the operating layer before polishing the story. Speed is the story.',
  )
  const [noteState, setNoteState] = useState('synced')
  const [activity, setActivity] = useState(initialActivity)
  const [processes, setProcesses] = useState(initialProcesses)
  const [selectedSuggestionId, setSelectedSuggestionId] = useState('suggestion-sweep')
  const [agentMode, setAgentMode] = useState('Watching the surface for the next move.')
  const [agentResult, setAgentResult] = useState('No active run. Suggestions are ready.')
  const [isCommandOpen, setIsCommandOpen] = useState(false)
  const [commandQuery, setCommandQuery] = useState('')
  const [commandIndex, setCommandIndex] = useState(0)
  const [isAuthModalOpen, setIsAuthModalOpen] = useState(false)
  const [authNotice, setAuthNotice] = useState(() => readAuthNotice())
  const [authState, setAuthState] = useState(buildInitialAuthState)
  const [authBusyProvider, setAuthBusyProvider] = useState('')
  const [accessProcessOverride, setAccessProcessOverride] = useState(null)
  const authPopupMonitorRef = useRef(0)
  const timersRef = useRef(new Set())
  const noteSyncTimerRef = useRef(0)
  const deferredCommandQuery = useDeferredValue(commandQuery)
  const activeStream = streams.find((stream) => stream.id === activeStreamId) ?? streams[0]

  const queueTimeout = (callback, delay = 960) => {
    const timerId = window.setTimeout(() => {
      timersRef.current.delete(timerId)
      callback()
    }, delay)

    timersRef.current.add(timerId)
  }

  const pushActivity = (entry) => {
    setActivity((current) => [createActivityEntry(entry), ...current].slice(0, 7))
  }

  const updateProcess = (processId, status, detail) => {
    if (processId === 'access') {
      setAccessProcessOverride({
        status,
        detail,
      })
      return
    }

    setProcesses((current) =>
      current.map((process) =>
        process.id === processId
          ? {
              ...process,
              status,
              detail: detail ?? process.detail,
            }
          : process,
      ),
    )
  }

  const focusSection = (sectionId) => {
    setActiveNav(sectionId)
    document.getElementById(sectionId)?.scrollIntoView({
      behavior: 'smooth',
      block: 'start',
    })
  }

  const selectStream = (streamId, forceExpand = false) => {
    startTransition(() => {
      setActiveStreamId(streamId)
      setExpandedStreamId((current) => {
        if (forceExpand) {
          return streamId
        }

        return current === streamId ? '' : streamId
      })
    })
  }

  const openCommandCenter = () => {
    setIsCommandOpen(true)
    setCommandQuery('')
    setCommandIndex(0)
  }

  const handleCommandQueryChange = (value) => {
    setCommandQuery(value)
    setCommandIndex(0)
  }

  const handleOpenLogin = () => {
    setIsAuthModalOpen(true)
    pushActivity({
      lane: 'Access',
      title: 'Operator sign-in surfaced from the workspace.',
      detail: 'The auth selector opened without forcing a page transition.',
      tone: 'accent',
    })
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
    updateProcess('access', 'running', `Waiting for ${getProviderLabel(provider)} to return.`)
    pushActivity({
      lane: 'Access',
      title: `${getProviderLabel(provider)} sign-in launched.`,
      detail: 'The popup flow is now owning the auth exchange.',
      tone: 'accent',
    })

    authPopupMonitorRef.current = window.setInterval(() => {
      if (!popup.closed) {
        return
      }

      window.clearInterval(authPopupMonitorRef.current)
      authPopupMonitorRef.current = 0
      setAuthBusyProvider('')
      setAccessProcessOverride(null)
      void syncAuthSession(setAuthState)
    }, 500)
  }

  const handleLogout = () => {
    window.location.assign(
      `/api/auth/logout/?next=${encodeURIComponent(buildAuthReturnPath())}`,
    )
  }

  const runWorkspaceAction = (actionId) => {
    switch (actionId) {
      case 'open-command':
        openCommandCenter()
        pushActivity({
          lane: 'Speed',
          title: 'Command center opened.',
          detail: 'Keyboard-first control stays one shortcut away.',
          tone: 'accent',
        })
        break
      case 'focus-runtime':
        selectStream('runtime', true)
        focusSection('board')
        setSelectedSuggestionId('suggestion-runtime')
        setAgentMode('Runtime delivery promoted to the front of the board.')
        setAgentResult('Release posture is now the active focus.')
        updateProcess('runtime', 'running', 'Reordering the board around delivery posture.')
        updateProcess('agent', 'running', 'Promoting runtime delivery across the workspace.')
        pushActivity({
          lane: 'Runtime',
          title: 'Runtime delivery moved to the hot path.',
          detail: 'The control board now prioritizes release and infra credibility.',
          tone: 'accent',
        })
        queueTimeout(() => {
          updateProcess('runtime', 'live', 'Runtime posture is now the active surface.')
          updateProcess('agent', 'live', 'Agent rail synchronized with runtime focus.')
          setAgentResult('Runtime delivery is now leading the workspace.')
        })
        break
      case 'run-sweep':
        setSelectedSuggestionId('suggestion-sweep')
        setAgentMode('Sweeping streams and refreshing what should be maxxed next.')
        setAgentResult('Running a cross-surface priority sweep.')
        updateProcess('agent', 'running', 'Re-scoring active streams and quick actions.')
        updateProcess('memory', 'running', 'Writing fresh activity into the live feed.')
        pushActivity({
          lane: 'Agent',
          title: 'System sweep started.',
          detail: 'The agent rail is refreshing priorities and recent activity.',
          tone: 'accent',
        })
        queueTimeout(() => {
          selectStream('surface', true)
          updateProcess('agent', 'live', 'Sweep completed and recommendations updated.')
          updateProcess('memory', 'live', 'Activity feed refreshed with current posture.')
          setAgentMode('Sweep complete. Operator surface is still the strongest lead.')
          setAgentResult('The control surface remains first. Runtime stays close behind.')
          pushActivity({
            lane: 'Agent',
            title: 'System sweep completed.',
            detail: 'Operator surface remains the sharpest priority on home.',
            tone: 'neutral',
          })
        }, 1040)
        break
      case 'auth-audit':
        selectStream('access', true)
        focusSection('board')
        setSelectedSuggestionId('suggestion-auth')
        setAgentMode('Auditing provider readiness and browser session posture.')
        setAgentResult('Operator access audit is in progress.')
        updateProcess('access', 'running', 'Reviewing provider readiness and session state.')
        updateProcess('agent', 'running', 'Scanning auth posture from the side rail.')
        pushActivity({
          lane: 'Access',
          title: 'Operator access audit started.',
          detail: 'Provider readiness and current browser session are being reviewed.',
          tone: 'accent',
        })
        queueTimeout(() => {
          setAccessProcessOverride(null)
          updateProcess('agent', 'live', 'Access posture folded back into the rail.')
          setAgentResult(
            authState.authenticated
              ? 'Session is live and attached to the private surface.'
              : authState.error
                ? 'Auth endpoint still needs attention.'
                : authState.configured
                  ? 'Providers are ready. The workspace can hand off to sign-in.'
                  : 'Auth is staged but not yet configured.',
          )
        }, 880)
        break
      case 'compose-brief':
        setSelectedSuggestionId('suggestion-brief')
        setAgentMode('Drafting the next build conversation around real system pressure.')
        setAgentResult('The agent framed the next brief around speed, control, and trust.')
        updateProcess('agent', 'running', 'Composing the next operator brief.')
        pushActivity({
          lane: 'Brief',
          title: 'Build brief drafted from the current workspace state.',
          detail: 'The next conversation is centered on the active surface, runtime, and access posture.',
          tone: 'neutral',
        })
        queueTimeout(() => {
          updateProcess('agent', 'live', 'Draft brief ready for operator review.')
          window.location.assign('mailto:info@xmaxx.ai?subject=XMAXX%20Build%20Brief')
        }, 520)
        break
      default:
        break
    }
  }

  const commandEntries = [
    {
      id: 'cmd-overview',
      group: 'Navigate',
      label: 'Jump to overview',
      detail: 'See the launchpad, live stats, and immediate actions.',
      keywords: 'overview launchpad home top',
      commandType: 'section',
      target: 'overview',
    },
    {
      id: 'cmd-feed',
      group: 'Navigate',
      label: 'Jump to feed',
      detail: 'Open the expandable stream cards and live priorities.',
      keywords: 'feed streams cards priorities',
      commandType: 'section',
      target: 'feed',
    },
    {
      id: 'cmd-board',
      group: 'Navigate',
      label: 'Jump to board',
      detail: 'Move to process state, operator note, and active controls.',
      keywords: 'board processes note controls',
      commandType: 'section',
      target: 'board',
    },
    {
      id: 'cmd-stack',
      group: 'Navigate',
      label: 'Jump to stack',
      detail: 'Review the delivery layers behind the surface.',
      keywords: 'stack terraform k3s docker helm',
      commandType: 'section',
      target: 'stack',
    },
    {
      id: 'cmd-open-command',
      group: 'Run',
      label: 'Open command center',
      detail: 'Keep the keyboard-first control loop active.',
      keywords: 'command center keyboard',
      commandType: 'action',
      target: 'open-command',
    },
    {
      id: 'cmd-sweep',
      group: 'Agent',
      label: 'Run system sweep',
      detail: 'Refresh the active streams and recent activity.',
      keywords: 'agent sweep refresh',
      commandType: 'action',
      target: 'run-sweep',
    },
    {
      id: 'cmd-runtime',
      group: 'Agent',
      label: 'Promote runtime delivery',
      detail: 'Move infra and release posture to the front of the board.',
      keywords: 'runtime delivery infra release',
      commandType: 'action',
      target: 'focus-runtime',
    },
    {
      id: 'cmd-auth',
      group: 'Access',
      label: 'Audit operator access',
      detail: 'Review provider readiness and session state.',
      keywords: 'auth access oauth session',
      commandType: 'action',
      target: 'auth-audit',
    },
    {
      id: 'cmd-brief',
      group: 'Agent',
      label: 'Draft build brief',
      detail: 'Open the next conversation from current workspace state.',
      keywords: 'brief build conversation mail',
      commandType: 'action',
      target: 'compose-brief',
    },
    {
      id: 'cmd-login',
      group: 'Access',
      label: authState.authenticated ? 'Review active session' : 'Open sign-in',
      detail: authState.authenticated
        ? 'Inspect the session card and private access posture.'
        : 'Open provider selection without leaving the workspace.',
      keywords: 'login auth session provider',
      commandType: authState.authenticated ? 'section' : 'login',
      target: authState.authenticated ? 'board' : 'login',
    },
  ]

  const normalizedQuery = deferredCommandQuery.trim().toLowerCase()
  const filteredCommands = commandEntries.filter((command) => {
    if (!normalizedQuery) {
      return true
    }

    const haystack = `${command.group} ${command.label} ${command.detail} ${command.keywords}`.toLowerCase()
    return haystack.includes(normalizedQuery)
  })

  useEffect(() => {
    const controller = new AbortController()

    void syncAuthSession(setAuthState, controller.signal)

    return () => controller.abort()
  }, [])

  useEffect(() => {
    const timers = timersRef.current

    return () => {
      if (authPopupMonitorRef.current) {
        window.clearInterval(authPopupMonitorRef.current)
      }

      if (noteSyncTimerRef.current) {
        window.clearTimeout(noteSyncTimerRef.current)
      }

      timers.forEach((timerId) => window.clearTimeout(timerId))
      timers.clear()
    }
  }, [])

  const handleAuthMessage = useEffectEvent((event) => {
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
    setAccessProcessOverride(null)

    const notice = buildAuthNotice(event.data)
    if (notice) {
      setAuthNotice(notice)
    }

    pushActivity({
      lane: 'Access',
      title: `${getProviderLabel(event.data.provider)} auth returned to the workspace.`,
      detail: 'Session state is being refreshed in place.',
      tone: 'accent',
    })
    void syncAuthSession(setAuthState)
  })

  useEffect(() => {
    window.addEventListener('message', handleAuthMessage)

    return () => {
      window.removeEventListener('message', handleAuthMessage)
    }
  }, [])

  const handleGlobalKeyDown = useEffectEvent((event) => {
    const isShortcut = (event.metaKey || event.ctrlKey) && event.key.toLowerCase() === 'k'

    if (isShortcut) {
      event.preventDefault()
      openCommandCenter()
      return
    }

    if (event.key === 'Escape') {
      setIsCommandOpen(false)
      setIsAuthModalOpen(false)
    }
  })

  useEffect(() => {
    window.addEventListener('keydown', handleGlobalKeyDown)

    return () => {
      window.removeEventListener('keydown', handleGlobalKeyDown)
    }
  }, [])

  const runCommand = (command) => {
    setIsCommandOpen(false)
    setCommandQuery('')

    if (command.commandType === 'section') {
      focusSection(command.target)
      return
    }

    if (command.commandType === 'login') {
      handleOpenLogin()
      return
    }

    runWorkspaceAction(command.target)
  }

  const derivedAccessProcess = accessProcessOverride ?? {
    status: authState.loading
      ? 'running'
      : authState.authenticated
        ? 'live'
        : authState.error || !authState.configured
          ? 'attention'
          : 'stable',
    detail: authState.loading
      ? 'Checking session continuity on the current browser.'
      : authState.authenticated
        ? 'Live operator session detected.'
        : authState.error
          ? authState.error
          : authState.configured
            ? 'Providers are ready for sign-in.'
            : 'Auth still needs backend configuration.',
  }

  const renderedProcesses = processes.map((process) =>
    process.id === 'access'
      ? {
          ...process,
          ...derivedAccessProcess,
        }
      : process,
  )

  return (
    <>
      <main className="workspace-shell">
        <div className="workspace-ambient workspace-ambient--one" />
        <div className="workspace-ambient workspace-ambient--two" />

        <motion.header
          className="workspace-topbar panel"
          initial={{ opacity: 0, y: 16 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.24, ease: [0.22, 1, 0.36, 1] }}
        >
          <a className="brand" href="#overview">
            <span>XMAXX</span>
            <small>speed is the product</small>
          </a>

          <nav className="workspace-nav" aria-label="Primary">
            {navLinks.map((link) => (
              <InteractiveLink
                key={link.id}
                className={`workspace-nav__link${
                  activeNav === link.id ? ' workspace-nav__link--active' : ''
                }`}
                href={`#${link.id}`}
                onClick={() => setActiveNav(link.id)}
              >
                {link.label}
              </InteractiveLink>
            ))}
          </nav>

          <div className="workspace-topbar__actions">
            <motion.button
              type="button"
              className="command-trigger"
              onClick={() => runWorkspaceAction('open-command')}
              whileTap={{ scale: 0.985 }}
            >
              <span>Command center</span>
              <kbd>Cmd K</kbd>
            </motion.button>

            <AuthControls
              authState={authState}
              onOpenLogin={handleOpenLogin}
              onLogout={handleLogout}
              busyProvider={authBusyProvider}
              compact
            />
          </div>
        </motion.header>

        <Reveal as={motion.section} className="overview-grid" id="overview">
          <div className="panel launchpad launchpad--active">
            <div className="panel-heading panel-heading--tight">
              <div>
                <p className="eyebrow">Operating layer</p>
                <h1>
                  Linear speed with an AI brain, Vercel restraint, Notion
                  flexibility, and Stripe-grade finish.
                </h1>
              </div>
              <StatusPill status="live" />
            </div>

            <p className="launchpad__lede">
              Home is now a live workspace. It keeps actions close, surfaces state
              continuously, and lets the user operate the system instead of
              browsing a dashboard.
            </p>

            <div className="launchpad__actions">
              <motion.button
                type="button"
                className="primary-button"
                onClick={() => runWorkspaceAction('run-sweep')}
                whileTap={{ scale: 0.985 }}
              >
                Run system sweep
              </motion.button>
              <motion.button
                type="button"
                className="ghost-button"
                onClick={() => runWorkspaceAction('auth-audit')}
                whileTap={{ scale: 0.985 }}
              >
                Audit access
              </motion.button>
              <motion.button
                type="button"
                className="ghost-button"
                onClick={() => runWorkspaceAction('focus-runtime')}
                whileTap={{ scale: 0.985 }}
              >
                Promote runtime
              </motion.button>
            </div>

            <div className="stats-grid">
              {workspaceStats.map((stat) => (
                <div key={stat.label} className="stat-card">
                  <strong>{stat.value}</strong>
                  <span>{stat.label}</span>
                </div>
              ))}
            </div>
          </div>

          <div className="panel signal-card">
            <div className="signal-card__overlay">
              <div className="panel-heading panel-heading--tight">
                <div>
                  <p className="eyebrow">System map</p>
                  <h2>Feed, board, rail, and runtime now read as one surface.</h2>
                </div>
                <span className="mini-label">Live topology</span>
              </div>

              <div className="signal-card__strips" aria-hidden="true">
                <span />
                <span />
                <span />
              </div>

              <p className="signal-card__body">
                The visual system stays cold and minimal, but the interface never
                feels inert. Motion is short, state is obvious, and every panel is
                built to expand rather than redirect.
              </p>
            </div>

            <img
              className="signal-card__image"
              src="/waterbox.png"
              alt="Waterbox product"
            />
          </div>
        </Reveal>

        <div className="workspace-grid">
          <div className="workspace-main">
            <Reveal as={motion.section} className="panel feed-panel" id="feed" delay={0.05}>
              <div className="panel-heading">
                <div>
                  <p className="eyebrow">What’s being maxxed</p>
                  <h2>Cards expand inline so the feed behaves like a workspace.</h2>
                </div>
                <span className="mini-label">{activeStream.title} selected</span>
              </div>

              <StaggerGroup as={motion.div} className="stream-grid" staggerChildren={0.06}>
                {streams.map((stream) => {
                  const expanded = expandedStreamId === stream.id
                  const active = activeStreamId === stream.id

                  return (
                    <StaggerItem key={stream.id}>
                      <InteractiveSurface
                        as={motion.article}
                        layout
                        className={`stream-card${expanded ? ' stream-card--expanded' : ''}${
                          active ? ' stream-card--active' : ''
                        }`}
                        onClick={() => selectStream(stream.id)}
                      >
                        <div className="stream-card__head">
                          <div>
                            <p className="stream-card__lane">{stream.lane}</p>
                            <h3>{stream.title}</h3>
                          </div>
                          <span className="stream-card__status">{stream.status}</span>
                        </div>

                        <p className="stream-card__summary">{stream.summary}</p>

                        <div className="stream-card__metrics">
                          {stream.metrics.map((metric) => (
                            <span key={metric}>{metric}</span>
                          ))}
                        </div>

                        <AnimatePresence initial={false}>
                          {expanded ? (
                            <motion.div
                              className="stream-card__details"
                              initial={{ opacity: 0, height: 0 }}
                              animate={{ opacity: 1, height: 'auto' }}
                              exit={{ opacity: 0, height: 0 }}
                              transition={{ duration: 0.22, ease: [0.22, 1, 0.36, 1] }}
                            >
                              <ul className="stream-card__notes">
                                {stream.notes.map((note) => (
                                  <li key={note}>{note}</li>
                                ))}
                              </ul>

                              <div className="stream-card__actions">
                                <motion.button
                                  type="button"
                                  className="ghost-button"
                                  onClick={(event) => {
                                    event.stopPropagation()
                                    setActiveStreamId(stream.id)
                                  }}
                                  whileTap={{ scale: 0.985 }}
                                >
                                  Keep selected
                                </motion.button>
                                <motion.button
                                  type="button"
                                  className="primary-button primary-button--small"
                                  onClick={(event) => {
                                    event.stopPropagation()
                                    runWorkspaceAction(stream.actionId)
                                  }}
                                  whileTap={{ scale: 0.985 }}
                                >
                                  {stream.actionLabel}
                                </motion.button>
                              </div>
                            </motion.div>
                          ) : null}
                        </AnimatePresence>
                      </InteractiveSurface>
                    </StaggerItem>
                  )
                })}
              </StaggerGroup>
            </Reveal>

            <div className="workspace-row">
              <Reveal as={motion.section} className="panel board-panel" id="board" delay={0.08}>
                <div className="panel-heading">
                  <div>
                    <p className="eyebrow">State board</p>
                    <h2>No dead UI. Every lane shows whether it is active, stable, or needs attention.</h2>
                  </div>
                  <span className="mini-label">Selected: {activeStream.lane}</span>
                </div>

                <div className="process-list">
                  {renderedProcesses.map((process) => (
                    <div key={process.id} className="process-row">
                      <div className="process-row__copy">
                        <strong>{process.label}</strong>
                        <span>{process.detail}</span>
                      </div>
                      <StatusPill status={process.status} />
                    </div>
                  ))}
                </div>
              </Reveal>

              <Reveal as={motion.section} className="panel note-panel" delay={0.11}>
                <div className="panel-heading">
                  <div>
                    <p className="eyebrow">Operator note</p>
                    <h2>Inline editing keeps the surface feeling owned, not fixed.</h2>
                  </div>
                  <span className="mini-label">{noteState === 'saving' ? 'Saving...' : 'Synced'}</span>
                </div>

                <label className="note-editor">
                  <span>Working hypothesis</span>
                  <textarea
                    value={workspaceNote}
                    onChange={(event) => {
                      setWorkspaceNote(event.target.value)
                      setNoteState('saving')
                      if (noteSyncTimerRef.current) {
                        window.clearTimeout(noteSyncTimerRef.current)
                      }
                      noteSyncTimerRef.current = window.setTimeout(() => {
                        noteSyncTimerRef.current = 0
                        setNoteState('synced')
                      }, 320)
                    }}
                  />
                </label>

                <div className="note-panel__actions">
                  <motion.button
                    type="button"
                    className="ghost-button"
                    onClick={() => focusSection('feed')}
                    whileTap={{ scale: 0.985 }}
                  >
                    Return to feed
                  </motion.button>
                  <motion.button
                    type="button"
                    className="primary-button primary-button--small"
                    onClick={() => runWorkspaceAction('compose-brief')}
                    whileTap={{ scale: 0.985 }}
                  >
                    Draft build brief
                  </motion.button>
                </div>
              </Reveal>
            </div>

            <div className="workspace-row">
              <Reveal as={motion.section} className="panel activity-panel" delay={0.14}>
                <div className="panel-heading">
                  <div>
                    <p className="eyebrow">Recent activity</p>
                    <h2>Feed and dashboard blend together so momentum stays visible.</h2>
                  </div>
                  <span className="mini-label">Recent first</span>
                </div>

                <div className="activity-list">
                  {activity.map((item) => (
                    <div key={item.id} className={`activity-item activity-item--${item.tone}`}>
                      <div className="activity-item__meta">
                        <span>{item.lane}</span>
                        <small>{item.time}</small>
                      </div>
                      <strong>{item.title}</strong>
                      <p>{item.detail}</p>
                    </div>
                  ))}
                </div>
              </Reveal>

              <Reveal as={motion.section} className="panel stack-panel" id="stack" delay={0.17}>
                <div className="panel-heading">
                  <div>
                    <p className="eyebrow">Platform stack</p>
                    <h2>The UI only feels expensive if the delivery path feels disciplined.</h2>
                  </div>
                  <span className="mini-label">Runtime-backed</span>
                </div>

                <div className="stack-list">
                  {stackLayers.map((layer) => (
                    <div key={layer.title} className="stack-item">
                      <strong>{layer.title}</strong>
                      <p>{layer.body}</p>
                    </div>
                  ))}
                </div>
              </Reveal>
            </div>
          </div>

          <Reveal as={motion.aside} className="panel agent-rail" delay={0.07}>
            <div className="panel-heading">
              <div>
                <p className="eyebrow">Agent rail</p>
                <h2>AI sits beside the operator, not behind a hidden modal.</h2>
              </div>
              <StatusPill status="live" />
            </div>

            <div className="agent-rail__hero">
              <strong>{agentMode}</strong>
              <p>{agentResult}</p>
            </div>

            <div className="agent-rail__section">
              <p className="agent-rail__label">Suggested actions</p>
              <div className="suggestion-list">
                {agentSuggestions.map((suggestion) => (
                  <motion.button
                    key={suggestion.id}
                    type="button"
                    className={`suggestion-card${
                      selectedSuggestionId === suggestion.id ? ' suggestion-card--active' : ''
                    }`}
                    onClick={() => {
                      setSelectedSuggestionId(suggestion.id)
                      runWorkspaceAction(suggestion.actionId)
                    }}
                    whileTap={{ scale: 0.985 }}
                  >
                    <strong>{suggestion.label}</strong>
                    <span>{suggestion.detail}</span>
                  </motion.button>
                ))}
              </div>
            </div>

            <div className="agent-rail__section">
              <p className="agent-rail__label">Live results</p>
              <div className="console-list">
                {activity.slice(0, 3).map((item) => (
                  <div key={item.id} className="console-line">
                    <span className="console-line__pulse" />
                    <div>
                      <strong>{item.lane}</strong>
                      <p>{item.title}</p>
                    </div>
                  </div>
                ))}
              </div>
            </div>

            <OperatorAccessCard
              authState={authState}
              notice={authNotice}
              onOpenLogin={handleOpenLogin}
              onLogout={handleLogout}
              busyProvider={authBusyProvider}
            />
          </Reveal>
        </div>
      </main>

      <AnimatePresence>
        {isCommandOpen ? (
          <CommandCenter
            open={isCommandOpen}
            onClose={() => setIsCommandOpen(false)}
            query={commandQuery}
            onQueryChange={handleCommandQueryChange}
            commands={filteredCommands}
            selectedIndex={commandIndex}
            onSelectIndex={setCommandIndex}
            onRunCommand={runCommand}
          />
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
    </>
  )
}

export default App
