import { useEffect, useRef, useState } from 'react'
import { ApiTokensPage, ProfilePage } from './components/ProfileWorkspace'
import './index.css'

const homeNavLinks = [
  { href: '#manifesto', label: 'Manifesto', page: 'home' },
  { href: '#domains', label: 'Domains', page: 'home' },
  { href: '#stack', label: 'Stack', page: 'home' },
  { href: '/core-unit', label: 'Core Unit', page: 'core-unit' },
]

const coreUnitNavLinks = [
  { href: '/', label: 'Maxxing OS', page: 'home' },
  { href: '#product-overview', label: 'Overview', page: 'core-unit' },
  { href: '#specs', label: 'Specs', page: 'core-unit' },
  { href: '#modes', label: 'Modes', page: 'core-unit' },
  { href: '#security', label: 'Security', page: 'core-unit' },
]

const accountNavLinks = [
  { href: '/profile', label: 'Profile', page: 'profile' },
  { href: '/access-tokens', label: 'API Access', page: 'access-tokens' },
]

const socialLinks = [
  {
    href: 'https://github.com/xmaxxai',
    label: 'GitHub',
    handle: 'xmaxxai',
    icon: 'github-icon',
    viewBox: '0 0 19 19',
    detail: 'Source, forks, and public build path',
  },
  {
    href: 'https://x.com/xmaxxai',
    label: 'X',
    handle: 'xmaxxai',
    icon: 'x-icon',
    viewBox: '0 0 19 19',
    detail: 'Signals, drops, and live updates',
  },
]

const homeHeroStats = [
  {
    label: 'Build Posture',
    value: 'Open',
    detail: 'Inspectable systems, forkable workflows, and community-owned improvement loops.',
  },
  {
    label: 'Loop Horizon',
    value: '24/7',
    detail: 'AI agents can keep scoring, planning, and nudging across the surfaces you want to maxx.',
  },
  {
    label: 'Control Model',
    value: 'Yours',
    detail: 'You choose the stack, the metrics, the prompts, and what better actually means.',
  },
]

const maxxTargets = [
  'Looks',
  'Style',
  'Physique',
  'Sleep',
  'Focus',
  'Code',
  'Money',
  'Space',
]

const softwareDeckColumns = [
  {
    title: 'Inputs',
    items: ['Photos', 'Biometrics', 'Calendar', 'Spending', 'Codebase', 'Environment'],
  },
  {
    title: 'Agents',
    items: ['Audit', 'Plan', 'Critique', 'Automate', 'Remind', 'Escalate'],
  },
  {
    title: 'Outputs',
    items: ['Routines', 'Checklists', 'PRs', 'Protocols', 'Reports', 'Next moves'],
  },
]

const softwareDeckEvents = [
  {
    label: 'LOOKSMAXX',
    detail: 'Grooming routine tightened, fit issues flagged, and presentation notes queued.',
  },
  {
    label: 'CODEMAXX',
    detail: 'Backlog triaged, repo context summarized, and shipping sequence proposed.',
  },
  {
    label: 'SLEEPMAXX',
    detail: 'Late-night drift detected, recovery plan updated, and tomorrow adjusted.',
  },
]

const maxxDomains = [
  {
    title: 'Looksmaxx',
    description: 'Make presentation measurable instead of vague.',
    items: [
      'Hair, skin, beard, and grooming audits',
      'Photo feedback, angles, and profile cleanup',
      'Routine tracking that compounds visible gains',
    ],
  },
  {
    title: 'Stylemaxx',
    description: 'Treat clothes, fit, and personal taste like a system.',
    items: [
      'Outfit planning from your actual wardrobe',
      'Shopping shortlists with fewer bad buys',
      'Occasion-specific style decision support',
    ],
  },
  {
    title: 'Physiquemaxx',
    description: 'Training, recovery, and nutrition loops that close.',
    items: [
      'Workout planning around goals and recovery',
      'Body-comp trend analysis and habit adherence',
      'Nutrition prompts and meal routine support',
    ],
  },
  {
    title: 'Sleepmaxx',
    description: 'Upgrade energy by fixing the quiet bottleneck.',
    items: [
      'Sleep timing and drift detection',
      'Wind-down automation and stimulant guardrails',
      'Morning readiness scoring and adjustments',
    ],
  },
  {
    title: 'Focusmaxx',
    description: 'Reduce chaos and convert intent into action.',
    items: [
      'Deep-work block design and interruption control',
      'Priority compression from noisy task lists',
      'Daily review loops that stop drift early',
    ],
  },
  {
    title: 'Codemaxx',
    description: 'Aim AI at the repo, not just the prompt box.',
    items: [
      'Codebase summaries, task decomposition, and patch plans',
      'PR drafting, review prep, and issue triage',
      'Local tooling for faster engineering loops',
    ],
  },
  {
    title: 'Moneymaxx',
    description: 'Point AI at leverage, waste, and opportunity.',
    items: [
      'Spending reviews and pattern detection',
      'Revenue and pipeline follow-up prompts',
      'Decision support for allocation and tradeoffs',
    ],
  },
  {
    title: 'Spacemaxx',
    description: 'Your room, desk, and environment shape output.',
    items: [
      'Desk reset and room maintenance protocols',
      'Lighting, noise, and layout optimization',
      'Environment cues that support the routine you want',
    ],
  },
]

const stackSections = [
  {
    title: 'Signal Capture',
    description: 'Pull in the inputs that actually shape outcomes.',
    items: [
      'Photos, notes, wearables, tasks, budgets, and repos',
      'Structured logs for habits, routines, and checkpoints',
      'Human feedback folded into the same loop',
    ],
  },
  {
    title: 'Scoring Layer',
    description: 'Turn fuzzy self-improvement into legible metrics.',
    items: [
      'Custom rubrics for each maxx domain',
      'Baseline, trend, and regression tracking',
      'Priority scoring so effort goes where it matters',
    ],
  },
  {
    title: 'Agent Loops',
    description: 'Use AI for continuous critique, planning, and execution.',
    items: [
      'Personal agents for each surface of life',
      'Scheduled reviews, nudges, and replans',
      'Escalation paths when autonomy should stop',
    ],
  },
  {
    title: 'Open Playbooks',
    description: 'Share tactics, protocols, and templates publicly.',
    items: [
      'Community-maintained routines and prompts',
      'Forkable systems instead of guru black boxes',
      'Public iteration on what actually works',
    ],
  },
  {
    title: 'Runtime Flexibility',
    description: 'Run locally, in the cloud, or on dedicated hardware.',
    items: [
      'Laptop-first workflows for builders',
      'Always-on deployment when you want persistent loops',
      'Cluster-ready posture for broader coordination',
    ],
  },
  {
    title: 'Operator Control',
    description: 'Keep people in command of the system.',
    items: [
      'Prompt, model, and policy choices stay visible',
      'Audit trails for what the agents changed',
      'Identity and access kept separate from the public thesis',
    ],
  },
]

const coreUnitHeroStats = [
  {
    label: 'Local Response',
    value: '<10ms',
    detail: 'Local-first compute keeps agent loops immediate across connected systems.',
  },
  {
    label: 'Acoustic Output',
    value: '0 dB',
    detail: 'Passive thermal dissipation with no onboard fan.',
  },
  {
    label: 'Average Draw',
    value: '8-15W',
    detail: 'Auto low-power idle preserves efficiency between workloads.',
  },
]

const coreUnitHighlights = [
  '180 x 110 x 95 mm',
  '1.2 kg',
  'Wi-Fi 6',
  'Bluetooth 5.3',
  '1 Gbps Ethernet',
  'Cluster ready',
]

const coreUnitSpecSections = [
  {
    title: 'Physical Design',
    description: 'Compact hardware with a quiet, architectural silhouette.',
    rows: [
      ['Form Factor', 'Compact rectangular monolith'],
      ['Material', 'Matte anodized aluminum shell'],
      ['Finish', 'Stealth black with anti-fingerprint coating'],
      ['Edge Detail', 'Soft-radius corners with LED perimeter strip'],
      ['Dimensions', '~180mm (L) x 110mm (W) x 95mm (H)'],
      ['Weight', '~1.2 kg'],
    ],
  },
  {
    title: 'Interface & Controls',
    description: 'Minimal surface language with visible state and no clutter.',
    rows: [
      ['Top Panel', 'Capacitive touch surface'],
      ['Design', 'No physical buttons'],
    ],
    ledStates: [
      { state: 'Blue', meaning: 'Active', tone: 'blue' },
      { state: 'Amber', meaning: 'Processing', tone: 'amber' },
      { state: 'Red', meaning: 'Error', tone: 'red' },
      { state: 'Off', meaning: 'Idle', tone: 'off' },
    ],
  },
  {
    title: 'Performance Core',
    description: 'Built for continuous local execution, automation, and optimization.',
    rows: [
      ['Processing Type', 'Local-first compute node'],
      ['Architecture', 'Multi-core AI-optimized chip'],
      ['Latency', '<10ms local response'],
      ['Cooling', 'Passive thermal dissipation (fanless)'],
    ],
  },
  {
    title: 'Connectivity',
    description: 'Ready for standalone use or distributed deployment.',
    rows: [
      ['Wireless', 'Wi-Fi 6 / Bluetooth 5.3'],
      ['Rear Ports', 'USB-C (power + data), 2x USB-A, Ethernet (1 Gbps)'],
      ['Sync Capability', 'Node-to-node mesh (cluster ready)'],
    ],
  },
  {
    title: 'Power',
    description: 'Lean power profile designed for always-on operation.',
    rows: [
      ['Input', 'USB-C PD'],
      ['Power Draw', '8-15W average'],
      ['Efficiency', 'Auto low-power idle state'],
    ],
  },
  {
    title: 'System Capabilities',
    description: 'Core software posture centered on local control and secure scaling.',
    items: [
      'Local AI processing',
      'Task automation engine',
      'Multi-domain optimization tracking',
      'Secure data storage (encrypted)',
      'Cluster networking (Xmaxx Network ready)',
    ],
  },
  {
    title: 'Security',
    description: 'Security model favors sovereignty, integrity, and operational trust.',
    id: 'security',
    items: [
      'End-to-end encryption',
      'Local data priority with no forced cloud dependency',
      'Secure boot architecture',
    ],
  },
  {
    title: 'Operating Conditions',
    description: 'Sized for desks, shelves, and rack-adjacent installs.',
    rows: [
      ['Temperature Range', '0°C to 40°C'],
      ['Noise', '0 dB (fanless)'],
      ['Placement', 'Desk / shelf / rack-compatible'],
    ],
  },
]

const coreUnitModes = [
  {
    title: 'Solo Node',
    body: 'Personal optimization system for one operator, one environment, and one local control surface.',
  },
  {
    title: 'Cluster Mode',
    body: 'Multi-device coordination across mesh-connected nodes for larger-scale optimization loops.',
  },
  {
    title: 'Builder Mode',
    body: 'Custom workflows, automation pipelines, and developer integration for deeper system extension.',
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

// Keep account tooling on standalone routes so the landing page stays focused.
function getCurrentPage() {
  if (typeof window === 'undefined') {
    return 'home'
  }

  const pathname = window.location.pathname.replace(/\/+$/, '') || '/'

  if (pathname === '/core-unit') {
    return 'core-unit'
  }

  if (pathname === '/profile') {
    return 'profile'
  }

  if (pathname === '/access-tokens') {
    return 'access-tokens'
  }

  return 'home'
}

function getSiteNavLinks(currentPage) {
  if (currentPage === 'home') {
    return [...homeNavLinks, ...accountNavLinks]
  }

  if (currentPage === 'core-unit') {
    return [...coreUnitNavLinks, ...accountNavLinks]
  }

  return [
    { href: '/', label: 'Maxxing OS', page: 'home' },
    { href: '/core-unit', label: 'Core Unit', page: 'core-unit' },
    ...accountNavLinks,
  ]
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
      body: `This browser now has an active ${label}-backed session on the XMAXX surface.`,
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
          href="/profile"
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

        <button type="button" className="ghost-button" onClick={onLogout}>
          Sign out
        </button>
      </div>
    )
  }

  return (
    <div className={className}>
      <button
        type="button"
        className="ghost-button"
        onClick={onOpenLogin}
        disabled={!authState.configured || Boolean(authState.error) || Boolean(busyProvider)}
      >
        {authState.error
          ? 'Auth unavailable'
          : busyProvider
            ? `Finishing ${getProviderLabel(busyProvider)}...`
            : availableProviders.length > 0
              ? 'Choose sign-in'
              : 'Auth not configured'}
      </button>
    </div>
  )
}

function AccessPanel({ authState, notice, onOpenLogin, onLogout, busyProvider = '' }) {
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
            ? 'Choose GitHub or Google to unlock the private surface.'
            : `Sign in with ${configuredProviderNames} to unlock the private surface.`
          : 'Operator auth is staged but not configured yet.'

  const body = authState.loading
    ? 'The surface is checking whether a browser session already exists.'
    : authState.error
      ? 'Login actions stay disabled until `/api/auth/session/` is reachable from the frontend.'
      : isAuthenticated
        ? 'This browser now carries an authenticated session owned by the deployed backend.'
        : authState.configured
          ? 'Sign-in opens in a popup so the backend can complete the OAuth exchange without interrupting the page.'
          : 'Once at least one provider has valid OAuth settings, this control will unlock the callback flow.'

  return (
    <section className="access-panel" id="access">
      <div className="access-panel__header">
        <div>
          <p className="section-kicker">Operator Access</p>
          <h3>{title}</h3>
        </div>
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
      </div>

      <p>{body}</p>

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
    <div className="auth-overlay" onClick={onClose}>
      <div
        className="auth-modal"
        role="dialog"
        aria-modal="true"
        aria-labelledby="auth-modal-title"
        onClick={(event) => event.stopPropagation()}
      >
        <div className="auth-modal__head">
          <div>
            <p className="eyebrow">Choose sign-in</p>
            <h2 id="auth-modal-title">
              Select the identity system that should own this browser session.
            </h2>
          </div>
          <button type="button" className="icon-button" onClick={onClose} aria-label="Close">
            ×
          </button>
        </div>

        <p className="auth-modal__copy">
          The backend completes the OAuth code exchange on the XMAXX origin and
          keeps the page intact while the popup finishes.
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
              <button
                key={provider.id}
                type="button"
                className={`provider-option${
                  providerState.configured ? ' provider-option--ready' : ''
                }`}
                onClick={() => onSelectProvider(provider.id)}
                disabled={disabled}
              >
                <div className="provider-option__head">
                  <div>
                    <p className="provider-option__eyebrow">{provider.eyebrow}</p>
                    <h3>{provider.label}</h3>
                  </div>
                  <span className={`provider-status provider-status--${providerState.configured ? 'ready' : 'attention'}`}>
                    {providerState.configured ? 'Ready' : 'Setup needed'}
                  </span>
                </div>
                <p>{provider.description}</p>
                <span className="provider-option__hint">
                  {getProviderStatusCopy(provider.id, providerState.configuredReason)}
                </span>
              </button>
            )
          })}
        </div>
      </div>
    </div>
  )
}

function SpecCard({ id, title, description, rows, items, ledStates }) {
  return (
    <article className="spec-card" id={id}>
      <div className="spec-card__header">
        <p className="section-kicker">Module</p>
        <h3>{title}</h3>
        <p>{description}</p>
      </div>

      {rows ? (
        <dl className="spec-list">
          {rows.map(([label, value]) => (
            <div className="spec-list__row" key={label}>
              <dt>{label}</dt>
              <dd>{value}</dd>
            </div>
          ))}
        </dl>
      ) : null}

      {items ? (
        <ul className="feature-list">
          {items.map((item) => (
            <li key={item}>{item}</li>
          ))}
        </ul>
      ) : null}

      {ledStates ? (
        <div className="led-states" aria-label="LED indicator states">
          {ledStates.map(({ state, meaning, tone }) => (
            <div className="led-state" key={state}>
              <span className={`led-state__dot led-state__dot--${tone}`} />
              <strong>{state}</strong>
              <span>{meaning}</span>
            </div>
          ))}
        </div>
      ) : null}
    </article>
  )
}

function SocialLink({ href, label, handle, icon, viewBox, detail }) {
  return (
    <a
      className="social-link"
      href={href}
      target="_blank"
      rel="noreferrer"
      aria-label={`${label} profile for @${handle}`}
    >
      <span className="social-link__icon" aria-hidden="true">
        <svg viewBox={viewBox}>
          <use href={`/icons.svg#${icon}`} />
        </svg>
      </span>

      <span className="social-link__copy">
        <strong>{label}</strong>
        <span>@{handle}</span>
        <small>{detail}</small>
      </span>
    </a>
  )
}

function SoftwareDeck() {
  return (
    <div className="hero-visual__frame hero-visual__frame--software">
      <div className="maxx-console" aria-label="XMAXX software control deck">
        <div className="maxx-console__head">
          <span className="maxx-console__path">maxx://orchestrator</span>
          <span className="maxx-console__status">8 domains live</span>
        </div>

        <div className="maxx-console__grid">
          {softwareDeckColumns.map(({ title, items }) => (
            <section className="maxx-console__column" key={title}>
              <p>{title}</p>
              <ul>
                {items.map((item) => (
                  <li key={item}>{item}</li>
                ))}
              </ul>
            </section>
          ))}
        </div>

        <div className="maxx-console__events">
          {softwareDeckEvents.map(({ label, detail }) => (
            <article className="maxx-console__event" key={label}>
              <span>{label}</span>
              <strong>{detail}</strong>
            </article>
          ))}
        </div>
      </div>
    </div>
  )
}

function SiteFooter() {
  return (
    <footer className="site-footer" aria-label="XMAXX social links">
      <div className="site-footer__copy">
        <p className="eyebrow">Direct Links</p>
        <p>
          Track the public build path, release flow, and live updates from the XMAXX
          account surface.
        </p>
      </div>

      <div className="site-footer__links">
        {socialLinks.map((link) => (
          <SocialLink key={link.label} {...link} />
        ))}
      </div>
    </footer>
  )
}

function HomePage({
  authState,
  authNotice,
  onOpenLogin,
  onLogout,
  authBusyProvider,
}) {
  return (
    <>
      <section className="hero-panel" id="overview">
        <div className="hero-copy">
          <p className="eyebrow">Open-source maxxing software</p>
          <h1>Open-source software for maxxing everything.</h1>
          <p className="hero-copy__lede">
            XMAXX is the operating system for turning AI into compounding self-improvement
            loops across looks, physique, sleep, focus, code, money, and environment.
          </p>

          <div className="verb-strip" aria-label="Maxx surfaces">
            {maxxTargets.map((target) => (
              <span key={target}>{target}</span>
            ))}
          </div>

          <div className="hero-actions">
            <a
              className="button button--solid"
              href="https://github.com/xmaxxai"
              target="_blank"
              rel="noreferrer"
            >
              View GitHub
            </a>
            <a className="button button--ghost" href="/core-unit">
              See current product
            </a>
          </div>

          <p className="hero-copy__support">
            Think maxxing OS, maxxing AI, XMAXX: a public toolkit for building better
            routines, better decisions, and better systems with agents in the loop.
          </p>

          <div className="hero-stats">
            {homeHeroStats.map(({ label, value, detail }) => (
              <article className="hero-stat" key={label}>
                <p>{label}</p>
                <strong>{value}</strong>
                <span>{detail}</span>
              </article>
            ))}
          </div>
        </div>

        <div className="hero-visual">
          <SoftwareDeck />

          <div className="hero-visual__meta">
            <div>
              <p className="section-kicker">Maxx surfaces</p>
              <h2>Looks, code, sleep, money, rooms, routines, and whatever comes next.</h2>
            </div>

            <div className="hardware-highlights">
              {maxxTargets.map((item) => (
                <span key={item}>{item}</span>
              ))}
            </div>
          </div>
        </div>
      </section>

      <section className="positioning-band" id="manifesto">
        <div>
          <p className="eyebrow">Manifesto</p>
          <h2>Open-source infrastructure for self-optimization.</h2>
        </div>

        <div className="positioning-band__copy">
          <p>
            Looksmaxxing was the meme. XMAXX turns maxxing into software: measurable,
            extensible, agent-driven loops that can improve almost any personal or
            operational surface.
          </p>
          <p>
            The point is not a closed guru product. The point is an open system that
            people can fork, inspect, remix, and use to maxx the parts of life they care
            about most.
          </p>
        </div>
      </section>

      <section className="section-block" id="domains">
        <div className="section-heading">
          <p className="eyebrow">Maxx Domains</p>
          <h2>Start with looks. Keep going until the whole operating system improves.</h2>
        </div>

        <div className="spec-grid">
          {maxxDomains.map((section) => (
            <SpecCard key={section.title} {...section} />
          ))}
        </div>
      </section>

      <section className="section-block" id="stack">
        <div className="section-heading">
          <p className="eyebrow">Stack</p>
          <h2>The software stack behind open-source maxxing.</h2>
        </div>

        <div className="spec-grid">
          {stackSections.map((section) => (
            <SpecCard key={section.title} {...section} />
          ))}
        </div>
      </section>

      <section className="section-block">
        <div className="section-heading">
          <p className="eyebrow">Builder Surface</p>
          <h2>The authenticated workspace still exists, but it no longer leads the story.</h2>
          <p>
            Sign in when you want the private operator tools. The public front door now
            stays focused on the open-source maxxing system itself.
          </p>
        </div>

        <AccessPanel
          authState={authState}
          notice={authNotice}
          onOpenLogin={onOpenLogin}
          onLogout={onLogout}
          busyProvider={authBusyProvider}
        />
      </section>

      <section className="closing-panel">
        <p className="eyebrow">Current Product</p>
        <h2>The Core Unit stays in the stack, just not at the center of the homepage.</h2>
        <p>
          XMAXX Core Unit is still the physical deployment surface for people who want a
          persistent, fanless, local-first node. Its specs and operating profile now live
          on their own page.
        </p>

        <div className="hardware-highlights">
          {coreUnitHighlights.map((item) => (
            <span key={item}>{item}</span>
          ))}
        </div>

        <div className="hero-actions">
          <a className="button button--solid" href="/core-unit">
            Open Core Unit page
          </a>
          <a
            className="button button--ghost"
            href="https://github.com/xmaxxai"
            target="_blank"
            rel="noreferrer"
          >
            Track the repo
          </a>
        </div>
      </section>

      <SiteFooter />
    </>
  )
}

function CoreUnitPage() {
  return (
    <>
      <section className="hero-panel" id="product-overview">
        <div className="hero-copy">
          <p className="eyebrow">Current product surface</p>
          <h1>XMAXX Core Unit is the dedicated hardware node.</h1>
          <p className="hero-copy__lede">
            The homepage now centers the open-source maxxing software thesis. This page
            keeps the current physical product, its hardware posture, and its deployment
            profile in one place.
          </p>

          <div className="verb-strip" aria-label="Core unit posture">
            <span>Persistent</span>
            <span>Fanless</span>
            <span>Local-first</span>
          </div>

          <div className="hero-actions">
            <a className="button button--solid" href="/">
              Back to Maxxing OS
            </a>
            <a
              className="button button--ghost"
              href="https://github.com/xmaxxai"
              target="_blank"
              rel="noreferrer"
            >
              View GitHub
            </a>
          </div>

          <div className="hero-stats">
            {coreUnitHeroStats.map(({ label, value, detail }) => (
              <article className="hero-stat" key={label}>
                <p>{label}</p>
                <strong>{value}</strong>
                <span>{detail}</span>
              </article>
            ))}
          </div>
        </div>

        <div className="hero-visual">
          <div className="hero-visual__frame">
            <img
              src="/waterbox.png"
              alt="XMAXX Core Unit in stealth black with blue LED perimeter strip"
            />
          </div>

          <div className="hero-visual__meta">
            <div>
              <p className="section-kicker">Hardware Envelope</p>
              <h2>Agent device. Fanless core. Physical deployment.</h2>
            </div>

            <div className="hardware-highlights">
              {coreUnitHighlights.map((item) => (
                <span key={item}>{item}</span>
              ))}
            </div>
          </div>
        </div>
      </section>

      <section className="positioning-band">
        <p className="eyebrow">Positioning</p>
        <div className="positioning-band__copy">
          <p>
            XMAXX Core Unit is AI agent hardware built for interface-level operation: a
            persistent box that can interpret software, move through workflows, and
            execute actions with controlled autonomy.
          </p>
          <p>
            Instead of stitching together scripts and remote sessions, XMAXX turns an
            agent runtime into a reliable physical product.
          </p>
        </div>
      </section>

      <section className="section-block" id="specs">
        <div className="section-heading">
          <p className="eyebrow">Specification Matrix</p>
          <h2>Hardware, runtime, and security posture in one surface.</h2>
        </div>

        <div className="spec-grid">
          {coreUnitSpecSections.map((section) => (
            <SpecCard key={section.title} {...section} />
          ))}
        </div>
      </section>

      <section className="section-block" id="modes">
        <div className="section-heading">
          <p className="eyebrow">Use Case Modes</p>
          <h2>Deploy as a personal node, a clustered network member, or a builder platform.</h2>
        </div>

        <div className="mode-grid">
          {coreUnitModes.map(({ title, body }) => (
            <article className="mode-card" key={title}>
              <p className="section-kicker">Mode</p>
              <h3>{title}</h3>
              <p>{body}</p>
            </article>
          ))}
        </div>
      </section>

      <section className="closing-panel">
        <p className="eyebrow">Operating Statement</p>
        <h2>Operational AI, delivered as hardware.</h2>
        <p>
          XMAXX Core Unit is designed to stay on, stay quiet, and run task-level actions
          from a persistent local-first agent runtime.
        </p>
      </section>

      <SiteFooter />
    </>
  )
}

function App() {
  const currentPage = getCurrentPage()
  const siteNavLinks = getSiteNavLinks(currentPage)
  const [isAuthModalOpen, setIsAuthModalOpen] = useState(false)
  const [authNotice, setAuthNotice] = useState(() => readAuthNotice())
  const [authState, setAuthState] = useState(buildInitialAuthState)
  const [authBusyProvider, setAuthBusyProvider] = useState('')
  const authPopupMonitorRef = useRef(0)

  useEffect(() => {
    const controller = new AbortController()
    void syncAuthSession(setAuthState, controller.signal)

    return () => controller.abort()
  }, [])

  useEffect(() => {
    return () => {
      if (authPopupMonitorRef.current) {
        window.clearInterval(authPopupMonitorRef.current)
      }
    }
  }, [])

  useEffect(() => {
    const handleAuthMessage = (event) => {
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

    window.addEventListener('message', handleAuthMessage)

    return () => {
      window.removeEventListener('message', handleAuthMessage)
    }
  }, [])

  useEffect(() => {
    if (!isAuthModalOpen) {
      return undefined
    }

    const handleKeyDown = (event) => {
      if (event.key === 'Escape') {
        setIsAuthModalOpen(false)
      }
    }

    window.addEventListener('keydown', handleKeyDown)

    return () => {
      window.removeEventListener('keydown', handleKeyDown)
    }
  }, [isAuthModalOpen])

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
    <div className="spec-page">
      <div className="ambient ambient--left" />
      <div className="ambient ambient--right" />

      <header className="site-header">
        <a className="brand" href={currentPage === 'home' ? '#overview' : '/'} aria-label="XMAXX home">
          <span className="brand__mark">XMAXX</span>
          <span className="brand__sub">
            {currentPage === 'core-unit' ? 'Core Unit' : 'Maxxing OS'}
          </span>
        </a>

        <nav className="site-nav" aria-label="Page sections">
          {siteNavLinks.map(({ href, label, page }) => (
            <a
              key={href}
              href={href}
              aria-current={!href.startsWith('#') && currentPage === page ? 'page' : undefined}
            >
              {label}
            </a>
          ))}
        </nav>

        <div className="site-header__actions">
          <AuthControls
            authState={authState}
            onOpenLogin={handleOpenLogin}
            onLogout={handleLogout}
            busyProvider={authBusyProvider}
            compact
          />
        </div>
      </header>

      <main className="page-shell">
        {currentPage === 'profile' ? (
          <ProfilePage authState={authState} onOpenLogin={handleOpenLogin} />
        ) : currentPage === 'access-tokens' ? (
          <ApiTokensPage authState={authState} onOpenLogin={handleOpenLogin} />
        ) : currentPage === 'core-unit' ? (
          <CoreUnitPage />
        ) : (
          <HomePage
            authState={authState}
            authNotice={authNotice}
            onOpenLogin={handleOpenLogin}
            onLogout={handleLogout}
            authBusyProvider={authBusyProvider}
          />
        )}
      </main>

      <AuthModal
        open={isAuthModalOpen}
        onClose={() => setIsAuthModalOpen(false)}
        authState={authState}
        onSelectProvider={handleProviderLogin}
        busyProvider={authBusyProvider}
      />
    </div>
  )
}

export default App
