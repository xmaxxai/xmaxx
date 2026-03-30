import './index.css'

const navLinks = [
  { href: '#overview', label: 'Overview' },
  { href: '#specs', label: 'Specs' },
  { href: '#modes', label: 'Modes' },
  { href: '#security', label: 'Security' },
]

const heroStats = [
  {
    label: 'Local Response',
    value: '<10ms',
    detail: 'Local-first compute keeps control loops immediate.',
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

const hardwareHighlights = [
  '180 x 110 x 95 mm',
  '1.2 kg',
  'Wi-Fi 6',
  'Bluetooth 5.3',
  '1 Gbps Ethernet',
  'Cluster ready',
]

const specSections = [
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

const modes = [
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

function App() {
  return (
    <div className="spec-page">
      <div className="ambient ambient--left" />
      <div className="ambient ambient--right" />

      <header className="site-header">
        <a className="brand" href="#overview" aria-label="XMAXX home">
          <span className="brand__mark">XMAXX</span>
          <span className="brand__sub">Core Unit</span>
        </a>

        <nav className="site-nav" aria-label="Page sections">
          {navLinks.map(({ href, label }) => (
            <a key={href} href={href}>
              {label}
            </a>
          ))}
        </nav>
      </header>

      <main className="page-shell">
        <section className="hero-panel" id="overview">
          <div className="hero-copy">
            <p className="eyebrow">Product Spec — XMAXX Core Unit</p>
            <h1>This is not a consumer gadget. This is a system node.</h1>
            <p className="hero-copy__lede">
              High-performance modular system hub designed for local-first
              processing, automation, and optimization workflows. Built for
              continuous operation with minimal noise and maximum efficiency.
            </p>

            <div className="verb-strip" aria-label="System purpose">
              <span>Run</span>
              <span>Track</span>
              <span>Optimize</span>
            </div>

            <div className="hero-stats">
              {heroStats.map(({ label, value, detail }) => (
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
                <h2>Compact monolith. Fanless core. Local-first runtime.</h2>
              </div>

              <div className="hardware-highlights">
                {hardwareHighlights.map((item) => (
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
              Purpose-built to run persistent workflows, track system state, and
              optimize across domains without forcing cloud dependence.
            </p>
            <p>
              XMAXX Core Unit behaves like an operational node: quiet, secure,
              mesh-capable, and designed to stay present in the environment.
            </p>
          </div>
        </section>

        <section className="section-block" id="specs">
          <div className="section-heading">
            <p className="eyebrow">Specification Matrix</p>
            <h2>Hardware, runtime, and security posture in one surface.</h2>
          </div>

          <div className="spec-grid">
            {specSections.map((section) => (
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
            {modes.map(({ title, body }) => (
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
          <h2>Local data priority. Secure boot. Continuous operation.</h2>
          <p>
            XMAXX Core Unit is designed to stay on, stay quiet, and stay in
            control of the environment it serves.
          </p>
        </section>
      </main>
    </div>
  )
}

export default App
