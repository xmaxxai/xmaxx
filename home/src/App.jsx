import { useEffect, useRef, useState } from 'react'
import { ApiTokensPage, ProfilePage } from './components/ProfileWorkspace'
import { InteractiveSurface, Reveal, StaggerGroup, StaggerItem } from './components/motion-primitives'
import './index.css'

const homeNavLinks = [
  { href: '#platform', label: 'Platform', page: 'home' },
  { href: '#automation', label: 'Automation', page: 'home' },
  { href: '#how-it-works', label: 'How It Works', page: 'home' },
  { href: '#open-source', label: 'Open Source', page: 'home' },
  { href: '/computer', label: 'XMAXX Computer', page: 'computer' },
]

const computerNavLinks = [
  { href: '/', label: 'Home', page: 'home' },
  { href: '#product-overview', label: 'Overview', page: 'computer' },
  { href: '#specs', label: 'Specs', page: 'computer' },
  { href: '#modes', label: 'Deploy', page: 'computer' },
  { href: '#security', label: 'Security', page: 'computer' },
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
    detail: 'Source, issues, and open build path',
  },
]

const developerAccessConfig = {
  productId: import.meta.env.VITE_STRIPE_PRODUCT_ID || 'prod_UHXHHhIqeNr9YX',
  checkoutUrl: import.meta.env.VITE_STRIPE_PAYMENT_LINK || '',
  communityUrl: import.meta.env.VITE_XMAXX_DEVELOPER_COMMUNITY_URL || '',
}

const developerAccessIncludes = [
  'Web-based control interface',
  'Developer SDK and APIs',
  'Early access features and updates',
  'Access to the private XMAXX developer community',
]

const scopePoints = [
  {
    title: 'Automate machine operations',
    description:
      'Run repeatable work across drones, devices, and connected systems from one control layer.',
  },
  {
    title: 'Automate software and computers',
    description:
      'Move routine checks, system tasks, and desktop workflows out of manual interfaces.',
  },
  {
    title: 'Keep the core open',
    description:
      'The codebase, deployment path, and product surface stay visible so builders can inspect and extend the system.',
  },
]

const homeHeroStats = [
  {
    label: 'Scope',
    value: 'Software + machines',
    detail: 'One control layer across workstations, connected systems, and machine-heavy environments.',
  },
  {
    label: 'Model',
    value: 'Automation first',
    detail: 'Define what should happen, then let XMAXX handle the control path.',
  },
  {
    label: 'Posture',
    value: 'Open source',
    detail: 'The code, deployment path, and product direction stay visible and usable by builders.',
  },
]

const commandTargets = [
  'Software',
  'Computers',
  'Devices',
  'Drones',
  'System tasks',
  'Operations',
]

const voiceHighlights = [
  'Formal project page',
  'Automation core',
  'Open codebase',
  'Product surface',
  'Extensible APIs',
  'Built in public',
  'Operator-first',
]

const voiceDeckWaves = [22, 40, 28, 56, 34, 62, 76, 48, 58, 32, 46, 24]

const voiceDeckColumns = [
  {
    title: 'Input',
    items: ['Define intent', 'Mission or task', 'Operator constraints', 'Target systems'],
  },
  {
    title: 'Agent',
    items: ['Interpret request', 'Plan execution', 'Resolve capabilities', 'Select actions'],
  },
  {
    title: 'Execution',
    items: ['Run across devices', 'Drive systems', 'Track state', 'Return feedback'],
  },
]

const voiceDeckActions = [
  {
    label: 'INPUT',
    detail: 'You define intent and constraints for the task, mission, or system operation.',
  },
  {
    label: 'AGENT',
    detail: 'XMAXX interprets the command and maps it into an executable control path.',
  },
  {
    label: 'FEEDBACK',
    detail: 'Execution results stay visible so operators can review, optimize, and iterate.',
  },
]

const operatorFlowSections = [
  {
    title: 'Input',
    description: 'Start with the task or outcome instead of the interface that would normally require manual work.',
    items: ['Task', 'Goal', 'Context'],
  },
  {
    title: 'Agent',
    description: 'XMAXX interprets the request and turns it into a concrete plan against the systems it can reach.',
    items: ['Interpret', 'Plan', 'Map capabilities'],
  },
  {
    title: 'Execution',
    description: 'The system executes across software, computers, and machines from one control layer.',
    items: ['Actions', 'Automation', 'Visible steps'],
  },
  {
    title: 'Feedback',
    description: 'Results stay visible so operators can review what happened and adjust the next run.',
    items: ['Status', 'Review', 'Adjust'],
  },
]

const proofSections = [
  {
    title: 'Open source project',
    description: 'The repo is public, the deployment path is visible, and the project is being built in the open.',
    items: ['Public code', 'Public delivery path', 'Builder access'],
  },
  {
    title: 'Automation core',
    description: 'The main idea is straightforward: automate as much practical work as possible across software and machines.',
    items: ['Unified control layer', 'Operational automation', 'Visible execution'],
  },
  {
    title: 'Product surface',
    description: 'XMAXX Computer gives the project a concrete product surface instead of leaving it as a concept.',
    items: ['Dedicated product page', 'Software surface', 'Hardware direction'],
  },
]

const buildUseCases = [
  {
    title: 'Operational workflows',
    description: 'Repeatable work that should run the same way every time.',
  },
  {
    title: 'Inspection and monitoring',
    description: 'Checks and monitoring loops that should not depend on manual oversight.',
  },
  {
    title: 'Computer automation',
    description: 'Desktop and system tasks that should move out of manual interfaces and into repeatable execution.',
  },
  {
    title: 'Multi-system operations',
    description: 'One layer coordinating several machines or software surfaces together.',
  },
]

const customerSections = [
  {
    title: 'Operations teams',
    description: 'Teams that need consistent execution across systems instead of more manual control work.',
  },
  {
    title: 'Infrastructure teams',
    description: 'Teams managing repeatable checks, monitoring, and anomaly response across real systems.',
  },
  {
    title: 'Builders',
    description: 'Developers who want an open automation core they can inspect, adapt, and ship with.',
  },
]

const offerSections = [
  {
    title: 'Open source automation core',
    description: 'Core software for turning operator intent into execution across software and machines.',
  },
  {
    title: 'XMAXX Computer',
    description: 'The current product surface for the runtime and its software and hardware direction.',
  },
  {
    title: 'Visible deployment path',
    description: 'A build and release flow that stays visible instead of disappearing behind a closed product stack.',
  },
]

const heroSurfaceNotes = [
  {
    label: 'Core',
    title: 'Automation first',
    detail: 'MAXX is built to move routine work out of manual control and into repeatable execution.',
  },
  {
    label: 'Scope',
    title: 'Software to machines',
    detail: 'The same project surface should cover software tasks, computers, devices, and machine operations.',
  },
  {
    label: 'Project',
    title: 'Open by default',
    detail: 'The code, delivery path, and current product direction stay visible in public.',
  },
]

const commandSurfaces = [
  {
    title: 'Live Voice Loop',
    description: 'The app is always listening when armed, and each pause becomes structured input.',
    items: [
      'Continuous transcription with partial updates',
      'A pause commits speech as mission input or fresh steering',
      'Voice commands like "stop loop" and "confirm action" are handled directly',
    ],
  },
  {
    title: 'Decision Models',
    description: 'Reasoning is not one vague blob; the app can structure planning through named frameworks.',
    items: [
      'OODA, Recognition-Primed, System 1 / 2, Bayes, RL, Predictive, and Cynefin',
      'Each loop stage gets its own prompt, narrative, bullets, and confidence',
      'The active model changes the scaffold, not just the label',
    ],
  },
  {
    title: 'Screen Text Resolver',
    description: 'The desktop loop can look at the screen and ground actions against visible text.',
    items: [
      'Fresh screenshots are captured through ScreenCaptureKit',
      'Vision OCR maps visible text into real screen coordinates',
      'The `find_screen_text` tool turns labels on screen into actionable points',
    ],
  },
  {
    title: 'Native Mouse Actions',
    description: 'The current execution bridge is real, but intentionally narrow.',
    items: [
      'Coordinate-based `mouse_move`, `mouse_click`, and `mouse_right_click`',
      'CGEvent HID posting through macOS when Accessibility is granted',
      'Targets can come from explicit coordinates or OCR-resolved text',
    ],
  },
  {
    title: 'Operator Approval',
    description: 'The loop asks before it commits to the wrong thing.',
    items: [
      'Questions, checkpoints, startup recovery, and action approval prompts',
      'Fresh speech can revise a waiting plan before execution',
      'The app distinguishes ready, queued, blocked, and done actions',
    ],
  },
  {
    title: 'Spoken Dialogue',
    description: 'The assistant can answer back out loud after each cycle.',
    items: [
      'ElevenLabs synthesis when configured',
      'macOS system voice fallback when ElevenLabs is unavailable',
      'External, internal, or combined narration modes',
    ],
  },
  {
    title: 'Speaker Analysis',
    description: 'Per-utterance diarization can enrich the loop context after you speak.',
    items: [
      'pyannoteAI runs after each committed pause when configured',
      'The app attaches speaker turns and loop context back into the mission',
      'If analysis fails, the local transcript still carries the session forward',
    ],
  },
  {
    title: 'Session Memory',
    description: 'The macOS app keeps the loop inspectable instead of ephemeral.',
    items: [
      'Conversation rail with live, captured, and delivered states',
      'Cycle history plus inspector view for prior plans',
      'Startup recovery when the previous launch ended uncleanly',
    ],
  },
]

const stackSections = [
  {
    title: 'Mission Control',
    description: 'The main dashboard is built around mission, environment, and steering.',
    items: [
      'Mission text, loop context, and operator feedback are first-class inputs',
      'Iteration budgets and decision models are configurable in the UI',
      'Automation permission state is visible alongside the mission',
    ],
  },
  {
    title: 'Transcription Engine',
    description: 'Speech capture is continuous and built around pause-based commits.',
    items: [
      'AVAudioEngine + Speech framework for live recognition',
      'Silence windows commit utterances into the loop automatically',
      'Playback echo suppression lets the mic stay live while the app speaks',
    ],
  },
  {
    title: 'Planning Core',
    description: 'Each loop is generated as structured JSON rather than free-form chat.',
    items: [
      'OpenAI Responses API produces the next navigation cycle',
      'Observe, orient, decide, act, and guide sections stay explicit',
      'Actions come back with tool names, targets, status, and rationale',
    ],
  },
  {
    title: 'Execution Bridge',
    description: 'The current runtime already executes some actions and plans others.',
    items: [
      'Mouse actions execute directly today when permissions allow',
      '`find_screen_text` resolves labels on screen into coordinates',
      '`shell_command` is currently planning-only and returned as a concrete suggestion',
    ],
  },
  {
    title: 'Permission Gates',
    description: 'The app is explicit about what macOS will and will not allow.',
    items: [
      'Accessibility is required before mouse automation can fire',
      'Screen Recording is required before OCR-based targeting can inspect the desktop',
      'The runtime surfaces those states in both settings and mission control',
    ],
  },
  {
    title: 'Audio Response Layer',
    description: 'Speech output is integrated into the loop, not bolted on later.',
    items: [
      'ElevenLabs or system voice can speak loop output',
      'Dialogue can be operator-facing, internal-only, or both',
      'The loop automatically resumes listening after playback finishes',
    ],
  },
  {
    title: 'Recovery & History',
    description: 'The session can survive interruptions and stay inspectable.',
    items: [
      'Recovery snapshots persist mission, feedback, progress, and status',
      'Startup assessment asks whether to continue or start fresh',
      'Cycle history and conversation history remain visible in the app',
    ],
  },
]

const coreUnitHeroStats = [
  {
    label: 'Voice Loop',
    value: '<10ms',
    detail: 'The broader XMAXX direction is still about keeping the guided loop close to the machine and responsive in real time.',
  },
  {
    label: 'Acoustic Output',
    value: '0 dB',
    detail: 'Passive thermal design keeps the node silent beside a desk microphone.',
  },
  {
    label: 'Always-On Draw',
    value: '8-15W',
    detail: 'The hardware track stays aimed at an always-available runtime that can keep the loop live without noise or heat drama.',
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
    description: 'Compact hardware sized for a desk, shelf, or workstation cluster.',
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
    description: 'Minimal hardware controls with visible voice-runtime state.',
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
    description: 'Built for always-on speech handling, routing, and automation.',
    rows: [
      ['Processing Type', 'Local-first voice control node'],
      ['Architecture', 'Multi-core AI-optimized chip'],
      ['Latency', '<10ms local routing response'],
      ['Cooling', 'Passive thermal dissipation (fanless)'],
    ],
  },
  {
    title: 'Connectivity',
    description: 'Ready for one desk or a larger voice-control footprint.',
    rows: [
      ['Wireless', 'Wi-Fi 6 / Bluetooth 5.3'],
      ['Rear Ports', 'USB-C (power + data), 2x USB-A, Ethernet (1 Gbps)'],
      ['Sync Capability', 'Node-to-node mesh (cluster ready)'],
    ],
  },
  {
    title: 'Power',
    description: 'Lean power profile for a voice runtime that stays available.',
    rows: [
      ['Input', 'USB-C PD'],
      ['Power Draw', '8-15W average'],
      ['Efficiency', 'Auto low-power idle state'],
    ],
  },
  {
    title: 'Voice Runtime',
    description: 'Core software posture centered on speech, control, and local trust.',
    items: [
      'Continuous microphone listener with local preprocessing',
      'Decision-model planning runtime',
      'Screenshot OCR and coordinate resolution',
      'Native HID mouse execution bridge',
      'Secure context storage (encrypted)',
      'Cluster networking (Xmaxx Network ready)',
    ],
  },
  {
    title: 'Security',
    description: 'Security model favors operator visibility and explicit boundaries.',
    id: 'security',
    items: [
      'Microphone permission boundaries with visible state',
      'Approval gates for privileged or destructive actions',
      'Local data priority with no forced cloud dependency',
      'Secure boot architecture',
    ],
  },
  {
    title: 'Operating Conditions',
    description: 'Sized for desks, shelves, and studio-adjacent installs.',
    rows: [
      ['Temperature Range', '0°C to 40°C'],
      ['Noise', '0 dB (fanless)'],
      ['Placement', 'Desk / shelf / rack-compatible'],
    ],
  },
]

const coreUnitModes = [
  {
    title: 'Desk Node',
    body: 'Always-on companion for one computer, one microphone path, and one operator.',
  },
  {
    title: 'Studio Node',
    body: 'Shared voice relay for workstations, meeting rooms, or creator setups that need a persistent command layer.',
  },
  {
    title: 'Builder Node',
    body: 'Custom adapters, automation policies, and local integrations for teams extending the runtime.',
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

  if (pathname === '/computer' || pathname === '/core-unit') {
    return 'computer'
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
    return homeNavLinks
  }

  if (currentPage === 'computer') {
    return computerNavLinks
  }

  return [
    { href: '/', label: 'Home', page: 'home' },
    { href: '/computer', label: 'XMAXX Computer', page: 'computer' },
  ]
}

function splitNavLinks(links) {
  return {
    sectionLinks: links.filter(({ href }) => href.startsWith('#')),
    routeLinks: links.filter(({ href }) => !href.startsWith('#')),
  }
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

function NavDropdown({ links, label = 'Sections' }) {
  if (links.length === 0) {
    return null
  }

  return (
    <label className="nav-select">
      <span className="nav-select__label">{label}</span>
      <select
        defaultValue=""
        aria-label={label}
        onChange={(event) => {
          const { value } = event.target

          if (!value) {
            return
          }

          window.location.assign(value)
          event.target.value = ''
        }}
      >
        <option value="">Open</option>
        {links.map(({ href, label: itemLabel }) => (
          <option key={href} value={href}>
            {itemLabel}
          </option>
        ))}
      </select>
    </label>
  )
}

function VoiceDeck() {
  return (
    <div className="hero-visual__frame hero-visual__frame--software">
      <div className="maxx-console" aria-label="XMAXX voice loop control deck">
        <div className="maxx-console__head">
          <span className="maxx-console__path">voice://xmaxx-computer</span>
          <span className="maxx-console__status">mic active</span>
        </div>

        <div className="voice-wave" aria-hidden="true">
          {voiceDeckWaves.map((height, index) => (
            <span key={`${height}-${index}`} style={{ height }} />
          ))}
        </div>

        <div className="maxx-console__grid">
          {voiceDeckColumns.map(({ title, items }) => (
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
          {voiceDeckActions.map(({ label, detail }) => (
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
    <Reveal as="footer" className="site-footer" aria-label="XMAXX social links">
      <div className="site-footer__copy">
        <p className="eyebrow">XMAXX</p>
        <p>
          XMAXX - Control at Scale
        </p>
      </div>

      <div className="site-footer__links">
        {socialLinks.map((link) => (
          <SocialLink key={link.label} {...link} />
        ))}
      </div>
    </Reveal>
  )
}

function HomePage({ authState, onOpenLogin }) {
  const isAuthenticated = authState.authenticated && authState.user
  const registerHref = isAuthenticated ? '/profile' : ''
  const checkoutHref = developerAccessConfig.checkoutUrl

  return (
    <>
      <Reveal as="section" className="hero-panel" id="overview">
        <div className="hero-copy">
          <p className="eyebrow">MAXX open source project</p>
          <h1>Automate Everything to the MAXX.</h1>
          <p className="hero-copy__lede">
            MAXX is an open source project focused on one thing: automating work across software,
            computers, and machines from a single control layer.
          </p>
          <p className="hero-copy__support">
            MAXX is focused on practical automation, visible execution, and an open product surface.
          </p>

          <div className="verb-strip" aria-label="XMAXX control scope">
            {commandTargets.map((target) => (
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
              View on GitHub
            </a>
            <a
              className="button button--ghost"
              href="/computer"
            >
              View XMAXX Computer
            </a>
          </div>

          <StaggerGroup className="hero-stats">
            {homeHeroStats.map(({ label, value, detail }) => (
              <StaggerItem as="article" className="hero-stat" key={label}>
                <p>{label}</p>
                <strong>{value}</strong>
                <span>{detail}</span>
              </StaggerItem>
            ))}
          </StaggerGroup>

          <Reveal className="hero-copy__panel" delay={0.1}>
            <div className="hero-copy__panel-head">
              <p className="section-kicker">Project Focus</p>
              <h2>Open automation core for software, computers, and machines.</h2>
            </div>

            <StaggerGroup className="hero-copy__panel-grid">
              {heroSurfaceNotes.map(({ label, title, detail }) => (
                <StaggerItem as="article" className="hero-copy__panel-note" key={title}>
                  <span>{label}</span>
                  <strong>{title}</strong>
                  <p>{detail}</p>
                </StaggerItem>
              ))}
            </StaggerGroup>
          </Reveal>
        </div>

        <div className="hero-visual">
          <VoiceDeck />

          <div className="hero-visual__meta">
            <div>
              <p className="section-kicker">Project Direction</p>
              <h2>Open source software for pushing as much routine control work into automation as possible.</h2>
            </div>

            <div className="hardware-highlights">
              {voiceHighlights.map((item) => (
                <span key={item}>{item}</span>
              ))}
            </div>
          </div>
        </div>
      </Reveal>

      <Reveal as="section" className="positioning-band" id="platform">
        <div>
          <p className="eyebrow">Project Summary</p>
          <h2>MAXX is an open source automation project.</h2>
        </div>

        <div className="positioning-band__copy">
          <p>
            The goal is not to add another dashboard. The goal is to reduce manual work
            by moving routine operations into a clear automation layer.
          </p>
          <p>
            That means one project surface, one control model, and one place to build
            automation across software, computers, devices, and machine workflows.
          </p>
        </div>
      </Reveal>

      <Reveal as="section" className="section-block" id="customers">
        <div className="section-heading">
          <p className="eyebrow">Who It Is For</p>
          <h2>MAXX is for teams that need systems to run with less manual intervention.</h2>
          <p>
            MAXX is built for operators, infrastructure teams, and builders who need
            more automation and less manual control work.
          </p>
        </div>

        <StaggerGroup className="use-case-grid use-case-grid--triad">
          {customerSections.map(({ title, description }) => (
            <InteractiveSurface as={StaggerItem} className="use-case-card" key={title}>
              <p className="section-kicker">Customer</p>
              <h3>{title}</h3>
              <p>{description}</p>
            </InteractiveSurface>
          ))}
        </StaggerGroup>
      </Reveal>

      <Reveal as="section" className="section-block" id="offer">
        <div className="section-heading">
          <p className="eyebrow">Core Product</p>
          <h2>The core product is automation.</h2>
          <p>
            MAXX is built around an open automation core, a formal product surface through
            XMAXX Computer, and a deployment path that stays visible.
          </p>
        </div>

        <StaggerGroup className="use-case-grid use-case-grid--triad">
          {offerSections.map(({ title, description }) => (
            <InteractiveSurface as={StaggerItem} className="use-case-card" key={title}>
              <p className="section-kicker">Offer</p>
              <h3>{title}</h3>
              <p>{description}</p>
            </InteractiveSurface>
          ))}
        </StaggerGroup>
      </Reveal>

      <Reveal as="section" className="section-block" id="developer-access">
        <div className="section-heading">
          <p className="eyebrow">Developer Access</p>
          <h2>XMAXX Developer Access</h2>
          <p>
            Access the XMAXX control platform for building and managing drone and
            autonomous systems.
          </p>
        </div>

        <div className="section-split">
          <article className="surface purchase-card">
            <div className="purchase-card__head">
              <div>
                <p className="section-kicker">Immediate access</p>
                <h3>Developer platform access delivered right after purchase.</h3>
              </div>
              <span className="purchase-card__badge">{developerAccessConfig.productId}</span>
            </div>

            <p className="purchase-card__copy">
              Register an operator account, complete checkout, and get access to the current
              XMAXX builder surface without waiting for manual provisioning.
            </p>

            <ul className="feature-list purchase-card__list">
              {developerAccessIncludes.map((item) => (
                <li key={item}>{item}</li>
              ))}
            </ul>

            <div className="hero-actions purchase-card__actions">
              {isAuthenticated ? (
                <a className="button button--ghost" href={registerHref}>
                  Open profile
                </a>
              ) : (
                <button className="button button--ghost" type="button" onClick={onOpenLogin}>
                  Register to Access
                </button>
              )}

              {checkoutHref ? (
                <a
                  className="button button--solid"
                  href={checkoutHref}
                  target="_blank"
                  rel="noreferrer"
                >
                  Buy Developer Access
                </a>
              ) : (
                <button className="button button--solid" type="button" disabled>
                  Buy Developer Access
                </button>
              )}
            </div>

            <p className="purchase-card__meta">
              This product is delivered immediately upon purchase.
            </p>
          </article>

          <aside className="section-aside section-aside--accent purchase-aside">
            <p className="section-kicker">Flow</p>
            <h3>Register, buy, and start building.</h3>
            <p>
              The account flow runs through the existing sign-in system. Checkout is wired
              to Stripe as soon as a payment link is configured for this product.
            </p>

            <div className="purchase-flow">
              <div className="purchase-flow__step">
                <strong>1</strong>
                <div>
                  <span>Create access</span>
                  <p>Sign in with GitHub or Google to establish the operator account.</p>
                </div>
              </div>
              <div className="purchase-flow__step">
                <strong>2</strong>
                <div>
                  <span>Complete purchase</span>
                  <p>Use Stripe checkout for the XMAXX Developer Access product.</p>
                </div>
              </div>
              <div className="purchase-flow__step">
                <strong>3</strong>
                <div>
                  <span>Start building</span>
                  <p>Use the control platform, SDK, APIs, and developer community access.</p>
                </div>
              </div>
            </div>

            {developerAccessConfig.communityUrl ? (
              <a
                className="button button--ghost purchase-aside__button"
                href={developerAccessConfig.communityUrl}
                target="_blank"
                rel="noreferrer"
              >
                Open developer community
              </a>
            ) : null}
          </aside>
        </div>
      </Reveal>

      <Reveal as="section" className="section-block">
        <div className="section-heading">
          <p className="eyebrow">Current Scope</p>
          <h2>What the project covers today.</h2>
          <p>
            The current page stays grounded in the parts of the project that are already clear.
          </p>
        </div>

        <StaggerGroup className="spec-grid spec-grid--scope">
          {scopePoints.map((section) => (
            <InteractiveSurface as={StaggerItem} key={section.title}>
              <SpecCard {...section} />
            </InteractiveSurface>
          ))}
        </StaggerGroup>
      </Reveal>

      <Reveal as="section" className="section-block" id="automation">
        <div className="section-heading">
          <p className="eyebrow">Automation Focus</p>
          <h2>The project exists to automate as much practical work as possible.</h2>
          <p>
            The point is not vague autonomy. The point is taking useful, repeatable work
            and moving it into an execution layer that is visible and controllable.
          </p>
        </div>

        <StaggerGroup className="use-case-grid">
          {buildUseCases.map(({ title, description }) => (
            <InteractiveSurface as={StaggerItem} className="use-case-card" key={title}>
              <p className="section-kicker">Automation Area</p>
              <h3>{title}</h3>
              <p>{description}</p>
            </InteractiveSurface>
          ))}
        </StaggerGroup>
      </Reveal>

      <Reveal as="section" className="section-block" id="how-it-works">
        <div className="section-heading">
          <p className="eyebrow">Built for Operators</p>
          <h2>Input to Agent to Execution to Feedback</h2>
          <p>
            The operating model is formal and simple: define the task, let the system plan it,
            execute it, then review what happened.
          </p>
        </div>

        <StaggerGroup className="spec-grid">
          {operatorFlowSections.map((section) => (
            <InteractiveSurface as={StaggerItem} key={section.title}>
              <SpecCard {...section} />
            </InteractiveSurface>
          ))}
        </StaggerGroup>
      </Reveal>

      <Reveal as="section" className="section-block" id="open-source">
        <div className="section-heading">
          <p className="eyebrow">Open Source</p>
          <h2>The project is open, and the product direction stays visible.</h2>
          <p>
            MAXX is being built in public. The code is open, the deployment path is visible,
            and the product surface is not hidden behind vague language.
          </p>
        </div>

        <StaggerGroup className="spec-grid spec-grid--triad">
          {proofSections.map((section) => (
            <InteractiveSurface as={StaggerItem} key={section.title}>
              <SpecCard {...section} />
            </InteractiveSurface>
          ))}
        </StaggerGroup>

        <div className="hero-actions">
          <a
            className="button button--solid"
            href="https://github.com/xmaxxai"
            target="_blank"
            rel="noreferrer"
          >
            GitHub repo
          </a>
        </div>
      </Reveal>

      <Reveal as="section" className="closing-panel">
        <p className="eyebrow">Product Page</p>
        <h2>XMAXX Computer is the current product page.</h2>
        <p>
          The homepage explains the core project. The computer page is where the current
          product surface, runtime details, and hardware direction live.
        </p>

        <div className="hero-actions">
          <a className="button button--solid" href="/computer">
            Open XMAXX Computer
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
      </Reveal>

      <SiteFooter />
    </>
  )
}

function CoreUnitPage() {
  return (
    <>
      <section className="hero-panel" id="product-overview">
        <div className="hero-copy">
          <p className="eyebrow">Product Page</p>
          <h1>XMAXX Computer is the current product surface.</h1>
          <p className="hero-copy__lede">
            XMAXX Computer is the current product expression of the XMAXX runtime: a
            voice-first control surface for the desktop, built in public, with a hardware
            direction behind it for always-on local operation.
          </p>

          <div className="verb-strip" aria-label="Core unit posture">
            <span>Always on</span>
            <span>Fanless</span>
            <span>Voice loop</span>
          </div>

          <div className="hero-actions">
            <a className="button button--solid" href="/">
              Back to Home
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
              <p className="section-kicker">Runtime Envelope</p>
              <h2>Local speech pipeline, desktop control, and a physical direction behind the product.</h2>
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
            XMAXX Computer proves the interaction model now: continuous voice capture,
            explicit decision stages, OCR-based screen targeting, native mouse execution,
            and approval-gated actions in a real desktop product.
          </p>
          <p>
            The hardware track extends that same system into a persistent local node, but
            the product page should start with what exists today and how the open-source
            project is evolving outward from there.
          </p>
        </div>
      </section>

      <section className="section-block" id="specs">
        <div className="section-heading">
          <p className="eyebrow">Specification Matrix</p>
          <h2>Hardware, runtime, and permission posture in one surface.</h2>
        </div>

        <div className="spec-grid">
          {coreUnitSpecSections.map((section) => (
            <SpecCard key={section.title} {...section} />
          ))}
        </div>
      </section>

      <section className="section-block" id="modes">
        <div className="section-heading">
          <p className="eyebrow">Deployment Modes</p>
          <h2>Deploy as a personal node, a studio relay, or a builder runtime.</h2>
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
        <p className="eyebrow">Open Project</p>
        <h2>XMAXX Computer is part product page, part open build log.</h2>
        <p>
          The intent is to keep shipping the product in public: app behavior, backend, infra,
          registry, and hardware direction all visible enough for operators and builders to
          understand what XMAXX already is and what comes next.
        </p>
      </section>

      <SiteFooter />
    </>
  )
}

function App() {
  const currentPage = getCurrentPage()
  const siteNavLinks = getSiteNavLinks(currentPage)
  const { sectionLinks, routeLinks } = splitNavLinks(siteNavLinks)
  const [isPageReady, setIsPageReady] = useState(false)
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
    const frame = window.requestAnimationFrame(() => {
      setIsPageReady(true)
    })

    return () => {
      window.cancelAnimationFrame(frame)
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
    <div className={`spec-page${isPageReady ? ' spec-page--ready' : ''}`}>
      <div className="ambient ambient--left" />
      <div className="ambient ambient--right" />

      <header className="site-header">
        <a className="brand" href={currentPage === 'home' ? '#overview' : '/'} aria-label="XMAXX home">
          <span className="brand__mark">XMAXX</span>
          <span className="brand__sub">
            {currentPage === 'computer' ? 'XMAXX Computer' : 'Open Voice Computing'}
          </span>
        </a>

        <nav className="site-nav" aria-label="Page sections">
          <NavDropdown
            links={sectionLinks}
            label={currentPage === 'computer' ? 'Product' : 'Explore'}
          />

          {routeLinks.map(({ href, label, page }) => (
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
        ) : currentPage === 'computer' ? (
          <CoreUnitPage />
        ) : (
          <HomePage authState={authState} onOpenLogin={handleOpenLogin} />
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
